//
//  Time.swift
//  TerraControl
//
//  Created by Thomas Bonk on 24.01.21.
//  Copyright 2021 Thomas Bonk <thomas@meandmymac.de>
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

public struct Time: Hashable, Codable, Comparable {

  // MARK: - Public Enums

  public enum IllegalValue: Error {
    case hourOutOfRange
    case minuteOutOfRange
    case secondOutOfRange
  }


  // MARK: - Public Properties

  public var hour: Int
  public var minute: Int = 0
  public var second: Int = 0

  public var seconds: Int {
    return hour * 60 * 60 + minute * 60 + second
  }


  // MARK: - Initialization

  public init(hour: Int, minute: Int = 0, second: Int = 0) throws {
    if hour < 0 || hour > 23 {
      throw IllegalValue.hourOutOfRange
    }
    if minute < 0 || minute > 59 {
      throw IllegalValue.minuteOutOfRange
    }
    if second < 0 || second > 59 {
      throw IllegalValue.secondOutOfRange
    }

    self.hour = hour
    self.minute = minute
    self.second = second
  }

  public init(seconds: Int) throws {
    try self.init(hour: seconds / 3600, minute: (seconds / 60) % 60, second: seconds % 60)
  }

  // MARK: - Comparable

  public static func < (lhs: Time, rhs: Time) -> Bool {
    let lhsVal = lhs.hour << 16 | lhs.minute << 8 | lhs.second
    let rhsVal = rhs.hour << 16 | rhs.minute << 8 | rhs.second

    return lhsVal < rhsVal
  }

  public static func <= (lhs: Time, rhs: Time) -> Bool {
    return (lhs < rhs) || (lhs == rhs)
  }

  public static func > (lhs: Time, rhs: Time) -> Bool {
    return (lhs != rhs) && !(lhs < rhs)
  }

  public static func >= (lhs: Time, rhs: Time) -> Bool {
    return (lhs > rhs) || (lhs == rhs)
  }

  public static func != (lhs: Time, rhs: Time) -> Bool {
    return !(lhs == rhs)
  }


  // MARK: - Calculation

  public static func + (lhs: Time, rhs: Time) throws -> Time {
    let result = lhs.seconds + rhs.seconds

    return try Time(seconds: result)
  }

  public static func - (lhs: Time, rhs: Time) throws -> Time {
    let result = lhs.seconds - rhs.seconds

    return try Time(seconds: result)
  }

  public static func / (lhs: Time, rhs: Double) throws -> Time {
    let result = Double(lhs.seconds) / rhs

    return try Time(seconds: Int(result))
  }

  public static func * (lhs: Time, rhs: Double) throws -> Time {
    let result = Double(lhs.seconds) * rhs

    return try Time(seconds: Int(result))
  }


  // MARK: - Hashable

  public static func == (lhs: Time, rhs: Time) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(hour)
    hasher.combine(minute)
    hasher.combine(second)
  }


  // MARK: - Coding Keys

  public enum CodingKeys: String, CodingKey {
    case hour
    case minute
    case second
  }
}

public extension Date {
  var time: Time? {
    get {
      let calendar = Calendar(identifier: .gregorian)
      let components = calendar.dateComponents([.hour, .minute, .second], from: self)

      return try? Time(hour: components.hour!, minute: components.minute!, second: components.second!)
    }
    set {
      let calendar = Calendar(identifier: .gregorian)
      let currentComponents = calendar.dateComponents([.year, .day, .month], from: self)
      let components =
        DateComponents(
          calendar: calendar,
          year: currentComponents.year,
          month: currentComponents.month,
          day: currentComponents.day,
          hour: newValue?.hour ?? 0,
          minute: newValue?.minute ?? 0,
          second: newValue?.second ?? 0,
          nanosecond: 0)

      self = components.date!
    }
  }
}
