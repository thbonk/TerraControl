//
//  ConfigurationSpec.swift
//  TerraControlCoreTests
//
//  Created by Thomas Bonk on 07.12.21.
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

extension Date {
  init(day: Int, month: Int, year: Int) {
    var dateComponents = DateComponents()
    dateComponents.year = year
    dateComponents.month = month
    dateComponents.day = day

    self = Calendar(identifier: .gregorian).date(from: dateComponents)!
  }
}

final class ConfigurationSpec: QuickSpec {

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

      it("Day 1 < Day 2 is false") {
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

      it("dayInYear is calculated correctly") {
        expect(try! Day(day: 1, month: 1).dayInYear).to(be(1))
        expect(try! Day(day: 1, month: 2).dayInYear).to(be(32))
        expect(try! Day(day: 28, month: 2).dayInYear).to(be(59))
        expect(try! Day(day: 30, month: 6).dayInYear).to(be(181))
        expect(try! Day(day: 31, month: 12).dayInYear).to(be(365))
      }

      it("Minus operator is calculating the difference correctly") {
        expect((try! Day(day: 31, month: 1)) - (try! Day(day: 1, month: 1))).to(be(30))
        expect((try! Day(day: 28, month: 2)) - (try! Day(day: 1, month: 1))).to(be(58))
        expect((try! Day(day: 31, month: 12)) - (try! Day(day: 1, month: 1))).to(be(364))
        expect((try! Day(day: 1, month: 1)) - (try! Day(day: 31, month: 12))).to(be(-364))
      }
    }

    describe("Testing configuration logic") {
      var config: TerraControlCore.Configuration!

      it("Load configuration from file") {
        expect {
          let configUrl = Bundle.module.url(forResource: "configuration", withExtension: "json")!
          let data = try Data(contentsOf: configUrl)
          let decoder = JSONDecoder()

          config = try decoder.decode(Configuration.self, from: data)

          expect(config.timezone!.identifier).to(equal("Europe/Berlin"))
          expect(config.location.latitude).to(equal(49.3099737))
          expect(config.location.longitude).to(equal(7.2831639))
        }
        .toNot(throwError())
      }

      it("Selecting the correct program for a date") {
        var program = config.terrariums[0].program(for: Date(day: 10, month: 1, year: 2022))
        expect(program!.name).to(equal("Winterruhe"))

        program = config.terrariums[0].program(for: Date(day: 1, month: 10, year: 2022))
        expect(program!.name).to(equal("Einleitung Winterruhe"))

        program = config.terrariums[0].program(for: Date(day: 1, month: 12, year: 2022))
        expect(program!.name).to(equal("Winterruhe"))

        program = config.terrariums[0].program(for: Date(day: 30, month: 6, year: 2022))
        expect(program!.name).to(equal("Normalbetrieb"))
      }

      it("Validation of configuration is successful") {
        expect {
          try config.validate()
        }
        .toNot(throwError())
      }
    }
  }

}

