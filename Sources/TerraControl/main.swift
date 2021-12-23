//
//  main.swift
//  TerraControl
//  
//  Created by Thomas Bonk on 05.12.21.
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
import Commander
import TerraControlCore

let main = command(
  Option<String>(
    "configurationFile",
    default: "/etc/terracontrol.config",
    description: "Path to the configuration file"),
  Option<String>(
    "stateFile",
    default: "/var/cache/terracontrol/terracontrol.state",
    description: "Path to the state file"),
  Flag(
    "stop",
    default: false,
    description: "Stop a running TerraController instance")) { (configurationFile: String, stateFile: String, stop: Bool) in

      guard !stop else {
        TerraControlService.shared.stop()
        return
      }

      do {
        try TerraControlService.shared.start(configurationFile: configurationFile, stateFile: stateFile)
      } catch {
        print_err("Error while starting TerraControl: \(error)")
      }
    }

main.run()
