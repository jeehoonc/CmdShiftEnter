//
//  ModifierFlagsConverter.swift
//  TestMacOsApp
//
//  Created by Jeehoon Cha on 2023/05/01.
//

import Carbon
import SwiftUI

struct ModifierFlagsConverter {
  
  public static func toString(flags: NSEvent.ModifierFlags) -> String {
    var results = Array<String>()
    if (flags.contains(NSEvent.ModifierFlags.command)) { results.append("command") }
    if (flags.contains(NSEvent.ModifierFlags.control)) { results.append("control") }
    if (flags.contains(NSEvent.ModifierFlags.option)) { results.append("option") }
    if (flags.contains(NSEvent.ModifierFlags.shift)) { results.append("shift") }
    if (flags.contains(NSEvent.ModifierFlags.capsLock)) { results.append("capsLock") }
    return results.joined(separator: " ")
  }
  
  public static func toCarbonFlags(flags: NSEvent.ModifierFlags) -> Int {
    var result: Int = 0
    if (flags.contains(NSEvent.ModifierFlags.command)) { result |= cmdKey }
    if (flags.contains(NSEvent.ModifierFlags.control)) { result |= controlKey }
    if (flags.contains(NSEvent.ModifierFlags.option)) { result |= optionKey }
    if (flags.contains(NSEvent.ModifierFlags.function)) { result |= kVK_Function }
    if (flags.contains(NSEvent.ModifierFlags.shift)) { result |= shiftKey }
    if (flags.contains(NSEvent.ModifierFlags.capsLock)) { result |= kVK_CapsLock }
    return result
  }
}
