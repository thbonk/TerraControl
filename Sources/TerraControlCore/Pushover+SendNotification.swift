//
//  Pushover+SendNotification.swift
//  TerraController
//
//  Created by Thomas Bonk on 29.01.21.
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
import Pushover

public extension Pushover {
  func sendNotification(
        _ message: String,
    to recipients: [String],
    title: String? = nil,
    url: String? = nil,
    urlTitle: String? = nil,
    timestamp: Date = Date(),
    priority: Priority = .normal,
    sound: Sound = .intermission,
    devices: [String]? = nil,
    completion: ((Result<Response, Error>) -> Void)? = nil) {
    
    let notification = Notification(message: message, to: recipients)

    if let _ = title {
      _ = notification.title(title!)
    }

    if let _ = url {
      _ = notification.url(url!)
    }

    if let _ = urlTitle {
      _ = notification.urlTitle(urlTitle!)
    }

    _ = notification.timestamp(timestamp)
    _ = notification.priority(priority)
    _ = notification.sound(sound)

    if let _ = devices {
      _ = notification.devices(devices!)
    }


    send(notification) { result in
      completion?(result)
    }
  }
}
