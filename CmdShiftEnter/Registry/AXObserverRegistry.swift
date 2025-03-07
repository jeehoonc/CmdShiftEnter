//
//  AXObserverRegistry.swift
//  ExpandWindowHotKey
//
//  Created by Jeehoon Cha on 11/24/24.
//

import SwiftUI

let _notificationTypes = [kAXUIElementDestroyedNotification, kAXWindowResizedNotification, kAXWindowMovedNotification]

let _observerCallback: AXObserverCallback = {  (observer, element, notification, refcon) in
  // do something
  let type = notification as String
  print("type =", type)
  WindowManager.getInstance().handleEvent(type, element)
}

class ProcessAXObserverRegistry {

  // singleton instance
  private static let instance: ProcessAXObserverRegistry = ProcessAXObserverRegistry()

  static func getInstance() -> ProcessAXObserverRegistry {
    return instance
  }

  private init() {}

  // map of AXObserver per process ID
  private var axObservers: [pid_t: AXObserver?] = [:]

  // event listener thread runloop
  private var axObserverRunLoopThread: BackgroundThreadWithRunLoop! = BackgroundThreadWithRunLoop("axObserverRunLoopThread")

  private func getAXObserver(pid: pid_t) -> AXObserver? {
    guard let observer = axObservers[pid] else {
      return nil;  // TODO: throw
    }
    return observer
  }

  func ensureInitialized(pid: pid_t) {
    if axObservers.keys.contains(pid) {
      // do nothing
      return;
    }

    var axObserverOut: AXObserver?
    let result: AXError = AXObserverCreate(pid, _observerCallback, &axObserverOut)
    guard result == .success else {
      print("Failed to create AXObserver for frontAppPid", pid, ": result=", result)
      return;  // TODO: throw
    }

    // register the axObserver source to run loop
    // TODO: remove axObserver source from run loop when the process terminates
    axObserverRunLoopThread.startIfNotStarted()
    CFRunLoopAddSource(axObserverRunLoopThread.runLoop, AXObserverGetRunLoopSource(axObserverOut!), .defaultMode)
    axObserverRunLoopThread.axObserverAdded = true

    // update axObservers map
    axObservers[pid] = axObserverOut
    print("initialized an AXObserver: pid =", pid, ", axObserver =", axObserverOut!)
  }

  func registerNotifications(pid: pid_t, element: AXUIElement) {
    // add notifications
    let observer = getAXObserver(pid: pid)
    for nType in _notificationTypes {
      let result = AXObserverAddNotification(observer!, element, nType as CFString, nil)
      print("Added notification for", nType, ": result =", result.rawValue)
    }
  }

  func unregisterNotifications(pid: pid_t, element: AXUIElement) {
    // remove notifications
    let observer = getAXObserver(pid: pid)
    for nType in _notificationTypes {
      var result: AXError? = nil;
      while (result != .success) {
        result = AXObserverRemoveNotification(observer!, element, nType as CFString)
        print("Called AXObserverRemoveNotification for", nType, ": result =", result!.rawValue)
      }
    }
  }
}
