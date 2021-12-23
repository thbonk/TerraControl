//
//  PushoverClient.swift
//  TerraControlCore
//
//  Created by Thomas Bonk on 19.12.21.
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
import Logging
import Pushover

class PushoverClient {
    
    // MARK: - Class Properties
    
    public static let shared: PushoverClient = {
        return PushoverClient()
    }()
    
    
    // MARK: - Private Properties

    private let logger = Logger(class: PushoverClient.self)
    private var pushover: Pushover? = nil
    private var userKey: String? = nil
    
    
    // MARK: - Initialization
    
    private init() {
        // Empty by design
    }
    
    
    // MARK: - Public Methods
    
    public func initialize(token: String, userKey: String) {
        self.pushover = Pushover(token: token)
        self.userKey = userKey
    }
    
    public func error(message: String) {
        self.notify(title: "TerraController Error", message: message, priority: .emergency)
    }
    
    public func warning(message: String) {
        self.notify(title: "TerraController Warning", message: message, priority: .high)
    }
    
    public func information(message: String) {
        self.notify(title: "TerraController Information", message: message, priority: .normal)
    }
    
    
    // MARK: - Private Methods
    
    private func notify(title: String, message: String, priority: Priority) {
        pushover?.send(Notification(message: message, to: [userKey!]).title(title)) { result in
            self.logger.info("Result when sending push notification: \(result)")
        }
    }
}
