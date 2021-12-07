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

struct Configuration: Hashable, Codable {

  // MARK: - Public Properties

  public var tz: String
  public var location: GeoLocation
  public var setupCode: String
  public var bridgeName: String
  public var terrariums: [Terrarium]


  // MARK: - Coding Keys

  enum CodingKeys: String, CodingKey {
    case tz
    case location
    case setupCode
    case bridgeName
    case terrariums
  }


  // MARK: - Hashable

  public static func == (lhs: Configuration, rhs: Configuration) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(bridgeName)
  }
}


// MARK: - Terrarium

struct Terrarium: Hashable, Codable {

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
}


// MARK: - Switch

struct Switch: Hashable, Codable {

  // MARK: - Public Properties

  public var id: String
  public var name: String


  // MARK: - Coding Keys

  enum CodingKeys: String, CodingKey {
    case id
    case name
  }


  // MARK: - Hashable

  public static func == (lhs: Switch, rhs: Switch) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}


// MARK: - Program

struct Program: Hashable, Codable {

  // MARK: - Public Properties

  public var name: String
  public var start: StartDay
  public var triggers: [Trigger]


  // MARK: - Coding Keys

  enum CodingKeys: String, CodingKey {
    case name
    case start
    case triggers
  }


  // MARK: - Hashable

  public static func == (lhs: Program, rhs: Program) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(name)
  }
}


// MARK: - StartDay

struct StartDay: Hashable, Codable {

  // MARK: - Public Properties

  public var day: String
  public var month: String


  // MARK: - Coding Keys

  enum CodingKeys: String, CodingKey {
    case day
    case month
  }


  // MARK: - Hashable

  public static func == (lhs: StartDay, rhs: StartDay) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(day)
    hasher.combine(month)
  }
}


// MARK: - Trigger

struct Trigger: Hashable, Codable {

  // MARK: - Public Properties

  public var timestamp: String
  public var switches: [String]   // array of switch IDs
  public var switchState: Bool


  // MARK: - Coding Keys

  enum CodingKeys: String, CodingKey {
    case timestamp
    case switches
    case switchState
  }


  // MARK: - Hashable

  public static func == (lhs: Trigger, rhs: Trigger) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(timestamp)
    hasher.combine(switches)
    hasher.combine(switchState)
  }
}
