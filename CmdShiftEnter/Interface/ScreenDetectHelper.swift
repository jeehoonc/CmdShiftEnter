//
//  ScreenDetectHelper.swift
//  ExpandWindowHotKey
//
//  Created by Jeehoon Cha on 11/24/24.
//

import SwiftUI

struct ScreenDetectHelper {
  static func convertOriginToQuartz(frame: NSRect) -> NSRect {
    var converted: NSRect = frame
    converted.origin.y = NSMaxY(NSScreen.screens[0].frame) - NSMaxY(frame)
    return converted
  }

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
