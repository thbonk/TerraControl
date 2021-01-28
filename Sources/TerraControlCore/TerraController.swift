//
//  TerraController.swift
//  TerraControl
//
//  Created by Thomas Bonk on 25.01.21.
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
import Logging
import HAP

public private(set) var TerraControlLogger: Logger = {
  let logger = Logger(label: "TerraController")

  LoggingSystem.bootstrap { label in
    var handler = StreamLogHandler.standardOutput(label: label)

    handler.logLevel = .info
    return handler
  }

  return logger
}()

public class TerraController: DeviceDelegate {

  // MARK: - Private Properties

  private let revision = Revision("1")

  private var configuration: TerraControlConfiguration
  private var keepRunning: Bool = true

  private var bridge: Device
  private var lightSwitch: Accessory.Switch
  private var heatlightSwitch: Accessory.Switch
  private var moonlightSwitch: Accessory.Switch
  private var alarm: Accessory.SecuritySystem
  private var server: Server
  private var location: Solar.Location
  private var eventScheduler: Scheduler!
  private var switchEvents = [Scheduler]()


  // MARK: - Initialization

  public init(configuration: TerraControlConfiguration) throws {
    self.configuration = configuration

    location = Solar.Location(latitude: configuration.location.latitude, longitude: configuration.location.longitude)

    alarm =
      Accessory.SecuritySystem(
        info:
          Service.Info(
            name: "Error in \(configuration.bridgeName!)",
            serialNumber: "1ea75203-1f70-408c-9778-0e6ec4e7cf41",
            manufacturer: "thbonk",
            model: "TerraController",
            firmwareRevision: revision))
    lightSwitch =
      Accessory.Switch(
        info:
          Service.Info(
                    name: configuration.lightSwitchName!,
            serialNumber: "d82d38c4-591f-429e-b346-5bee78ac7094",
            manufacturer: "thbonk",
                   model: "TerraController",
        firmwareRevision: revision))
    heatlightSwitch =
      Accessory.Switch(
        info:
          Service.Info(
            name: configuration.heatlightSwitchName!,
            serialNumber: "027b6a61-ddf2-4d79-a90e-bf2c1fc15558",
            manufacturer: "thbonk",
            model: "TerraController",
            firmwareRevision: revision))
    moonlightSwitch =
      Accessory.Switch(
        info:
          Service.Info(
            name: configuration.moonlightSwitchName!,
            serialNumber: "640a7399-4855-43d2-9932-7d21e0cf32a6",
            manufacturer: "thbonk",
            model: "TerraController",
            firmwareRevision: revision))

    bridge =
      Device(
        bridgeInfo:
          Service.Info(
                        name: configuration.bridgeName!,
                serialNumber: "4dbdb2ea-fea0-4e42-bc98-4a5de21c74fd",
                manufacturer: "thbonk",
                       model: "TerraController Brdige",
            firmwareRevision: revision),
          setupCode: Device.SetupCode(stringLiteral: configuration.setupCode),
        storage: FileStorage(filename: configuration.stateFile!),
        accessories: [lightSwitch, heatlightSwitch, moonlightSwitch])
    server = try Server(device: bridge)
    bridge.delegate = self
  }


  // MARK: - API

  public func start() throws {
    TerraControlLogger.info("Starting TerraController...")

    keepRunning = true

    eventScheduler = Scheduler.schedule(at: Date().startOfDay, repeating: .seconds(24 * 60 * 60), block: scheduleEvents)

    while keepRunning {
      RunLoop.current.run(mode: .default, before: Date.distantFuture)
    }

    try server.stop()
  }

  public func stop() {
    DispatchQueue.main.async {
      TerraControlLogger.info("Shutting down TerraController...")

      self.keepRunning = false
    }
  }


  // MARK: - Schedule Events

  private func scheduleEvents() {
    TerraControlLogger.info("Scheduling events")

    switchEvents.removeAll()

    if let program = configuration.currentProgram {
      if program.moonlightEnabled {
        handleError { switchEvents.append(try scheduleMoonlightOn(program)) }
        handleError { switchEvents.append(try scheduleMoonlightOff(program)) }
      }

      if lightHours(for: program) > 0 {
        handleError { switchEvents.append(try scheduleLightOn(program)) }
        handleError { switchEvents.append(try scheduleLightOff(program)) }
      }

      if heatHours(for: program) > 0 {
        handleError { switchEvents.append(try scheduleHeatOn(program)) }
        handleError { switchEvents.append(try scheduleHeatOff(program)) }
      }
    }
  }

  private func handleError(_ closure: () throws -> ()) {
    do {
      try closure()
    } catch {
      TerraControlLogger.error("An error occurred: \(error)")

      alarm.securitySystem.securitySystemCurrentState.value = .alarmTriggered
    }
  }

  private func scheduleMoonlightOn(_ program: Program) throws -> Scheduler {

    return Scheduler.schedule(at: try moonRise(for: program)) {
      self.moonlightSwitch.`switch`.powerState.value = true
    }
  }

  private func scheduleMoonlightOff(_ program: Program) throws -> Scheduler {
    return Scheduler.schedule(at: try moonSet(for: program)) {
      self.moonlightSwitch.`switch`.powerState.value = false
    }
  }

  private func scheduleLightOn(_ program: Program) throws -> Scheduler {
    let halfLightHours = lightHours(for: program) / 2
    let earliestLightOnTime =
      try sunrise(for: program) < earliestLightTime(for: program)
      ? earliestLightTime(for: program)
      : try sunrise(for: program)
    var lightOnTime =
      Date(timeIntervalSince1970: try noon(for: program).timeIntervalSince1970 - (halfLightHours * 60 * 60))

    lightOnTime = lightOnTime < earliestLightOnTime ? earliestLightOnTime : lightOnTime

    TerraControlLogger.info("Scheduling LightOn for >\(lightOnTime)<")

    return
      Scheduler.schedule(at: lightOnTime) {
        self.lightSwitch.`switch`.powerState.value = true

        TerraControlLogger.info("LightOn triggered at >\(Date().localDate)<")
      }
  }

  private func scheduleHeatOn(_ program: Program) throws -> Scheduler {
    let halfHeatHours = heatHours(for: program) / 2
    let earliestHeatOnTime =
      try sunrise(for: program) < earliestHeatTime(for: program)
      ? earliestHeatTime(for: program)
      : try sunrise(for: program)
    var heatOnTime =
      Date(timeIntervalSince1970: try noon(for: program).timeIntervalSince1970 - (halfHeatHours * 60 * 60))

    heatOnTime = heatOnTime < earliestHeatOnTime ? earliestHeatOnTime : heatOnTime

    TerraControlLogger.info("Scheduling HeatOn for >\(heatOnTime)<")

    return
      Scheduler.schedule(at: heatOnTime) {
        self.heatlightSwitch.`switch`.powerState.value = true

        TerraControlLogger.info("HeatOn triggered at >\(Date().localDate)<")
      }
  }

  private func scheduleLightOff(_ program: Program) throws -> Scheduler {
    let halfLightHours = lightHours(for: program) / 2
    let latestLightOffTime =
      try sunset(for: program) > latestLightTime(for: program)
      ? latestLightTime(for: program)
      : try sunset(for: program)
    var lightOffTime =
      Date(timeIntervalSince1970: try noon(for: program).timeIntervalSince1970 + (halfLightHours * 60 * 60))

    lightOffTime = lightOffTime > latestLightOffTime ? latestLightOffTime : lightOffTime

    TerraControlLogger.info("Scheduling LightOff for >\(lightOffTime)<")

    return
      Scheduler.schedule(at: lightOffTime) {
        self.lightSwitch.`switch`.powerState.value = false

        TerraControlLogger.info("LightOff triggered at >\(Date().localDate)<")
      }
  }

  private func scheduleHeatOff(_ program: Program) throws -> Scheduler {
    let halfHeatHours = heatHours(for: program) / 2
    let latestHeatOffTime =
      try sunrise(for: program) < latestHeatTime(for: program)
      ? latestHeatTime(for: program)
      : try sunrise(for: program)
    var heatOffTime =
      Date(timeIntervalSince1970: try noon(for: program).timeIntervalSince1970 + (halfHeatHours * 60 * 60))

    heatOffTime = heatOffTime > latestHeatOffTime ? latestHeatOffTime : heatOffTime

    TerraControlLogger.info("Scheduling HeatOff for >\(heatOffTime)<")

    return
      Scheduler.schedule(at: heatOffTime) {
        self.heatlightSwitch.`switch`.powerState.value = false

        TerraControlLogger.info("HeatOff triggered at >\(Date().localDate)<")
      }
  }


  // MARK: - Date related methods

  private func start(of program: Program) -> Date {
    var startOfProgram = Date()

    startOfProgram.day = program.start
    startOfProgram.time = try! Time(hour: 0)

    return startOfProgram
  }

  private func daysSinceStart(of program: Program) -> Double {
    let programStart = start(of: program)
    let today = Date().startOfDay
    let result = (today.timeIntervalSince1970 - programStart.timeIntervalSince1970) / (24 * 60 * 60)

    return result
  }

  private func lightHours(for program: Program) -> Double {
    var hours = program.lightHours

    if program.increaseLightHoursPerDay > 0 {
      hours = hours + daysSinceStart(of: program) * program.increaseLightHoursPerDay
    }

    return hours
  }

  private func heatHours(for program: Program) -> Double {
    var hours = program.heatHours

    if program.increaseHeatHoursPerDay > 0 {
      hours = hours + daysSinceStart(of: program) * program.increaseHeatHoursPerDay
    }

    return hours
  }

  private func noon(for program: Program) throws -> Date {
    return try Solar.noon(for: Date(), at: location, in: configuration.timezone)
  }

  private func moonRise(for program: Program) throws -> Date {
    // TODO Calculate moon rise
    var rise = Date()

    rise.time = try Time(hour: 22)

    return rise
  }

  private func moonSet(for program: Program) throws -> Date {
    // TODO Calculate moon set
    return try moonRise(for: program).addingTimeInterval(120)
  }

  private func sunrise(for program: Program) throws -> Date {
    return try Solar.sunRiseAndSet(for: Date(), at: location, in: configuration.timezone).sunrise
  }

  private func sunset(for program: Program) throws -> Date {
    return try Solar.sunRiseAndSet(for: Date(), at: location, in: configuration.timezone).sunset
  }

  private func earliestLightTime(for program: Program) -> Date {
    var now = Date()

    now.time = program.earliestLightTime
    return now
  }

  private func earliestHeatTime(for program: Program) -> Date {
    var now = Date()

    now.time = program.earliestHeatTime
    return now
  }

  private func latestLightTime(for program: Program) -> Date {
    var now = Date()

    now.time = program.latestLightTime
    return now
  }

  private func latestHeatTime(for program: Program) -> Date {
    var now = Date()

    now.time = program.latestHeatTime
    return now
  }
}
