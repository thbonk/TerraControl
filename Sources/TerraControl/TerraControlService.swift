//
//  TerraControlService.swift
//  TerraControl
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
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Logging
import Swifter
import TerraControlCore

class TerraControlService {

  // MARK: - Public Class Properties

  public static let shared: TerraControlService = {
    return TerraControlService()
  }()


  // MARK: - Private Properties

  private var configuration: Configuration!
  private var controller: TerraController!

  private let ipcPort: UInt16 = 0xCAFE
  private let ipcServer: HttpServer = {
    let server = HttpServer()

    server["/stop"] = { request in
      // TODO
      TerraControlService.shared.controller.stop()
      return .ok(.htmlBody("OK"))
    }

    return server
  }()

  private var logger = Logger(class: TerraControlService.self)


  // MARK: - Initialization

  fileprivate init() {
    // Empty by design
  }


  // MARK: - API

  public func stop() {
    let url = URL(string: "http://127.0.0.1:\(ipcPort)/stop")!

    URLSession
      .shared
      .dataTask(
        with: url,
        completionHandler: { _, _, error in
          if let error = error {
            self.logger.error("Error while starting TerraControl: \(error)")
          }
        })
      .resume()
  }

  public func start(configurationFile: String, stateFile: String) throws {
    do {
      let configUrl = URL(fileURLWithPath: configurationFile)
      let data = try Data(contentsOf: configUrl)
      let decoder = JSONDecoder()

      configuration = try decoder.decode(Configuration.self, from: data)
      try configuration.validate()

      controller = try TerraController(configuration: configuration, stateFile: stateFile)
      try ipcServer.start(ipcPort, forceIPv4: true)
      try controller!.start()

      signal(SIGINT) { _ in TerraControlService.shared.stop() }
      signal(SIGTERM) { _ in TerraControlService.shared.stop() }
    } catch {
      logger.error("Error while starting TerraControl: \(error)")
    }
  }

}
