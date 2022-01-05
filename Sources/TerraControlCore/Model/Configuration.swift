//
//  Configuration.swift
//  TerraControlCore
//
//  Created by Thomas Bonk on 06.12.21.
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


private func check(_ condition: Bool, error: Error) throws {
  guard condition else {
    throw error
  }
}


// MARK: - GeoLocation

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


// MARK: - Configuration

public struct Configuration: Hashable, Codable {

  // MARK: - Errors

  public enum ConfigurationError: String, Error {
    case noTimezoneGiven          = "Configuration has an empty timezone"
    case noSetupCodeGiven         = "Configuration has an empty setup code"
    case noBridgeNameGiven        = "Configuration has an empty bridge name"
    case douplicateTerrariumNames = "Configuration contains terrariums with equal names"
  }


  // MARK: - Public Properties

  public var tz: String
  public var location: GeoLocation
  public var setupCode: String
  public var bridgeName: String
  public var pushoverToken: String?
  public var pushoverUserKey: String?
  public var terrariums: [Terrarium]


  // MARK: - Coding Keys

  enum CodingKeys: String, CodingKey {
    case tz
    case location
    case setupCode
    case bridgeName
    case pushoverToken
    case pushoverUserKey
    case terrariums
  }


  // MARK: - Hashable

  public static func == (lhs: Configuration, rhs: Configuration) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(bridgeName)
  }


  // MARK: - Validation

  public func validate() throws {
    try check(!tz.isEmpty, error: ConfigurationError.noTimezoneGiven)
    try check(!setupCode.isEmpty, error: ConfigurationError.noSetupCodeGiven)
    try check(!bridgeName.isEmpty, error: ConfigurationError.noBridgeNameGiven)

    try check(
      Dictionary(grouping: terrariums, by: \.name).allSatisfy( {(_, value: [Any]) in value.count == 1 }),
      error: ConfigurationError.douplicateTerrariumNames)

    try terrariums.forEach { terrarium in
      try terrarium.validate()
    }
  }
}


// MARK: - Terrarium

public struct Terrarium: Hashable, Codable {

  // MARK: - Errors

  public enum ConfigurationError: String, Error {
    case noNameGiven          = "Terrarium configuration has an empty name"
    case duplicateSwitchIds     = "Terrarium configuration has an switches with duplicate IDs"
    case duplicateProgramNames  = "Terrarium configuration has an programs with duplicate names"
  }


  // MARK: - Public Properties

  public var name: String
  public var switches: [Switch]
  public var programs: [Program]


  // MARK: - Coding Keys

  enum CodingKeys: String, CodingKey {
    case name
    case switches
    case programs
  }


  // MARK: - Hashable

  public static func == (lhs: Terrarium, rhs: Terrarium) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(name)
  }


  // MARK: - Validation

  public func validate() throws {
    try check(!name.isEmpty, error: ConfigurationError.noNameGiven)
    try check(
      Dictionary(grouping: switches, by: \.id).allSatisfy( {(_, value: [Any]) in value.count == 1 }),
      error: ConfigurationError.duplicateSwitchIds)
    try check(
      Dictionary(grouping: programs, by: \.name).allSatisfy( {(_, value: [Any]) in value.count == 1 }),
      error: ConfigurationError.duplicateSwitchIds)
    try switches.forEach { sw in
      try sw.validate()
    }
    try programs.forEach { program in
      try program.validate()
    }

    // TODO check switches of programs and their rules
  }
}


// MARK: - Switch

public struct Switch: Hashable, Codable {

  // MARK: - Errors

  public enum ConfigurationError: String, Error {
    case noIdGiven            = "Switch configuration has an empty id"
    case noNameGiven          = "Switch configuration has an empty name"
    case noSerialNumberGiven  = "Switch configuration has an empty serial number"
    case noManufacturerGiven  = "Switch configuration has an empty manufacturer"
    case noModelGiven         = "Switch configuration has an empty model"
  }


  // MARK: - Public Properties

  public var id: String
  public var name: String
  public var serialNumber: String = UUID().uuidString
  public var manufacturer: String = "Thomas Bonk"
  public var model: String = "TerraController Switch"


  // MARK: - Coding Keys

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case serialNumber
    case manufacturer
    case model
  }


  // MARK: - Hashable

  public static func == (lhs: Switch, rhs: Switch) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }


  // MARK: - Validation

  public func validate() throws {
    try check(!id.isEmpty, error: ConfigurationError.noIdGiven)
    try check(!name.isEmpty, error: ConfigurationError.noNameGiven)
    try check(!serialNumber.isEmpty, error: ConfigurationError.noSerialNumberGiven)
    try check(!manufacturer.isEmpty, error: ConfigurationError.noManufacturerGiven)
    try check(!model.isEmpty, error: ConfigurationError.noModelGiven)
  }
}


// MARK: - Program

public struct Program: Hashable, Codable {

  // MARK: - Errors

  public enum ConfigurationError: String, Error {
    case noNameGiven          = "Program configuration has an empty name"
    case duplicateRules       = "Program configuration has duplicate rules"
  }


  // MARK: - Public Properties

  public var name: String
  public var start: Day
  public var rules: [Rule]


  // MARK: - Coding Keys

  enum CodingKeys: String, CodingKey {
    case name
    case start
    case rules
  }


  // MARK: - Hashable

  public static func == (lhs: Program, rhs: Program) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(name)
  }


  // MARK: - Validation

  public func validate() throws {
    try check(!name.isEmpty, error: ConfigurationError.noNameGiven)
    try check(
      Dictionary(grouping: rules, by: \.hashValue).allSatisfy( {(_, value: [Any]) in value.count == 1 }),
      error: ConfigurationError.duplicateRules)
  }
}


// MARK: - StartDay

public struct Day: Hashable, Codable, Comparable {

  // MARK: - Public Enums

  public enum IllegalValue: Error {
    case dayOutOfRange
    case monthOutOfRange
  }


  // MARK: - Public Properties

  public var day: Int
  public var month: Int

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


  // MARK: - Private Properties

  private let daysPerMonth = [
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


  // MARK: - Coding Keys

  enum CodingKeys: String, CodingKey {
    case day
    case month
  }


  // MARK: - Initialization

  public init(day: Int, month: Int) throws {
    if month < 1 || month > 12 {
      throw IllegalValue.monthOutOfRange
    }
    if day < 1 || day > daysPerMonth[month - 1] {
      throw IllegalValue.dayOutOfRange
    }

    self.day = day
    self.month = month
  }


  // MARK: - Public Operators

  public static func - (lhs: Day, rhs: Day) -> Int {
    return lhs.dayInYear - rhs.dayInYear
  }
  

  // MARK: - Comparable

  public static func < (lhs: Day, rhs: Day) -> Bool {
    return lhs.dayInYear < rhs.dayInYear
  }

  public static func <= (lhs: Day, rhs: Day) -> Bool {
    return (lhs < rhs) || (lhs == rhs)
  }

  public static func > (lhs: Day, rhs: Day) -> Bool {
    return !(lhs < rhs)
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
}


// MARK: - Trigger

public struct Rule: Hashable, Codable {

  // MARK: - Public Properties

  // Hours the switches are turned on is around noon
  // turn on : noon - hoursOn / 2
  // turn off: noon + hoursOn / 2
  public var hoursOn: Double
  public var hoursOnIncrementPerDay: Double = 0
  public var switches: [String]   // array of switch IDs


  // MARK: - Coding Keys

  enum CodingKeys: String, CodingKey {
    case hoursOn
    case switches
  }


  // MARK: - Hashable

  public static func == (lhs: Rule, rhs: Rule) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(hoursOn)
    hasher.combine(switches)
  }
}
