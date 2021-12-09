//
//  Configuration+Extrensions.swift
//  TerraControlCore
//
//  Created by Thomas Bonk on 07.12.21.
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

// MARK: - Day

extension Day {

  // MARK: - Public Properties

  public var dayInYear: Int {
    guard month != 1 else {
      return day
    }

    var days = 0

    for month in 0..<(month - 1) {
      days += daysPerMonth[month]
    }

    days += day

    return days
  }


  // MARK: - Public Operators

  public static func - (lhs: Day, rhs: Day) -> Int {
    return lhs.dayInYear - rhs.dayInYear
  }
}

// MARK: - Configuration

extension Configuration {

  // MARK: - Public Properties

  public var timezone: TimeZone? {
    return TimeZone(identifier: tz)
  }
}


// MARK: - Terrarium

extension Terrarium {

  // MARK: - Public Methods

  func program(for date: Date) -> Program? {
    
    // TODO
    return nil
  }

  func currentProgram() -> Program? {
    return program(for: Date())
  }
}
