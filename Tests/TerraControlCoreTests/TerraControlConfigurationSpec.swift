//
//  TerraControlConfigurationSpec.swift
//  TerraControl
//
//  Created by Thomas Bonk on 24.01.21.
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

final class TerraControlConfigurationSpec: QuickSpec {
  public override func spec() {
    describe("Testing the Day struct") {
      it("Two equal days have equal hash values") {
        let day1 = try! Day(day: 3, month: 10)
        let day2 = try! Day(day: 3, month: 10)

        expect(day1.hashValue).to(equal(day2.hashValue))
      }

      it("Two different days have different hash values") {
        let day1 = try! Day(day: 3, month: 10)
        let day2 = try! Day(day: 3, month: 3)

        expect(day1.hashValue).toNot(equal(day2.hashValue))
      }

      it("Day 1 < Day 2 is true") {
        let day1 = try! Day(day: 3, month: 3)
        let day2 = try! Day(day: 3, month: 10)

        expect(day1 < day2).to(beTruthy())
      }

      it("Day 1 < Day 2 is true") {
        let day1 = try! Day(day: 3, month: 10)
        let day2 = try! Day(day: 3, month: 3)

        expect(day1 < day2).toNot(beTruthy())
      }

      it("Day 1 != Day 2 is true") {
        let day1 = try! Day(day: 3, month: 10)
        let day2 = try! Day(day: 3, month: 3)

        expect(day1 != day2).to(beTruthy())
      }

      it("If month is out of range, an exception is thrown") {
        expect {
          let _ = try Day(day: 29, month: 13)
        }
        .to(throwError(Day.IllegalValue.monthOutOfRange))
      }

      it("If day is out of range, an exception is thrown") {
        expect {
          let _ = try Day(day: 29, month: 2)
        }
        .to(throwError(Day.IllegalValue.dayOutOfRange))
      }
    }

    describe("Load configuration from file") {
      it("Load configuration from file") {
        expect {
          let configUrl = Bundle.module.url(forResource: "configuration", withExtension: "json")!
          let data = try Data(contentsOf: configUrl)
          let decoder = JSONDecoder()
          let config = try decoder.decode(TerraControlConfiguration.self, from: data)

          expect(config.timezone.identifier).to(equal("Europe/Berlin"))
          expect(config.location.latitude).to(equal(49.3099737))
          expect(config.location.longitude).to(equal(7.2831639))
        }
        .toNot(throwError())
      }
    }
  }
}
