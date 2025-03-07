//
//  SettingsView.swift
//  TestMacOsApp
//
//  Created by Jeehoon Cha on 2023/04/30.
//

import SwiftUI
import Carbon

struct GeneralSettingsView: View {
  @EnvironmentObject private var hotKeyRegistry: HotKeyRegistry
  
  @State private var inputModifierFlags: NSEvent.ModifierFlags?
  @State private var inputKeyCode: UInt16?
  
  var body: some View {
    Form {
      VStack {
        Text("\(hotKeyRegistry.getModifierFlagsString()) \(hotKeyRegistry.getKeyCodeString())")
        Divider()
        if let inputModifierFlags = inputModifierFlags, let inputKeyCode = inputKeyCode {
          HStack {
            Text("\(ModifierFlagsConverter.toString(flags: inputModifierFlags)) \(NSEventKeyCodeToString.convert(from: inputKeyCode))")
            Button("Save") {
              hotKeyRegistry.registerHotKey(modifierFlags: inputModifierFlags, keyCode: Int(inputKeyCode))
              self.inputKeyCode = nil
              self.inputModifierFlags = nil
            }
          }
        }
      }
    }
    .padding(20)
    .frame(width: 500, height: 100)
    .onAppear {
      NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
        self.inputModifierFlags = event.modifierFlags
        self.inputKeyCode = event.keyCode
        return event
      }
    }
  }
}

struct SettingsView: View {
    private enum Tabs: Hashable {
        case general, advanced
    }
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
        }
        .padding(20)
        .frame(width: 500, height: 150)
    }
}
