//
//  WindowStateRegistry.swift
//  ExpandWindowHotKey
//
//  Created by Jeehoon Cha on 11/24/24.
//

import SwiftUI

class WindowStateRegistry {

  // singleton instance
  private static let instance: WindowStateRegistry = WindowStateRegistry()

  static func getInstance() -> WindowStateRegistry {
    return instance
  }

  private init() {}

  struct WindowState {
    var originalPosition: CGPoint?
    var originalSize: CGSize?
  }
  private var windowStates: [CGWindowID: WindowState?] = [:]

  func getWindowState(windowID: CGWindowID) -> WindowState {
    return windowStates[windowID]!!
  }

  func hasWindowState(windowID: CGWindowID) -> Bool {
    return windowStates.keys.contains(windowID)
  }

  func setWindowState(windowID: CGWindowID, position: CGPoint?, size: CGSize?) {
    var windowState: WindowState? = windowStates.keys.contains(windowID)
      ? windowStates[windowID]!
      : WindowState()
    windowState!.originalPosition = position!
    windowState!.originalSize = size!
    print("Updated window state: windowID =", windowID, ", windowState =", windowState!)
    windowStates.updateValue(windowState, forKey: windowID)
  }

  func removeWindowState(windowID: CGWindowID) {
    windowStates[windowID] = nil
    print("Removed window state: windowID =", windowID)
  }
}
