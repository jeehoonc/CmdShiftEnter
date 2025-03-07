//
//  UInt32Converter.swift
//  TestMacOsApp
//
//  Created by Jeehoon Cha on 2023/04/30.
//

import Foundation

class DataConverter<FromType> {
  public static func convert(from: Data) -> FromType {
    var value: FromType?
    withUnsafeBytes(of: from) { bytes in value = bytes.load(as: FromType.self) }
    return value!
  }
  
  public static func convert(from: FromType) -> Data {
    var data = Data()
    withUnsafeBytes(of: from) { bytes in data.append(contentsOf: bytes) }
    return data;
  }
}

class UInt32Converter: DataConverter<UInt32> {}

class UInt64Converter: DataConverter<UInt64> {}

class UIntConverter: DataConverter<UInt64> {
  public static func convert(from: Data) -> UInt {
    return UInt(DataConverter<UInt64>.convert(from: from))
  }
  
  public static func convert(from: UInt) -> Data {
    return convert(from: UInt64(from))
  }
}
