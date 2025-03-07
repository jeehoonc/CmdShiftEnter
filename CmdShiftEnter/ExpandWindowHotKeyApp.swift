//
//  ExpandWindowHotKeyApp.swift
//  ExpandWindowHotKey
//
//  Created by Jeehoon Cha on 2023/05/07.
//

import SwiftUI

@main
struct ExpandWindowHotKeyApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @Environment(\.openSettings) private var openSettings
  
  var body: some Scene {
    Settings {
      SettingsView()
        .environmentObject(appDelegate.getHotKeyRegistry().pointee)
    }
    MenuBarExtra {
      Button("Settings") {
        openSettings();
      }
    } label: {
      Text("Foo")
    }
  }
}

class AppDelegate: NSObject, NSApplicationDelegate {
  var hotKeyRegistry: HotKeyRegistry = HotKeyRegistry()

  func getHotKeyRegistry() -> UnsafeMutablePointer<HotKeyRegistry>  {
    return withUnsafeMutablePointer(to: &hotKeyRegistry) { pointer in return pointer }
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    hotKeyRegistry.registerHotKey()
  }
}
