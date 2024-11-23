//
//  WindowEventHandler.swift
//  ExpandWindowHotKey
//
//  Created by Jeehoon Cha on 11/19/24.
//

import ApplicationServices.HIServices.AXUIElement
import ApplicationServices.HIServices.AXNotificationConstants

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
