//
//  TerraController.swift
//  TerraControllerCore
//
//  Created by Thomas Bonk on 12.12.21.
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
import HAP
import Logging

public class TerraController: DeviceDelegate {
    
    // MARK: - Private Properties
    
    private let logger = Logger(class: TerraController.self)
    private let configuration: Configuration
    private let stateFile: String
    private let location: Solar.Location
    
    private var keepRunning: Bool = true
    
    private var programScheduler: Scheduler!
    private var switchEvents = [Scheduler]()
    
    private let revision = Revision("1")
    
    private var bridge: Device!
    private var server: Server!
    private var switches = [String:Accessory.Switch]()
    
    
    // MARK: - Initialization
    
    public init(configuration: Configuration, stateFile: String) throws {
        self.configuration = configuration
        self.stateFile = stateFile
        self.location =
        Solar.Location(latitude: configuration.location.latitude, longitude: configuration.location.longitude)
        
        if let token = configuration.pushoverToken, let userKey = configuration.pushoverUserKey {
            PushoverClient.shared.initialize(token: token, userKey: userKey)
        }
        
        initializeSwitches()
        try initializeBridge()
    }
    
    private func initializeSwitches() {
        configuration
            .terrariums
            .forEach { terrarium in
                switches =
                switches
                    .merging(
                        terrarium
                            .switches
                            .reduce(into:  [String:Accessory.Switch]()) { dictionary, sw in
                                dictionary[sw.id] =
                                Accessory
                                    .Switch(
                                        info:
                                            Service.Info(
                                                name: "\(terrarium.name): \(sw.name)",
                                                serialNumber: sw.serialNumber,
                                                manufacturer: sw.manufacturer,
                                                model: sw.model,
                                                firmwareRevision: revision))
                            },
                        uniquingKeysWith: { (first, _) in first })
            }
    }
    
    private func initializeBridge() throws {
        bridge =
        Device(
            bridgeInfo:
                Service.Info(
                    name: configuration.bridgeName,
                    serialNumber: "de61442e-5b40-11ec-bf63-0242ac130002",
                    manufacturer: "Thomas Bonk",
                    model: "TerraController Bridge",
                    firmwareRevision: revision),
            setupCode: Device.SetupCode(stringLiteral: configuration.setupCode),
            storage: FileStorage(filename: stateFile),
            accessories: switches.values.shuffled())
        server = try Server(device: bridge)
        bridge.delegate = self
    }
    
    
    // MARK: - Start and stop
    
    public func start() throws {
        logger.info("Starting TerraControl...")
        PushoverClient.shared.information(message: "Starting TerraControl")
        
        keepRunning = true
        
        programScheduler =
            Scheduler.schedule(
                at: Date.startOfDay,
                repeating: .seconds(24 * 60 * 60),
                block: schedulePrograms)
        
        while keepRunning {
            RunLoop.current.run(mode: .default, before: Date.distantFuture)
        }
        
        logger.info("Stopping TerraControl...")
        PushoverClient.shared.information(message: "Stopping TerraControl")
        try server.stop()
    }
    
    public func stop() {
        DispatchQueue.main.async {
            self.logger.info("Shutting down TerraController...")
            
            self.keepRunning = false
        }
    }
    
    
    // MARK: - Private Methods
    
    private func schedulePrograms() {
        logger.info("Scheduling programs...")
        
        switchEvents.removeAll()
        
        do {
            let now = Date.date(for: configuration.timezone!)
            let noon = try Solar.noon(for: now, at: location, in: configuration.timezone!).date(for: configuration.timezone!)
            
            configuration
                .terrariums
                .forEach { terrarium in
                    let program = terrarium.currentProgram()
                    
                    PushoverClient.shared.information(message: "Scheduling program \(program!.name) for terrarium \(terrarium.name) at \(now). Noon is at \(noon).")
                    
                    program?
                        .rules
                        .forEach { rule in
                            guard rule.hoursOn > 0 else {
                                return
                            }
                            
                            let halfIntervall =
                              ((rule.hoursOn + rule.hoursOnIncrementPerDay * Double(now.day - terrarium.currentProgram()!.start)) / 2) * 3600
                            
                            
                            guard halfIntervall > 0 else {
                                return
                            }
                            
                            let onTime = noon - halfIntervall
                            let offTime = noon + halfIntervall
                            
                            switchEvents.append(Scheduler.schedule(at: onTime) {
                                self.setState(switches: rule.switches, state: true)
                            })
                            switchEvents.append(Scheduler.schedule(at: offTime) {
                                self.setState(switches: rule.switches, state: false)
                            })
                        }
                }
        } catch {
            logger.error("Error while scheduling programs: \(error)")
        }
    }
    
    private func setState(switches: [String], state: Bool) {
        switches
            .forEach { switchId in
                let sw = self.switches[switchId]!
                
                sw.switch.powerState.value = state
                
                let stateDescription = state ? "ON" : "OFF"
                PushoverClient.shared.information(message: "Setting power state of switch \(sw.info.name.value!) to \(stateDescription)")
            }
    }
}
