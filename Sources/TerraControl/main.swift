//
//  main.swift
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
import Commander
import TerraControlCore

var ctrl: TerraController? = nil

let main = command(
  Option<String>(
    "configurationFile",
    default: "/etc/terracontrol.config",
    description: "Path to the configuration file")) { (configurationFile: String) in

  do {
    let configUrl = URL(fileURLWithPath: configurationFile)
    let data = try Data(contentsOf: configUrl)
    let decoder = JSONDecoder()
    let config = try decoder.decode(TerraControlConfiguration.self, from: data)

    let controller = try TerraController(configuration: config)
    ctrl = controller

    signal(SIGINT) { _ in ctrl!.stop() }
    signal(SIGTERM) { _ in ctrl!.stop() }

    try controller.start()
  } catch {
    TerraControlLogger.error("Error while starting: \(error)")
  }
}

main.run()
