//
//  DateExtension.swift
//  DateAid
//
//  Created by Aaron Williamson on 6/14/15.
//  Copyright (c) 2015 Aaron Williamson. All rights reserved.
//

import Foundation

extension NSDate {

    convenience init(dateString: String) {
        let dateStringFormatter = NSDateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        let date = dateStringFormatter.dateFromString(dateString)!
        self.init(timeInterval: 0, sinceDate: date)
    }
    
    func daysBetween() -> Int {
        let components = getComponents()
        components.setValue(2015, forComponent: .Year) // Static year component for now, should change to dynamic
        let newDate = getCalendar().dateFromComponents(components)
        let dateDay = getCalendar().ordinalityOfUnit(.Day, inUnit: .Year, forDate: newDate!)
        let nowDay = getCalendar().ordinalityOfUnit(.Day, inUnit: .Year, forDate: NSDate())
        var difference = dateDay - nowDay
        if difference < 0 {
            difference += 365
        }
        return difference
    }
    
    func ageTurning() -> Int {
        return getComponents().year + 1
    }
    
    func getCalendar() -> NSCalendar {
        return NSCalendar.currentCalendar()
    }
    
    func getComponents() -> NSDateComponents {
        return getCalendar().components([.Year, .Month, .Day], fromDate: self)
    }
    
    func getYear() -> Int {
        return getComponents().year
    }
    
    func getMonth() -> Int {
        return getComponents().month
    }
    
    func getDay() -> Int {
        return getComponents().day
    }
}