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
import Swifter
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

var ctrl: TerraController? = nil
var pushover: Pushover? = nil
var pushoverUserKey: String = ""

let port:UInt16 = 0xCAFE

let ipcServer: HttpServer = {
  let server = HttpServer()

  server["/stop"] = { request in
    ctrl?.stop()
    return .ok(.htmlBody("OK"))
  }

  return server
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
      let url = URL(string: "http://127.0.0.1:\(port)/stop")!
      var request = URLRequest(url: url)
      request.httpMethod = "GET"

      let data = try NSURLConnection.sendSynchronousRequest(request, returning: nil)
      print("\(data)")
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

    try ipcServer.start(port, forceIPv4: true)
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
