//
//  TerraController+DeviceDelegate.swift
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
import HAP

public extension TerraController {
  /// Tells the delegate that a controller subscribed for updates.
  ///
  /// - Parameters:
  ///   - accessory: the accessory to which the characteristic's service
  ///     belongs
  ///   - service: the service to which the characteristic belongs
  ///   - characteristic: the characteristic that was subscribed to
  func characteristicListenerDidSubscribe(
    _ accessory: Accessory,
    service: Service,
    characteristic: AnyCharacteristic) {

    TerraControlLogger
      .info(
        .init(
          stringLiteral:
            "Characteristic listener did subsxcribe to characteristic >\(characteristic)< "
            + "of accessory >\(accessory)< belonging to service >\(service)<"))
  }

  /// Tells the delegate that a controller unsubscribed from updates.
  ///
  /// - Parameters:
  ///   - accessory: the accessory to which the characteristic's service
  ///     belongs
  ///   - service: the service to which the characteristic belongs
  ///   - characteristic: the characteristic that was unsubscribed from
  func characteristicListenerDidUnsubscribe(
    _ accessory: Accessory,
    service: Service,
    characteristic: AnyCharacteristic) {

    TerraControlLogger
      .info(
        .init(
          stringLiteral:
            "Characteristic listener did unsubsxcribe to characteristic >\(characteristic)< "
            + "of accessory >\(accessory)< belonging to service >\(service)<"))
  }

  /// Tells the delegate that identification of the device was requested.
  ///
  /// When the user configures a device, there might be multiple similar
  /// devices. In order to identify the individual device, HAP
  /// accommodates for an identification event. When possible, you should
  /// make the physical device emit sound and/or light for the user to be
  /// able to identify the device.
  func didRequestIdentification() {
    TerraControlLogger.info("Identification was requested")
  }

  /// Tells the delegate that identification of an accessory was requested.
  ///
  /// When the user configures an accessory, there might be multiple similar
  /// accessories. In order to identify the individual accessory, HAP
  /// accommodates for an identification event. When possible, you should
  /// make the physical accessory emit sound and/or light for the user to be
  /// able to identify the accessory.
  ///
  /// - Parameter accessory: accessory to be identified
  func didRequestIdentificationOf(_ accessory: Accessory) {
    TerraControlLogger.info("Identification of accessory >\(accessory)< was requested")
  }

  /// Tells the delegate that the Device PairingState has changed.
  ///
  func didChangePairingState(from: PairingState, to: PairingState) {
    TerraControlLogger.info("The pairing state changed from >\(from)< to >\(to)<")
  }

  /// Tells the delegate that the value of a characteristic has changed.
  ///
  /// - Parameters:
  ///   - accessory: the accessory to which the characteristic's service
  ///     belongs
  ///   - service: the service to which the characteristic belongs
  ///   - characteristic: the characteristic that was changed
  ///   - newValue: the new value of the characteristic
  func characteristic<T>(
    _ characteristic: GenericCharacteristic<T>,
    ofService service: Service,
    ofAccessory accessory: Accessory,
    didChangeValue value: T?) {

    TerraControlLogger
      .info(
        .init(
          stringLiteral:
            "The value of characteristic >\(characteristic)< "
            + "of accessory >\(accessory)< belonging to service >\(service)< "
            + "changed to >\(String(describing: value))<"))
  }
}
