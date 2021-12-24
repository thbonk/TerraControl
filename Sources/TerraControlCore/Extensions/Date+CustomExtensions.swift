//
//  Date+CustomExtensions.swift
//  TerraControlCore
//
//  Created by Thomas Bonk on 09.12.21.
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

struct Time {
    
    // MARK: - Public Properties
    
    var hour: Int
    var minute: Int
    var second: Int
}

extension Date {
    
    // MARK: - Public Properties
    
    static var yesterday: Date {
        return Date().dayBefore
    }
    
    static var tomorrow:  Date {
        return Date().dayAfter
    }
    
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    
    static var startOfDay: Date {
        var now = Date()
        
        now.time = Time(hour: 0, minute: 0, second: 0)
        
        return now
    }
    
    var startOfDay: Date {
        var now = self
        
        now.time = Time(hour: 0, minute: 0, second: 0)
        
        return now
    }
    
    static func date(for timezone: TimeZone) -> Date {
        return Date().date(for: timezone)
    }
    
    func date(for timezone: TimeZone) -> Date {
        let nowUTC = self
        let timeZoneOffset = Double(timezone.secondsFromGMT(for: nowUTC))
        
        guard let localDate = Calendar.current.date(byAdding: .second, value: Int(timeZoneOffset), to: nowUTC) else {
            return Date()
        }
        
        return localDate
    }
    
    var day: Day {
        return
        try! Day(day: Calendar.current.component(.day, from: self), month: Calendar.current.component(.month, from: self))
    }
    
    var time: Time {
        get {
            let calendar = Calendar(identifier: .gregorian)
            let components = calendar.dateComponents([.hour, .minute, .second], from: self)
            
            return Time(hour: components.hour!, minute: components.minute!, second: components.second!)
        }
        set {
            let calendar = Calendar(identifier: .gregorian)
            let currentComponents = calendar.dateComponents([.year, .day, .month], from: self)
            let components =
            DateComponents(
                calendar: calendar,
                year: currentComponents.year,
                month: currentComponents.month,
                day: currentComponents.day,
                hour: newValue.hour,
                minute: newValue.minute,
                second: newValue.second,
                nanosecond: 0)
            
            
            self = components.date!
        }
    }
}
