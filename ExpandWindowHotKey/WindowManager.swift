//
//  WindowManager.swift
//  TestMacOsApp
//
//  Created by Jeehoon Cha on 2023/05/01.
//

import SwiftUI

class WindowManager: ObservableObject {
  
  struct WindowState {
    var isFullSize: Bool
    var originalFrame: NSRect?
  }
  
  private static var windowStates: [CGWindowID: WindowState] = [:]

  public static func resize() {
    let frontApp = NSWorkspace.shared.runningApplications.first { $0.isActive }
    guard let frontAppPid = frontApp?.processIdentifier else { exit (1) }
    let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    let options: NSDictionary = [prompt: true]
    let permission = AXIsProcessTrustedWithOptions(options)
    print("frontApp =", frontApp, ", frontAppPid =", frontAppPid, ", AXIsProcessTrustedWithOptions =", permission)

    if permission {
      // retrieve focused window as AXUIElement
      let appElement = AXUIElementCreateApplication(frontAppPid)
      var focusedWindow: AnyObject?
      var result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)
      print("appElement =", appElement, ", result =", result.rawValue, ", focusedWindow =", focusedWindow)

      if result == .success, let focusedWindowElement: AXUIElement? = focusedWindow as! AXUIElement {
          // retrieve position of the focused window
          let position: CGPoint? = AXUIElementHelper.getAXValue(element: focusedWindowElement!, attribute: .position)

          // retrieve screen that containing the position of the focused window
          let screen = ScreenDetectHelper.getScreenContaining(point: position!)

          // expand the focused window to the maximum frame of the screen
          AXUIElementHelper.setAXValue(element: focusedWindowElement!, attribute: .position, value: screen?.frame.origin, type: .cgPoint)
          AXUIElementHelper.setAXValue(element: focusedWindowElement!, attribute: .size, value: screen?.frame.size, type: .cgSize)
      } else {
        print("Failed to get focused window (pid=", frontAppPid, ")")
      }
//      let focusedWindow = AXUIElementHelper.getValue(element: AXUIElementCreateApplication(frontAppPid), attribute: .focusedWindow)
//      let focusedWindowElement = focusedWindow as! AXUIElement
    }
    print("Done =", true)

//    if let window = NSApplication.shared.keyWindow {
//      let windowID = CGWindowID(window.windowNumber)
//      
//      if let windowState = windowStates[windowID]{
//        window.setFrame(windowState.originalFrame!, display: true)
//        windowStates.removeValue(forKey: windowID)
//      } else {
//        if let visibleFrame = window.screen?.visibleFrame {
//          windowStates[windowID] = WindowState(isFullSize: true, originalFrame: window.frame)
//          window.setFrame(visibleFrame, display: true)
//        } else {
//          print("window screen =", window.screen)
//        }
//      }
//    }
  }
}

struct AXUIElementHelper {
//  static func getWindowId(windowElement: AXUIElement) -> CGWindowID? {
//    var windowId = CGWindowID(0)
//    let result = _AXUIElementGetWindow(windowElement, &windowId)
//    guard result == .success else { return nil }
//    return windowId
//  }
  
  static func setSize(windowElement: AXUIElement, size: CGSize?) {
    guard var newSize = size else { return }
    guard let newAXValue = AXValueCreate(.cgSize, &newSize) else { return }
    AXUIElementSetAttributeValue(windowElement, NSAccessibility.Attribute.size.rawValue as CFString, newAXValue)
  }
  
  static func getSize(windowElement: AXUIElement) -> CGSize? {
    return getAXValue(element: windowElement, attribute: .size)
  }
  
  static func getPosition(windowElement: AXUIElement) -> CGPoint? {
    return getAXValue(element: windowElement, attribute: .position)
  }
  
  static func getValue(element: AXUIElement, attribute: NSAccessibility.Attribute) -> AnyObject? {
    var value: AnyObject? = nil
    AXUIElementCopyAttributeValue(element, attribute.rawValue as CFString, &value)
    return value
  }
  
  static func setValue(element: AXUIElement, attribute: NSAccessibility.Attribute, value: AnyObject) {
    AXUIElementSetAttributeValue(element, attribute.rawValue as CFString, value)
  }
  
  static func getAXValue<T>(element: AXUIElement, attribute: NSAccessibility.Attribute) -> T? {
    guard let value = getValue(element: element, attribute: attribute), CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
    
    let axValue = value as! AXValue
    let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
    let success = AXValueGetValue(axValue, AXValueGetType(axValue), pointer)
    return success ? pointer.pointee : nil
  }
  
  static func setAXValue<T>(element: AXUIElement, attribute: NSAccessibility.Attribute, value: T, type: AXValueType) {
    let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
    pointer.pointee = value
    guard let axValue = AXValueCreate(type, pointer) else { return }
    setValue(element: element, attribute: attribute, value: axValue)
  }
}

struct ScreenDetectHelper {
  static func getScreenContaining(point: CGPoint) -> NSScreen? {
    return getScreenOf(filter: { frame in
      return NSRectToCGRect(frame).contains(point)
    })
  }
  
  private static func getScreenOf(filter: (NSRect) -> Bool) -> NSScreen? {
    for screen in NSScreen.screens {
      if filter(screen.frame) { return screen }
    }
    return NSScreen.main
  }
}
