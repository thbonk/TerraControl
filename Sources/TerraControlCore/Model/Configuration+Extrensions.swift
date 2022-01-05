//
//  Configuration+Extrensions.swift
//  TerraControlCore
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


// MARK: - Configuration

extension Configuration {

  // MARK: - Public Properties

  public var timezone: TimeZone? {
    return TimeZone(identifier: tz)
  }
}


// MARK: - Terrarium

extension Terrarium {

  // MARK: - Public Methods

  func program(for date: Date) -> Program? {
    var currentProgram: Program? = nil
    let today = date.day
    let sortedPrograms =
      programs
        .sorted { p1, p2 in
          p1.start < p2.start
        }

    sortedPrograms
      .forEach { program in
        guard currentProgram == nil else {
          return
        }

        if program.start <= today {
          currentProgram = program
        }
      }

    guard currentProgram != nil else {
      return sortedPrograms.last
    }

    return currentProgram
  }

  func currentProgram() -> Program? {
    return program(for: Date())
  }
}
