//
//  Date+CustomExtensions.swift
//  TerraControl
//
//  Created by Thomas Bonk on 26.01.21.
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

public extension Date {
  var localDate: Date {
    let nowUTC = self
    let timeZoneOffset = Double(TimeZone.current.secondsFromGMT(for: nowUTC))

    guard let localDate = Calendar.current.date(byAdding: .second, value: Int(timeZoneOffset), to: nowUTC) else {
      return Date()
    }

    return localDate
  }

  var startOfDay: Date {
    var startOfDay = self;

    startOfDay.time = try! Time(hour: 0, minute: 0, second: 0)
    return startOfDay
  }

  static func localDate(_ timeZone: TimeZone = TimeZone.current) -> Date {
    let nowUTC = Date()
    let timeZoneOffset = Double(timeZone.secondsFromGMT(for: nowUTC))

    guard let localDate = Calendar.current.date(byAdding: .second, value: Int(timeZoneOffset), to: nowUTC) else {
      return Date()
    }

    return localDate
  }
}
