//
//  WindowEventHandler.swift
//  ExpandWindowHotKey
//
//  Created by Jeehoon Cha on 11/19/24.
//

import ApplicationServices.HIServices.AXUIElement
import ApplicationServices.HIServices.AXNotificationConstants

let _notificationTypes = [kAXUIElementDestroyedNotification, kAXWindowResizedNotification, kAXWindowMovedNotification]

let _observerCallback: AXObserverCallback = {  (observer, element, notification, refcon) in
  // do something
  let type = notification as String
  print("type =", type)
  handleEvent(type, element)
}

fileprivate func handleEvent(_ type: String, _ element: AXUIElement) {
    // events are handled concurrently, thus we check that the app is still running
    switch type {
      case kAXUIElementDestroyedNotification: windowDestroyed(element);
      case kAXWindowResizedNotification: windowResized(element);
      case kAXWindowMovedNotification: windowMoved(element);
      default: return
    }
}

fileprivate func windowDestroyed(_ element: AXUIElement) {
  print("windowDestroyed: element =", element)
}

fileprivate func windowResized(_ element: AXUIElement) {
  print("windowResized: element =", element)
}

fileprivate func windowMoved(_ element: AXUIElement) {
  print("windowMoved: element =", element)
}

class BackgroundThreadWithRunLoop {
  var thread: Thread?
  var runLoop: CFRunLoop?
  var hasStarted: Bool?
  var axObserverAdded: Bool?
  private let queue = DispatchQueue(label: "BackgroundThreadWithRunLoop.DispatchQueue")

  init(_ name: String) {
    self.hasStarted = false
    self.axObserverAdded = false

    // create a background thread and retrieve its runLoop
    thread = Thread {
      self.runLoop = CFRunLoopGetCurrent()
      self.hasStarted = true
      while !self.axObserverAdded! {
        Thread.sleep(forTimeInterval: 0.01)
      }
      print("self.axObserverAdded: ", self.axObserverAdded!)
      CFRunLoopRun()
    }

    thread!.name = name
  }

  // synchronous and idempotent
  func startIfNotStarted() {
    queue.sync {
      if self.hasStarted! {
        return
      }

      // start thread runloop
      self.thread!.start()
      while !self.hasStarted! {
        print("thread not started")
        Thread.sleep(forTimeInterval: 0.1)
      }
    }
  }
}
