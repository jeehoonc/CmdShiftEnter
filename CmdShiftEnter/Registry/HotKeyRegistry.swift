//
//  HotKeyRegistry.swift
//  TestMacOsApp
//
//  Created by Jeehoon Cha on 2023/05/01.
//

import Foundation
import Carbon
import SwiftUI

class HotKeyRegistry: ObservableObject {
  @AppStorage("modifierFlags") public var modifierFlags: Data = UIntConverter.convert(
    from: NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue
  )
  @AppStorage("keyCode") public var keyCode = kVK_Return
  private var hotKeyRef: EventHotKeyRef?
  
  public func getModifierFlagsString() -> String {
    return ModifierFlagsConverter.toString(flags: HotKeyRegistry.toModifierFlags(data: modifierFlags))
  }
  
  public func getKeyCodeString() -> String {
    return NSEventKeyCodeToString.convert(from: keyCode)
  }
  
  public func registerHotKey() {
    registerHotKey(
      modifierFlags: HotKeyRegistry.toModifierFlags(data: modifierFlags),
      keyCode: keyCode,
      hotKeyRef: &hotKeyRef)
  }
  
  public func registerHotKey(modifierFlags: NSEvent.ModifierFlags, keyCode: Int) {
    self.modifierFlags = UIntConverter.convert(from: modifierFlags.rawValue)
    self.keyCode = keyCode
    if (hotKeyRef != nil) {
      UnregisterEventHotKey(hotKeyRef!)
    }
    registerHotKey(modifierFlags: modifierFlags, keyCode: keyCode, hotKeyRef: &hotKeyRef)
  }
  
  private func registerHotKey(modifierFlags: NSEvent.ModifierFlags, keyCode: Int, hotKeyRef: UnsafeMutablePointer<EventHotKeyRef?>) {
    let keyCodeId = UInt32(keyCode)
    let carbonFlags = UInt32(ModifierFlagsConverter.toCarbonFlags(flags: modifierFlags))

    let hotKeyID = EventHotKeyID(signature: OSType(Constants.signature), id: keyCodeId)
    var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
    
    // Install handler.
    InstallEventHandler(GetApplicationEventTarget(), hotKeyEventHandler, 1, &eventType, nil, nil)

    // Register hotkey.
    let status = RegisterEventHotKey(keyCodeId, carbonFlags, hotKeyID, GetApplicationEventTarget(), 0 /* options bit */, hotKeyRef)
    assert(status == noErr)
  }
  
  private static func toModifierFlags(data: Data) -> NSEvent.ModifierFlags {
    return NSEvent.ModifierFlags(rawValue: UIntConverter.convert(from: data))
  }
}

private func hotKeyEventHandler(eventHandlerCall: EventHandlerCallRef?, event: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus {
  var hotKeyID = EventHotKeyID()
  GetEventParameter(
    event,
    EventParamName(kEventParamDirectObject),
    EventParamType(typeEventHotKeyID),
    nil,
    MemoryLayout<EventHotKeyID>.size,
    nil,
    &hotKeyID)
  print("TEST")
  print("hotKeyID =", hotKeyID)
  WindowManager.getInstance().resize()
  return noErr
}
