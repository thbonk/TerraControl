//
//  Service.swift
//  TerraControl
//
//  Created by Thomas Bonk on 30.01.21.
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
import TerraControlCore
import Pushover
import Swifter
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

private var sharedService: Service = {
  Service()
}()

class Service {

  // MARK: - Class Properties

  public static var shared: Service {
    return sharedService
  }


  // MARK: - Private Properties

  private var configuration: TerraControlConfiguration? = nil
  private var pushover: Pushover? = nil
  private var pushoverUserKey: String = ""
  private var controller: TerraController? = nil

  private let ipcPort: UInt16 = 0xCAFE
  private let ipcServer: HttpServer = {
    let server = HttpServer()

    server["/stop"] = { request in
      Service.shared.controller?.stop()

      if let push = Service.shared.pushover {
        push
          .sendNotification(
            "Stopped TerraController",
            to: [Service.shared.pushoverUserKey],
            title: "TerraControl Information",
            priority: .normal,
            sound: .spacealarm) { result in

            TerraControlLogger.info("Result when sending notification: \(result)")
          }
      }

      return .ok(.htmlBody("OK"))
    }

    return server
  }()


  // MARK: - Initialization

  fileprivate init() {
    // Empty by design
  }


  // MARK: - Public Methods

  public func stopService() {
    let url = URL(string: "http://127.0.0.1:\(ipcPort)/stop")!

    _ = URLSession.shared.synchronousDataTaskWithURL(url: url)
  }

  public func startService(configurationFile: String) {
    do {
      let configUrl = URL(fileURLWithPath: configurationFile)
      let data = try Data(contentsOf: configUrl)
      let decoder = JSONDecoder()

      configuration = try decoder.decode(TerraControlConfiguration.self, from: data)

      if let pushoverToken = configuration!.pushoverToken {
        pushover = Pushover(token: pushoverToken)
        pushoverUserKey = configuration!.pushoverUserKey!
      }

      controller = try TerraController(configuration: configuration!, pushover: pushover)

      signal(SIGINT) { _ in sharedService.controller!.stop() }
      signal(SIGTERM) { _ in sharedService.controller!.stop() }

      try ipcServer.start(ipcPort, forceIPv4: true)
      try controller!.start()
    } catch {
      TerraControlLogger.error("Error while starting: \(error)")

      if let push = pushover {
        push
          .sendNotification(
            "A TerraControl error occurred: \(error)",
            to: [pushoverUserKey],
            title: "TerraControl Error",
            priority: .emergency,
            sound: .spacealarm) { result in

            TerraControlLogger.error("Result when sending notification: \(result)")
          }
      }
    }
  }
}
