//
//  DateUtils.swift
//  notenik
//
//  Created by Herb Bowie on 11/28/18.
//  Copyright © 2018 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//
import Foundation

/**
 A singleton class providing access to a number of useful date utilities.
 */
public class DateUtils {
    
    public static let shared = DateUtils()
    
    public let firstWeekday = Calendar.current.firstWeekday
    
    var now : Date
    var ymdFormatter  : DateFormatter
    var ymdhmsFormatter: DateFormatter
    var yyyyFormatter : DateFormatter
    var mmFormatter   : DateFormatter
    var ddFormatter   : DateFormatter
    var gregCalendar  : Calendar
    var dateTimeFormatter: DateFormatter
    public var timestampFormatter: DateFormatter
    
    public static let monthNames = [
        "n/a",
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December"
    ]
    
    public static let dayOfWeekNames = [
        "n/a",
        "Sunday",
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday"
    ];
    
    static let sunday = 1
    static let monday = 2
    static let tuesday = 3
    static let wednesday = 4
    static let thursday = 5
    static let friday = 6
    static let saturday = 7
    
    /**
     Initialize constant references to today's current date.
     */
    private init() {
        now = Date()
        ymdFormatter = DateFormatter()
        ymdFormatter.dateFormat = "yyyy-MM-dd"
        ymdhmsFormatter = DateFormatter()
        ymdhmsFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        yyyyFormatter = DateFormatter()
        yyyyFormatter.dateFormat = "yyyy"
        mmFormatter = DateFormatter()
        mmFormatter.dateFormat = "MM"
        ddFormatter = DateFormatter()
        ddFormatter.dateFormat = "dd"
        gregCalendar = Calendar(identifier: .gregorian)
        dateTimeFormatter = DateFormatter()
        dateTimeFormatter.dateStyle = .medium
        dateTimeFormatter.timeStyle = .medium
        timestampFormatter = DateFormatter()
        timestampFormatter.locale = Locale(identifier: "en_US_POSIX")
        timestampFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        timestampFormatter.dateFormat = "yyyyMMddHHmmss"
    }
    
    public func refreshToday() {
        now = Date()
    }
    
    /// Return today's date in yyyy-MM-dd format
    public var ymdToday: String {
        return ymdFormatter.string(from: now)
    }
    
    public var ymdhmsNow: String {
        return ymdhmsFormatter.string(from: now)
    }
    
    /// Return today's year in yyyy format
    public var yyyyToday: String {
        return yyyyFormatter.string(from: now)
    }
    
    /// Return today's month in mm format
    public var mmToday: String {
        return mmFormatter.string(from: now)
    }
    
    /// Return today's day of month in dd format
    public var ddToday: String {
        return ddFormatter.string(from: now)
    }
    
    public var dateTimeToday: String {
        now = Date()
        return dateTimeFormatter.string(from: now)
    }
    
    /// Return an optional date object when passed a string in "yyyy-mm-dd" format
    public func dateFromYMD(_ ymdDate: String) -> Date? {
        return ymdFormatter.date(from: ymdDate)
    }
    
    /// Return an optional date object when passed individual integer values for year, month and day
    public func dateFromYMD(year: Int, month: Int, day: Int) -> Date? {
        // Specify date components
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        
        // Create date from components
        let userCalendar = Calendar.current
        return userCalendar.date(from: dateComponents)
    }
    
    func dayOfWeekForYMD(year: Int, month: Int, day: Int) -> Int {
        let date = dateFromYMD(year: year, month: month, day: day)
        if date == nil {
            return 0
        } else {
            return dayOfWeekForDate(date!)
        }
    }
    
    /// Return the day of week for a date, where 1 is Sunday, 2 is Monday, etc.
    public func dayOfWeekForDate(_ date: Date) -> Int {
        return gregCalendar.component(.weekday, from: date)
    }
    
    /// Return a date formatted as a yyyy-MM-dd string
    public func ymdFromDate(_ date : Date) -> String {
        return ymdFormatter.string(from: date)
    }
    
    /// Return a date formatted as a "dd MMM yyy" string
    public func dMyFromDate(_ date: Date) -> String {
        let year = gregCalendar.component(.year, from: date)
        let month = gregCalendar.component(.month, from: date)
        let day = gregCalendar.component(.day, from: date)
        return String(format: "%02d", day) + " " + getShortMonthName(for: month) + " " + String(format: "%04d", year)
    }
    
    /**
    Given a complete or partial month name, return an index value pointing to the full month name,
    or a negative number if no match.
     
    - Parameter name: Possible full or partial name of a month
    - Returns: Index value pointing to full name of month, if a match, otherwise a negative number. Note that 1 points to January, 2 to February, etc., since 0 points to 'n/a'
     */
    public func matchMonthName (_ name: String) -> Int {
        var i = 1
        var looking = true
        let nameLower = name.lowercased()
        while looking && i < DateUtils.monthNames.count {
            let nextName = DateUtils.monthNames[i].lowercased()
            if nextName.hasPrefix(nameLower) {
                looking = false
            } else {
                i += 1
            }
        }
        if looking {
            i = -1
        }
        return i
    }
    
    /**
     Given a complete or partial day of week name, return an index value pointing to the full day of week name,
     or a negative number if no match.
     
     - Parameter name: Possible full or partial name of a month
     - Returns: Index value pointing to full day of week name, if a match, otherwise a negative number. Note that 1 points to Sunday, 2 to Monday, etc., since 0 points to 'n/a'
     */
    public func matchDayOfWeekName (_ name : String) -> Int {
        var i = 1
        var looking = true
        let nameLower = name.lowercased()
        while looking && i < DateUtils.dayOfWeekNames.count {
            let nextName = DateUtils.dayOfWeekNames[i].lowercased()
            if nextName.hasPrefix(nameLower) {
                looking = false
            } else {
                i += 1
            }
        }
        if looking {
            i = -1
        }
        return i
    }
    
    /// Return the name of the day of the week, given a weekly calendar column index,
    /// and using the user's preferred starting day of week.
    /// - Parameter columnIndex: A column index, in the range of 0 - 6.
    /// - Returns: The name of the corresponding day of the week.
    public func dayOfWeekName(for columnIndex: Int) -> String {
        guard columnIndex >= 0 && columnIndex <= 6 else { return "undefined" }
        var weekdayIndex = columnIndex + firstWeekday
        if weekdayIndex > 7 {
            weekdayIndex -= 7
        }
        return DateUtils.dayOfWeekNames[weekdayIndex]
    }
    
    /// Get a short (3-letter) name of the given month.
    ///
    /// - Parameter monthNumberStr: A string containing the month number (1 - 12)
    /// - Returns: The 3-character beginning of the month name, or an empty string if an invalid month number. 
    public func getShortMonthName(for monthNumberStr: String) -> String {
        let monthNumber = Int(monthNumberStr)
        guard let mm = monthNumber else { return "" }
        return getShortMonthName(for: mm)
    }
    
    /// Get a short (3-letter) name of the given month.
    ///
    /// - Parameter monthNumber: The month number, in the range 1 - 12.
    /// - Returns: The 3-character beginning of the month name,
    ///            or an empty string if an invalid month number.
    public func getShortMonthName(for monthNumber: Int) -> String {
        guard monthNumber > 0 && monthNumber <= 12 else { return "" }
        return String(DateUtils.monthNames[monthNumber].prefix(3))
    }
    
    public func getDaysInMonth(year: Int, month: Int) -> Int {
        let dateComponents = DateComponents(year: year, month: month)
        let calendar = Calendar.current
        let date = calendar.date(from: dateComponents)!
        
        let range = calendar.range(of: .day, in: .month, for: date)!
        return range.count
    }
    
}
