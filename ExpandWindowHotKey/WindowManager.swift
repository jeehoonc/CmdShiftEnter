//
//  WindowManager.swift
//  TestMacOsApp
//
//  Created by Jeehoon Cha on 2023/05/01.
//

import SwiftUI

class WindowManager {
  private var windowStateRegistry = WindowStateRegistry.getInstance()
  private var axObserverRegistry = ProcessAXObserverRegistry.getInstance()
  private let queue = DispatchQueue(label: "WindowRegistryManager.DispatchQueue")

  // singleton instance
  static let instance = WindowManager()

  static func getInstance() -> WindowManager { return instance }

  private init() {}

  // idempotent
  private func addToRegistry(element: AXUIElement, pid: pid_t, windowID: CGWindowID, position: CGPoint?, size: CGSize?) {
    // do nothing, if the window is already added to the registry
    if (windowStateRegistry.hasWindowState(windowID: windowID)) {
      return
    }

    // update windowState
    WindowStateRegistry.getInstance().setWindowState(windowID: windowID, position: position, size: size)

    // register AXObserver
    let observerRegistry = ProcessAXObserverRegistry.getInstance()
    observerRegistry.ensureInitialized(pid: pid)
    observerRegistry.registerNotifications(pid: pid, element: element)
  }

  private func removeFromRegistry(element: AXUIElement, pid: pid_t, windowID: CGWindowID) {
    // do nothing, if already removed from the registry
    if (!windowStateRegistry.hasWindowState(windowID: windowID)) {
      return
    }

    // remove windowState
    WindowStateRegistry.getInstance().removeWindowState(windowID: windowID)

    // unregister AXObserver
    ProcessAXObserverRegistry.getInstance().unregisterNotifications(pid: pid, element: element)
  }

  func resize() {
    queue.sync {
      // retrieve frontApp PID and AXUIElement
      let frontApp = NSWorkspace.shared.runningApplications.first { $0.isActive }
      guard let pid = frontApp?.processIdentifier else { exit (1) }
      let appElement = AXUIElementCreateApplication(pid)
      print("frontApp =", frontApp as Any, ", pid =", pid, ", appElement =", appElement)

      // check Accessibility Permissions
      let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
      let permission = AXIsProcessTrustedWithOptions(options)
      guard permission == true else {
        print("Failed: accessibility permission not granted")
        return;
      }

      // retrieve focused window as AXUIElement
      var focusedWindow: AnyObject?
      let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)
      guard result == .success else {
        print ("Failed to get focused window: result =", result)
        return
      }
      let element: AXUIElement = (focusedWindow as! AXUIElement)

      // retrieve window ID
      guard let windowID: CGWindowID = AXUIElementHelper.getWindowId(windowElement: element) else {
        print("Failed to get windowID")  // TODO: throw
        return;
      }

      // expand or unexpand, depending on the window state
      if (!windowStateRegistry.hasWindowState(windowID: windowID)) {
        // retrieve position of the focused window
        let position: CGPoint? = AXUIElementHelper.getPosition(windowElement: element)
        let size: CGSize? = AXUIElementHelper.getSize(windowElement: element)

        // retrieve screen that is containing the position of the focused window
        let screen = ScreenDetectHelper.getScreenContaining(point: position!)

        // expand the focused window to the maximum frame of the screen
        AXUIElementHelper.setPosition(windowElement: element, position: screen?.frame.origin)
        AXUIElementHelper.setSize(windowElement: element, size: screen?.frame.size)
        print("Expanded focused window element:", size!, "--> (full)")

        // add to registry
        addToRegistry(element: element, pid: pid, windowID: windowID, position: position, size: size)
      } else {
        // remove from registry
        let windowState = WindowStateRegistry.getInstance().getWindowState(windowID: windowID)
        removeFromRegistry(element: element, pid: pid, windowID: windowID)

        // unexpand the focused window (shrink to its original size)
        AXUIElementHelper.setPosition(windowElement: element, position: windowState.originalPosition)
        AXUIElementHelper.setSize(windowElement: element, size: windowState.originalSize)
        print("Shrinked focused window element: (full) -->", windowState.originalSize!)
      }
    }
  }

  func handleEvent(_ type: String, _ element: AXUIElement) {
    queue.sync {
      switch type {
        case kAXUIElementDestroyedNotification: fallthrough;
        case kAXWindowResizedNotification: fallthrough;
        case kAXWindowMovedNotification:
          var windowID: CGWindowID? = nil
          while (windowID == nil) {
            windowID = AXUIElementHelper.getWindowId(windowElement: element)
          }
          var pid: pid_t? = nil
          while (pid == nil) {
            pid = AXUIElementHelper.getProcessId(windowElement: element)
          }
          removeFromRegistry(element: element, pid: pid!, windowID: windowID!)
          break
        default:
          return
      }
    }
  }
}
