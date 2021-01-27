//
//  Day.swift
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

public struct Day: Hashable, Codable, Comparable {

  // MARK: - Public Enums

  public enum IllegalValue: Error {
    case dayOutOfRange
    case monthOutOfRange
  }


  // MARK: - Public Properties

  public var day: Int
  public var month: Int


  // MARK: - Initialization

  public init(day: Int, month: Int) throws {
    let daysPerMonth = [
      31, // January
      28, // February
      31, // March
      30, // April
      31, // May
      30, // June
      31, // July
      31, // August
      30, // September
      31, // October
      30, // November
      31] // December

    if month < 1 || month > 12 {
      throw IllegalValue.monthOutOfRange
    }
    if day < 1 || day > daysPerMonth[month - 1] {
      throw IllegalValue.dayOutOfRange
    }

    self.day = day
    self.month = month
  }


  // MARK: - Comparable

  public static func < (lhs: Day, rhs: Day) -> Bool {
    let lhsVal = lhs.day << 8 | lhs.month
    let rhsVal = rhs.day << 8 | rhs.month

    return lhsVal < rhsVal
  }

  public static func <= (lhs: Day, rhs: Day) -> Bool {
    return (lhs < rhs) || (lhs == rhs)
  }

  public static func > (lhs: Day, rhs: Day) -> Bool {
    return (lhs != rhs) && !(lhs < rhs)
  }

  public static func >= (lhs: Day, rhs: Day) -> Bool {
    return (lhs > rhs) || (lhs == rhs)
  }

  public static func != (lhs: Day, rhs: Day) -> Bool {
    return !(lhs == rhs)
  }


  // MARK: - Hashable

  public static func == (lhs: Day, rhs: Day) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(day)
    hasher.combine(month)
  }


  // MARK: - Coding Keys

  public enum CodingKeys: String, CodingKey {
    case day
    case month
  }
}

public extension Date {
  var day: Day? {
    get {
      let calendar = Calendar(identifier: .gregorian)
      let components = calendar.dateComponents([.month, .day], from: self)

      return try? Day(day: components.day!, month: components.month!)
    }
    set {
      let calendar = Calendar(identifier: .gregorian)
      let currentComponents = calendar.dateComponents([.year, .hour, .minute, .second, .nanosecond], from: self)
      let components =
        DateComponents(
          calendar: calendar,
          year: currentComponents.year,
          month: newValue?.month ?? 1,
          day: newValue?.day ?? 1,
          hour: currentComponents.hour,
          minute: currentComponents.minute,
          second: currentComponents.second,
          nanosecond: currentComponents.nanosecond)

      self = components.date!
    }
  }
}
