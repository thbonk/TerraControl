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
import Pushover
import Swifter
import Stencil

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
  private var pushover: Pushover? = nil

  private var configuration: TerraControlConfiguration
  private var keepRunning: Bool = true

  private var bridge: Device
  private var lightSwitch: Accessory.Switch
  private var heatlightSwitch: Accessory.Switch
  private var moonlightSwitch: Accessory.Switch
  private var server: Server
  private var location: Solar.Location
  private var eventScheduler: Scheduler!
  private var switchEvents = [Scheduler]()
  private let webServer = HttpServer()


  // MARK: - Initialization

  public init(configuration: TerraControlConfiguration, pushover: Pushover?) throws {
    self.configuration = configuration
    self.pushover = pushover

    location = Solar.Location(latitude: configuration.location.latitude, longitude: configuration.location.longitude)

    lightSwitch =
      Accessory.Switch(
        info:
          Service.Info(
                    name: configuration.lightSwitchName,
            serialNumber: "d82d38c4-591f-429e-b346-5bee78ac7094",
            manufacturer: "thbonk",
                   model: "TerraController",
        firmwareRevision: revision))
    heatlightSwitch =
      Accessory.Switch(
        info:
          Service.Info(
            name: configuration.heatlightSwitchName,
            serialNumber: "027b6a61-ddf2-4d79-a90e-bf2c1fc15558",
            manufacturer: "thbonk",
            model: "TerraController",
            firmwareRevision: revision))
    moonlightSwitch =
      Accessory.Switch(
        info:
          Service.Info(
            name: configuration.moonlightSwitchName,
            serialNumber: "640a7399-4855-43d2-9932-7d21e0cf32a6",
            manufacturer: "thbonk",
            model: "TerraController",
            firmwareRevision: revision))

    bridge =
      Device(
        bridgeInfo:
          Service.Info(
                        name: configuration.bridgeName,
                serialNumber: "4dbdb2ea-fea0-4e42-bc98-4a5de21c74fd",
                manufacturer: "thbonk",
                       model: "TerraController Bridge",
            firmwareRevision: revision),
          setupCode: Device.SetupCode(stringLiteral: configuration.setupCode),
        storage: FileStorage(filename: configuration.stateFile),
        accessories: [lightSwitch, heatlightSwitch, moonlightSwitch])
    server = try Server(device: bridge)
    bridge.delegate = self

    do {
      try startWebServer()
    } catch {
      TerraControlLogger.error("Error while starting the web server: \(error)")
    }
  }


  // MARK: - API

  public func start() throws {
    TerraControlLogger.info("Starting TerraController...")

    keepRunning = true

    eventScheduler = Scheduler.schedule(at: Date().startOfDay, repeating: .seconds(24 * 60 * 60), block: scheduleEvents)

    if let push = pushover {
      push
        .sendNotification(
          "Starting TerraController",
          to: [configuration.pushoverUserKey!],
          title: "TerraControl Information",
          priority: .normal,
          sound: .spacealarm) { result in

          TerraControlLogger.info("Result when sending notification: \(result)")
        }
    }

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

  private func logAndNotify(_ message: String) {
    TerraControlLogger.info("\(message)")

    if let pushover = self.pushover {
      pushover
        .sendNotification(
          message,
          to: [configuration.pushoverUserKey!],
          title: "TerraControl Information",
          priority: .normal,
          sound: .classical) { result in

          TerraControlLogger.error("Result when sending notification: \(result)")
        }
    }
  }

  private func scheduleEvents() {
    TerraControlLogger.info("Scheduling events...")

    switchEvents.removeAll()

    guard let program = configuration.currentProgram else {
      logAndNotify("No active program found! Configured programs: \(programsSummary())")

      return
    }

    logAndNotify("Scheduling events for program >\(program.name)<")

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

  private func programsSummary() -> String {
    let result =
      configuration
      .programs
      .map { program in "'\(program.name)' -> \(program.start.day)/\(program.start.month)" }
      .joined(separator: " | ")

    return "(\(result))"
  }

  private func handleError(_ closure: () throws -> ()) {
    do {
      try closure()
    } catch {
      TerraControlLogger.error("An error occurred: \(error)")

      if let pushover = self.pushover {
        pushover
          .sendNotification(
            "A TerraControl error occurred: \(error)",
            to: [configuration.pushoverUserKey!],
            title: "TerraControl Error",
            priority: .emergency,
            sound: .spacealarm) { result in

            TerraControlLogger.error("Result when sending notification: \(result)")
        }
      }
    }
  }

  private func scheduleMoonlightOn(_ program: Program) throws -> Scheduler {
    return Scheduler.schedule(at: try moonRise(for: program)) {
      self.moonlightSwitch.`switch`.powerState.value = true

      self.logAndNotify("MoonlightOn triggered at >\(Date().localDate)<")
    }
  }

  private func scheduleMoonlightOff(_ program: Program) throws -> Scheduler {
    return Scheduler.schedule(at: try moonSet(for: program)) {
      self.moonlightSwitch.`switch`.powerState.value = false

      self.logAndNotify("MoonlightOff triggered at >\(Date().localDate)<")
    }
  }

  private func scheduleLightOn(_ program: Program) throws -> Scheduler {
    let time = try lightOnTime(program)

    TerraControlLogger.info("Scheduling LightOn for >\(time)<")

    return
      Scheduler.schedule(at: time) {
        self.lightSwitch.`switch`.powerState.value = true

        self.logAndNotify("LightOn triggered at >\(Date().localDate)<")
      }
  }

  private func lightOnTime(_ program: Program) throws -> Date {
    let halfLightHours = lightHours(for: program) / 2
    let earliestLightOnTime =
      try sunrise(for: program) < earliestLightTime(for: program)
      ? earliestLightTime(for: program)
      : try sunrise(for: program)
    var lightOnTime =
      Date(timeIntervalSince1970: try noon(for: program).timeIntervalSince1970 - (halfLightHours * 60 * 60))

    lightOnTime = lightOnTime < earliestLightOnTime ? earliestLightOnTime : lightOnTime

    return lightOnTime
  }

  private func scheduleHeatOn(_ program: Program) throws -> Scheduler {
    let time = try heatOnTime(program)

    TerraControlLogger.info("Scheduling HeatOn for >\(time)<")

    return
      Scheduler.schedule(at: time) {
        self.heatlightSwitch.`switch`.powerState.value = true

        self.logAndNotify("HeatOn triggered at >\(Date().localDate)<")
      }
  }

  private func heatOnTime(_ program: Program) throws -> Date {
    let halfHeatHours = heatHours(for: program) / 2
    let earliestHeatOnTime =
      try sunrise(for: program) < earliestHeatTime(for: program)
      ? earliestHeatTime(for: program)
      : try sunrise(for: program)
    var heatOnTime =
      Date(timeIntervalSince1970: try noon(for: program).timeIntervalSince1970 - (halfHeatHours * 60 * 60))

    heatOnTime = heatOnTime < earliestHeatOnTime ? earliestHeatOnTime : heatOnTime

    return heatOnTime
  }

  private func scheduleLightOff(_ program: Program) throws -> Scheduler {
    let time = try lightOffTime(program)

    TerraControlLogger.info("Scheduling LightOff for >\(time)<")

    return
      Scheduler.schedule(at: time) {
        self.lightSwitch.`switch`.powerState.value = false

        self.logAndNotify("LightOff triggered at >\(Date().localDate)<")
      }
  }

  private func lightOffTime(_ program: Program) throws -> Date {
    let halfLightHours = lightHours(for: program) / 2
    let latestLightOffTime =
      try sunset(for: program) > latestLightTime(for: program)
      ? latestLightTime(for: program)
      : try sunset(for: program)
    var lightOffTime =
      Date(timeIntervalSince1970: try noon(for: program).timeIntervalSince1970 + (halfLightHours * 60 * 60))

    lightOffTime = lightOffTime > latestLightOffTime ? latestLightOffTime : lightOffTime

    return lightOffTime
  }

  private func scheduleHeatOff(_ program: Program) throws -> Scheduler {
    let time = try heatOffTime(program)

    TerraControlLogger.info("Scheduling HeatOff for >\(time)<")

    return
      Scheduler.schedule(at: time) {
        self.heatlightSwitch.`switch`.powerState.value = false

        self.logAndNotify("HeatOff triggered at >\(Date().localDate)<")
      }
  }

  private func heatOffTime(_ program: Program) throws -> Date {
    let halfHeatHours = heatHours(for: program) / 2
    let latestHeatOffTime =
      try sunset(for: program) < latestHeatTime(for: program)
      ? try sunset(for: program)
      : latestHeatTime(for: program)
    var heatOffTime =
      Date(timeIntervalSince1970: try noon(for: program).timeIntervalSince1970 + (halfHeatHours * 60 * 60))

    heatOffTime = heatOffTime > latestHeatOffTime ? latestHeatOffTime : heatOffTime

    return heatOffTime
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
    let hours = program.lightHours + daysSinceStart(of: program) * program.increaseLightHoursPerDay

    return hours
  }

  private func heatHours(for program: Program) -> Double {
    let hours = program.heatHours + daysSinceStart(of: program) * program.increaseHeatHoursPerDay

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
    return try moonRise(for: program).addingTimeInterval(120 * 60)
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


  // MARK: - WebServer

  private func startWebServer() throws {
    webServer["/"] = handleControllerStatus(request:)
    try webServer.start(1337, forceIPv4: true, priority: .background)
  }

  private func handleControllerStatus(request: HttpRequest) -> HttpResponse {
    do {
      return .ok(.htmlBody(try statusPage()))
    } catch {
      return .internalServerError
    }
  }

  private func statusPage() throws -> String {
    let template = """
    <!DOCTYPE html>
    <html>
      <head>
        <title>TerraController Status</title>
      </head>

      <body>
        <table>
          <tr>
            <td>Local Date and Time:</td>
            <td>{{ dateAndTime }}</td>
          </tr>
          <tr>
            <td>Current Program:</td>
            <td>{{ currentProgram }}</td>
          </tr>
          <tr>
            <td>Sunrise:</td>
            <td>{{ sunrise }}</td>
          </tr>
          <tr>
            <td>Noon:</td>
            <td>{{ noon }}</td>
          </tr>
          <tr>
            <td>Sunset:</td>
            <td>{{ sunset }}</td>
          </tr>
          <tr>
            <td>Moonise:</td>
            <td>{{ moonrise }}</td>
          </tr>
          <tr>
            <td>Moonset:</td>
            <td>{{ moonset }}</td>
          </tr>
          <tr>
            <td>Light Hours:</td>
            <td>{{ lightHours }}</td>
          </tr>
          <tr>
            <td>Heat Hours:</td>
            <td>{{ heatHours }}</td>
          </tr>
          <tr>
            <td>Light on:</td>
            <td>{{ lightOn }}</td>
          </tr>
          <tr>
            <td>Heat Light on:</td>
            <td>{{ heatLightOn }}</td>
          </tr>
          <tr>
            <td>Light off:</td>
            <td>{{ lightOff }}</td>
          </tr>
          <tr>
            <td>Heat Light off:</td>
            <td>{{ heatLightOff }}</td>
          </tr>
          <tr>
            <td>Moon Light enabled:</td>
            <td>{{ moonLightEnabled }}</td>
          </tr>
          <tr>
            <td>Moon Light on:</td>
            <td>{{ moonLightOn }}</td>
          </tr>
          <tr>
            <td>Moon Light off:</td>
            <td>{{ moonLightOff }}</td>
          </tr>
        </table>
      </body>
    </html>
    """

    let environment = Environment()
    return try environment.renderTemplate(string: template, context: try templateContext())
  }

  private func templateContext() throws -> [String:Any] {
    if let program = configuration.currentProgram {
      return [
        "dateAndTime": Date().localDate,
        "currentProgram": program.name,
        "sunrise": try sunrise(for: program).localDate,
        "noon": try noon(for: program).localDate,
        "sunset": try sunset(for: program).localDate,
        "moonrise": try moonRise(for: program).localDate,
        "moonset": try moonSet(for: program).localDate,
        "lightHours": lightHours(for: program),
        "heatHours": heatHours(for: program),
        "lightOn": try lightOnTime(program).localDate,
        "heatLightOn": try heatOnTime(program).localDate,
        "lightOff": try lightOffTime(program).localDate,
        "heatLightOff": try heatOffTime(program).localDate,
        "moonLightEnabled": program.moonlightEnabled,
        "moonLightOn": try moonRise(for: program).localDate,
        "moonLightOff": try moonSet(for: program).localDate
      ]
    } else {
      return [
        "dateAndTime": Date(),
        "currentProgram": "none",
        "sunrise": "",
        "noon": "",
        "sunset": "",
        "moonrise": "",
        "moonset": "",
        "lightHours": "",
        "heatHours": "",
        "lightOn": "",
        "heatLightOn": "",
        "lightOff": "",
        "heatLightOff": "",
        "moonLightEnabled": "",
        "moonLightOn": "",
        "moonLightOff": ""
      ]
    }
  }
}
