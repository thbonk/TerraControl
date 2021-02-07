//
//  TerraControlConfiguration.swift
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

/// This is the location of the terrarium. It is used to calculate sun and moon events.
public struct GeoLocation: Hashable, Codable {

  // MARK: - Public Properties

  public var latitude: Double
  public var longitude: Double


  // MARK: - Hashable

  public static func == (lhs: GeoLocation, rhs: GeoLocation) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(latitude)
    hasher.combine(longitude)
  }


  // MARK: - Coding Keys

  enum CodingKeys: String, CodingKey {
    case latitude
    case longitude
  }
}

/// A program determines the events for light, heating and moonlight times
public struct Program: Hashable, Codable {

  // MARK: - Public Properties

  /// Day of the year when this program starts.
  public var start: Day

  /// Program name
  public var name: String

  /// Number of hours of light. The light will be turned on around noon. The boundary of light
  /// is determined by `earliestLightTime`, `latestLightTime`, the sunrise end or sunrise start time.
  public var lightHours: Double

  /// Increase of the `lightHours` in minutes per day since the start day.
  public var increaseLightHoursPerDay: Double

  /// Number of hours of heating. The heating will be turned on around noon. The boundary of heating
  /// is determined by `earliestHeatTime`, `latestHeatTime`, the sunrise end or sunrise start time.
  public var heatHours: Double

  /// Increase of the `heatHours` in minutes per day since the start day.
  public var increaseHeatHoursPerDay: Double

  /// The earliest time or the end of the sunrise (whatever comes last) of a day when the light shall be turned on.
  public var earliestLightTime: Time

  /// The earliest time or the end of the sunrise (whatever comes last) of a day when the heating shall be turned on.
  public var earliestHeatTime: Time

  /// The latest time or begin of sunset (whatever comes first) of a day when the light shall be turned off.
  public var latestLightTime: Time

  /// The latest time or begin of sunset (whatever comes first) of a day when the heating shall be turned off.
  public var latestHeatTime: Time

  /// This flag determines whether the moonlight shall be turned on or off according to moonrise and moonset
  public var moonlightEnabled: Bool


  // MARK: - API

  public func startDate(for timezone: TimeZone) -> Date {
    let cal = Calendar.init(identifier: .gregorian)

    return
      DateComponents(
        calendar: cal,
        timeZone: timezone,
        year: cal.dateComponents(in: timezone, from: Date()).year,
        month: start.month,
        day: start.day,
        hour: 0,
        minute: 0,
        second: 0,
        nanosecond: 0)
      .date!
      .localDate
  }


  // MARK: - Hashable

  public static func == (lhs: Program, rhs: Program) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(start)
    hasher.combine(name)
  }


  // MARK: - Coding Keys

  enum CodingKeys: String, CodingKey {
    case start
    case name
    case lightHours
    case increaseLightHoursPerDay
    case heatHours
    case increaseHeatHoursPerDay
    case earliestLightTime
    case earliestHeatTime
    case latestLightTime
    case latestHeatTime
    case moonlightEnabled
  }
}

public struct TerraControlConfiguration: Hashable, Codable {

  // MARK: - Public Properties

  public var timezone: TimeZone
  public var location: GeoLocation
  public var setupCode: String
  public var bridgeName: String = "TerraController"
  public var lightSwitchName: String = "Terrarium Light"
  public var heatlightSwitchName: String = "Terrarium Heat Light"
  public var moonlightSwitchName: String = "Terrarium Moon Light"
  public var pushoverToken: String? = nil
  public var pushoverUserKey: String? = nil
  public var stateFile: String = "/var/cache/TerraControlPairings.json"
  public var programs: [Program]

  public var sortedPrograms: [Program] {
    return
      programs.sorted { (p1, p2) -> Bool in
        return p1.startDate(for: timezone) < p2.startDate(for: timezone)
      }
  }

  public var currentProgram: Program? {
    let now = Date().localDate
    var current: Program? = nil

    programs
      .sorted { (p1, p2) -> Bool in
        return p1.startDate(for: timezone) > p2.startDate(for: timezone)
      }
      .forEach { program in
        guard current == nil else {
          return
        }

        if program.startDate(for: timezone) <= now {
          current = program
        }
      }

    return current
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let tz = try values.decode(String.self, forKey: .timezone)

    timezone = TimeZone(identifier: tz)!
    location = try values.decode(GeoLocation.self, forKey: .location)
    setupCode = try values.decode(String.self, forKey: .setupCode)

    if values.contains(.bridgeName) {
      bridgeName = try values.decode(String.self, forKey: .bridgeName)
    }
    if values.contains(.lightSwitchName) {
      lightSwitchName = try values.decode(String.self, forKey: .lightSwitchName)
    }
    if values.contains(.heatlightSwitchName) {
      heatlightSwitchName = try values.decode(String.self, forKey: .heatlightSwitchName)
    }
    if values.contains(.moonlightSwitchName) {
      moonlightSwitchName = try values.decode(String.self, forKey: .moonlightSwitchName)
    }

    if values.contains(.pushoverToken) {
      pushoverToken = try values.decode(String.self, forKey: .pushoverToken)
    }
    if values.contains(.pushoverUserKey) {
      pushoverUserKey = try values.decode(String.self, forKey: .pushoverUserKey)
    }

    if values.contains(.stateFile) {
      stateFile = try values.decode(String.self, forKey: .stateFile)
    }

    programs = try values.decode([Program].self, forKey: .programs)

    if pushoverToken == nil || pushoverUserKey == nil {
      pushoverToken = nil
      pushoverUserKey = nil
    }
  }


  // MARK: - Hashable

  public static func == (lhs: TerraControlConfiguration, rhs: TerraControlConfiguration) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(timezone)
    hasher.combine(location)
  }


  // MARK: - Coding Keys

  enum CodingKeys: String, CodingKey {
    case timezone
    case location
    case setupCode
    case bridgeName
    case lightSwitchName
    case heatlightSwitchName
    case moonlightSwitchName
    case pushoverToken
    case pushoverUserKey
    case stateFile
    case programs
  }
}
