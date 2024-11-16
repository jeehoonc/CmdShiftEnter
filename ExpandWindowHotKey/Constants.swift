//
//  Constants.swift
//  TestMacOsApp
//
//  Created by Jeehoon Cha on 2023/05/01.
//

import Foundation

enum Constants {
  public static let signature = toFourCharCode(stringValue: "swat")
  
  private static func toFourCharCode(stringValue: String) -> Int {
    var result: Int = 0
    if let data = stringValue.data(using: String.Encoding.macOSRoman) {
      data.withUnsafeBytes({ (rawBytes) in
        let bytes = rawBytes.bindMemory(to: UInt8.self)
        for i in 0 ..< data.count {
          result = result << 8 + Int(bytes[i])
        }
      })
    }
    return result
  }
}
