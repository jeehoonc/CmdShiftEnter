//
//  AXUIElementHelper.swift
//  ExpandWindowHotKey
//
//  Created by Jeehoon Cha on 11/24/24.
//

import SwiftUI
import AppKit

struct AXUIElementHelper {
  static func getProcessId(windowElement: AXUIElement) -> pid_t? {
    let pointer = UnsafeMutablePointer<pid_t>.allocate(capacity: 1)
    let result = AXUIElementGetPid(windowElement, pointer)
    if (result.rawValue > 0) {
      return nil  // TODO: throw
    }
    return pointer.pointee
  }

  static func getWindowId(windowElement: AXUIElement) -> CGWindowID? {
    var windowId = CGWindowID(0)
    let result = _AXUIElementGetWindow(windowElement, &windowId)
    print("getWindowId: element =", windowElement, ", result =", result.rawValue, ", windowId =", windowId)
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

@_silgen_name("_AXUIElementGetWindow") @discardableResult
func _AXUIElementGetWindow(_ axUiElement: AXUIElement, _ wid: inout CGWindowID) -> AXError
