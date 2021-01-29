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
import Pushover
import Procbridge

var ctrl: TerraController? = nil
var pushover: Pushover? = nil
var pushoverUserKey: String = ""

let port:UInt16 = 0xCAFE

let ipcServer: PBServer = {
  return PBServer(port : port) { (method, args) in
    switch method {
    case "stop":
      ctrl?.stop()
      return 0

    default:
      return 0
    }
  }
}()

let main = command(
  Option<String>(
    "configurationFile",
    default: "/etc/terracontrol.config",
    description: "Path to the configuration file"),
  Flag(
    "stop",
    default: false,
    description: "Stop a running TerraController instance")) { (configurationFile: String, stop: Bool) in

  do {
    guard !stop else {
      try PBClient(host: "127.0.0.1", port: port).request(method: "stop", payload: 0)
      return
    }

    let configUrl = URL(fileURLWithPath: configurationFile)
    let data = try Data(contentsOf: configUrl)
    let decoder = JSONDecoder()
    let config = try decoder.decode(TerraControlConfiguration.self, from: data)

    if let pushoverToken = config.pushoverToken {
      pushover = Pushover(token: pushoverToken)
      pushoverUserKey = config.pushoverUserKey!
    }

    let controller = try TerraController(configuration: config, pushover: pushover)
    ctrl = controller

    signal(SIGINT) { _ in ctrl!.stop() }
    signal(SIGTERM) { _ in ctrl!.stop() }

    ipcServer.start()
    try controller.start()
  } catch {
    TerraControlLogger.error("Error while starting: \(error)")

    if let push = pushover {
      push
        .sendNotification(
          "A TerraControl error occurred: \(error)",
          to: [pushoverUserKey],
          title: "Error",
          priority: .emergency,
          sound: .spacealarm) { result in

          TerraControlLogger.error("Result when sending notification: \(result)")
        }
    }
  }
}

main.run()
