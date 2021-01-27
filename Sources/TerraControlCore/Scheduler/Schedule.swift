//
//  Schedule.swift
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

open class Scheduler {

  // MARK: - Private Class Properties

  private static let schedulerQueue =
    DispatchQueue(
           label: "TC-SchedulerQueue",
             qos: .background,
      attributes: [.concurrent])


  // MARK: - Private Properties

  private var timerSource = DispatchSource.makeTimerSource(flags: [.strict], queue: Scheduler.schedulerQueue)
  private var deadline: DispatchTime
  private var interval: DispatchTimeInterval
  private var handler: () -> ()


  // MARK: - Initialization

  private init(deadline: DispatchTime, repeating interval: DispatchTimeInterval = .never, block: @escaping () -> ()) {
    self.deadline = deadline
    self.interval = interval
    self.handler = block

    timerSource.schedule(deadline: self.deadline, repeating: self.interval)
    timerSource.setEventHandler { [weak self] in
      self?.handler()
    }
    timerSource.resume()
  }

  public class func schedule(
               at date: Date,
    repeating interval: DispatchTimeInterval = .never,
                 block: @escaping () -> ()) -> Scheduler {

    return
      Scheduler(
         deadline: .now() + .seconds(Int(date.timeIntervalSince(Date()))),
        repeating: interval,
            block: block)
  }
}
