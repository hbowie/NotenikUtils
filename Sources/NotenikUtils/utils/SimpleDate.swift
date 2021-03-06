//
//  SimpleDate.swift
//  Notenik
//
//  Created by Herb Bowie on 4/20/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A simple date class that allows a date to be easily incremented.
public class SimpleDate: CustomStringConvertible {
    
    public var year = 2019
    public var month = 04
    public var day = 20
    public var dayOfWeek = 7
    public var daysInMonth = 30
    
    public var description: String {
        return yyyy + "-" + mm + "-" + dd
    }
    
    public var yyyy: String {
        return String(format: "%04d", year)
    }
    
    public var mm: String {
        return String(format: "%02d", month)
    }
    
    public var dd: String {
        return String(format: "%02d", day)
    }
    
    public var weekend: Bool {
        return dayOfWeek == DateUtils.sunday || dayOfWeek == DateUtils.saturday
    }
    
    public var date: Date? {
        return DateUtils.shared.dateFromYMD(year: year, month: month, day: day)
    }
    
    public var goodDate: Bool {
        return (year > 0
            && month > 0 && month <= 12
            && day > 0 && day <= 31)
    }
    
    public init() {
        
    }
    
    public convenience init(year: Int, month: Int, day: Int) {
        self.init()
        self.year = year
        self.month = month
        self.day = day
        calcDaysInMonth()
        calcDayOfWeek()
    }
    
    public convenience init(yr: Int?, mn: Int?, dy: Int?) {
        self.init()
        if let y = yr {
            year = y
        } else {
            year = 0
        }
        if let m = mn {
            month = m
        } else {
            month = 0
        }
        if let d = dy {
            day = d
        } else {
            day = 0
        }
        if goodDate {
            calcDaysInMonth()
            calcDayOfWeek()
        } else {
            dayOfWeek = 1
            daysInMonth = 30
        }
    }
    
    public func setDayOfMonth(_ dayOfMonth: Int) {
        day = dayOfMonth
        adjustInvalidDay()
        calcDayOfWeek()
    }
    
    public func addDays(_ days: Int) {
        day = day + days
        while day > daysInMonth {
            day = day - daysInMonth
            bumpMonthUp()
        }
        while day < 1 {
            bumpMonthDown()
            day = day + daysInMonth
        }
        calcDayOfWeek()
    }
    
    public func addMonths(_ months: Int) {
        month = month + months
        while month > 12 {
            month = month - 12
            year += 1
        }
        while month < 1 {
            month = month + 12
            year -= 1
        }
        calcDaysInMonth()
        adjustInvalidDay()
        calcDayOfWeek()
    }
    
    public func addYears(_ years: Int) {
        year = year + years
        calcDaysInMonth()
        adjustInvalidDay()
        calcDayOfWeek()
    }
    
    func bumpMonthUp() {
        month += 1
        if month > 12 {
            year += 1
            month = 1
        }
        calcDaysInMonth()
    }
    
    func bumpMonthDown() {
        month -= 1
        if month < 1 {
            year -= 1
            month = 12
        }
        calcDaysInMonth()
        adjustInvalidDay()
    }
    
    func adjustInvalidDay() {
        if day > daysInMonth {
            day = daysInMonth
        }
    }
    
    func calcDaysInMonth() {
        daysInMonth = DateUtils.shared.getDaysInMonth(year: year, month: month)
    }
    
    func calcDayOfWeek() {
        dayOfWeek = DateUtils.shared.dayOfWeekForYMD(year: year, month: month, day: day)
    }
}
