//
//  URLSession+Sync.swift
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
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import TerraControlCore

extension URLSession {
  func synchronousDataTaskWithURL(url: URL) -> (Data?, URLResponse?, Error?) {
    var data: Data?, response: URLResponse?, error: Error?

    let semaphore = DispatchSemaphore(value: 0)

    dataTask(with: url) {
      data = $0; response = $1; error = $2
      semaphore.signal()
    }
    .resume()

    _ = semaphore.wait(timeout: DispatchTime.distantFuture)

    TerraControlLogger.info("data = \(String(describing: data)) | response = \(String(describing: response)) | error = \(String(describing: error))")

    return (data, response, error)
  }
}
