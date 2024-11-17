//
//  WindowManager.swift
//  TestMacOsApp
//
//  Created by Jeehoon Cha on 2023/05/01.
//

import SwiftUI
import AppKit

class WindowManager: ObservableObject {

  struct WindowState {
    var isFullSize: Bool
    var originalPosition: CGPoint?
    var originalSize: CGSize?
  }

  // map of window states per window ID
  private static var windowStates: [CGWindowID: WindowState?] = [:]

  public static func resize() {
    let frontApp = NSWorkspace.shared.runningApplications.first { $0.isActive }
    guard let frontAppPid = frontApp?.processIdentifier else { exit (1) }
    let appElement = AXUIElementCreateApplication(frontAppPid)
    print("frontApp =", frontApp as Any, ", frontAppPid =", frontAppPid, ", appElement =", appElement)

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
    let focusedWindowElement: AXUIElement = (focusedWindow as! AXUIElement)

    // retrieve window ID
    guard let windowID: CGWindowID = AXUIElementHelper.getWindowId(windowElement: focusedWindowElement) else {
      print("Failed to get windowID")
      return;
    }

    // lookup windowState dictionary
    let containedWindowID = windowStates.keys.contains(windowID)
    if !windowStates.keys.contains(windowID) {
      windowStates[windowID] = WindowState(isFullSize: false)
    }
    var windowState: WindowState? = windowStates[windowID]!
    print("windowID =", windowID, ", containedWindowID =", containedWindowID, ", windowState =", windowState)

    // expand or shrink, depending on the window state
    if windowState?.isFullSize == false {
      // retrieve position of the focused window
      let position: CGPoint? = AXUIElementHelper.getPosition(windowElement: focusedWindowElement)
      let size: CGSize? = AXUIElementHelper.getSize(windowElement: focusedWindowElement)

      // retrieve screen that is containing the position of the focused window
      let screen = ScreenDetectHelper.getScreenContaining(point: position!)

      // expand the focused window to the maximum frame of the screen
      AXUIElementHelper.setPosition(windowElement: focusedWindowElement, position: screen?.frame.origin)
      AXUIElementHelper.setSize(windowElement: focusedWindowElement, size: screen?.frame.size)

      // update windowState
      windowState?.isFullSize = true
      windowState?.originalPosition = position
      windowState?.originalSize = size
      print("Updated window state (isFullSize: false --> true): windowID =", windowID, ", windowState =", windowState)
    } else {
      // expand the focused window to the maximum frame of the screen
      AXUIElementHelper.setPosition(windowElement: focusedWindowElement, position: windowState?.originalPosition)
      AXUIElementHelper.setSize(windowElement: focusedWindowElement, size: windowState?.originalSize)

      // update windowState
      windowState?.isFullSize = false
      print("Updated window state (isFullSize: true --> false): windowID =", windowID, ", windowState =", windowState)
    }

    // update windowStates map
    windowStates.updateValue(windowState, forKey: windowID)
  }
}

struct AXUIElementHelper {
  static func getWindowId(windowElement: AXUIElement) -> CGWindowID? {
    var windowId = CGWindowID(0)
    let result = _AXUIElementGetWindow(windowElement, &windowId)
    guard result == .success else { return nil }
    return windowId
  }

  static func setSize(windowElement: AXUIElement, size: CGSize?) {
    guard var newSize = size else { return }
    guard let newAXValue = AXValueCreate(.cgSize, &newSize) else { return }
    AXUIElementSetAttributeValue(windowElement, NSAccessibility.Attribute.size.rawValue as CFString, newAXValue)
  }
  
  static func setPosition(windowElement: AXUIElement, position: CGPoint?) {
    guard var newPosition = position else { return }
    guard let newAXValue = AXValueCreate(.cgPoint, &newPosition) else { return }
    AXUIElementSetAttributeValue(windowElement, NSAccessibility.Attribute.position.rawValue as CFString, newAXValue)
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

@_silgen_name("_AXUIElementGetWindow") @discardableResult
func _AXUIElementGetWindow(_ axUiElement: AXUIElement, _ wid: inout CGWindowID) -> AXError
