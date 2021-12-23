//
//  DateExtensionsSpec.swift
//  TerraControlCoreTests
//
//  Created by Thomas Bonk on 13.12.21.
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
import Quick
import Nimble

@testable import TerraControlCore

final class DateExtensionsSpec: QuickSpec {

  public override func spec() {

    describe("Testing the Date extensions") {

      it("Getting start of day is successfull") {
        let startOfDay = Date.startOfDay

        expect(startOfDay.time.hour).to(equal(0))
        expect(startOfDay.time.minute).to(equal(0))
        expect(startOfDay.time.second).to(equal(0))
      }

      it("Setting the time of a date is successful") {
        var noon = Date()

        noon.time = Time(hour: 12, minute: 0, second: 0)

        expect(noon.time.hour).to(equal(12))
        expect(noon.time.minute).to(equal(0))
        expect(noon.time.second).to(equal(0))
      }
    }
  }
}
