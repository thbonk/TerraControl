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
import Swifter
import TerraControlCore

class TerraControlService {

  // MARK: - Public Class Properties

  public static let shared: TerraControlService = {
    return TerraControlService()
  }()


  // MARK: - Private Properties

  private let ipcPort: UInt16 = 0xCAFE
  private let ipcServer: HttpServer = {
    let server = HttpServer()

    server["/stop"] = { request in
      // TODO

      return .ok(.htmlBody("OK"))
    }

    return server
  }()


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
            print("Error while stoping the service: \(error)")
          }
        }).resume()
  }

  public func start() {
    // TODO
  }

}
