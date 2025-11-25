//
//  FreeformDate.swift
//  NotenikUtils
//
//  Created by Herb Bowie on 11/23/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class FreeformDate {
    
    public var originalValue = ""
    
    public var yyyy = ""
    public var mm = ""
    public var dd = ""
    
    public var yy: String {
        guard yyyy.count == 4 else { return "" }
        return String(yyyy.suffix(2))
    }
    
    var timeValuesIncluded = false
    
    public var hours = ""
    public var minutes = ""
    public var seconds = ""
    public var ampm = ""
    
    var start = ""
    var end = ""
    
    var year1 = ""
    var year2 = ""
    
    var alphaMonth = false
    var funkyDate = false
    
    public var normalizedDate = ""
    
    public var time = ""
    
    /// Set an initial value as part of initialization
    public init (_ value: String) {
        set(value)
    }
    
    /**
     Set the date's value to a new string, parsing the input and attempting to
     identify the year, month and date
     */
    public func set(_ value: String) {
        
        originalValue = value
        
        yyyy = ""
        mm = ""
        dd = ""
        alphaMonth = false
        
        timeValuesIncluded = false
        hours = ""
        minutes = ""
        seconds = ""
        ampm = ""
        
        funkyDate = false
        
        let parseContext = ParseContext()
        
        var word = DateWord()
        var lastChar: Character = " "
        
        for c in value {
            if word.numbers && c == ":" {
                parseContext.lookingForTime = true
                timeValuesIncluded = true
                processWord(context: parseContext, word: word)
                word = DateWord()
            } else if StringUtils.isDigit(c) {
                if word.letters {
                    processWord(context: parseContext, word: word)
                    word = DateWord()
                } else if word.numbers && word.count == 4 {
                    processWord(context: parseContext, word: word)
                    word = DateWord()
                } else if word.numbers && yyyy.count == 4 && word.count == 2 {
                    processWord(context: parseContext, word: word)
                    word = DateWord()
                }
                word.numbers = true
                word.append(c)
            } else if StringUtils.isAlpha(c) {
                if word.numbers {
                    processWord(context: parseContext, word: word)
                    word = DateWord()
                }
                word.letters = true
                word.append(c)
            } else {
                if word.letters && word.hasData {
                    processWord(context: parseContext, word: word)
                    word = DateWord()
                } else if word.numbers && word.hasData {
                    processWord(context: parseContext, word: word)
                    word = DateWord()
                    if c == "," && dd.count > 0 {
                        parseContext.lookingForTime = true
                    }
                }
                if c == "-"
                    && lastChar == " "
                    && mm.count > 0
                    && dd.count > 0
                    && !(parseContext.lookingForTime) {
                    parseContext.startOfDateRangeCompleted = true
                }
                
            } // end if c is some miscellaneous punctuation
            
            lastChar = c
        } // end for c in value
        if word.hasData {
            processWord(context: parseContext, word: word)
        }
        
        // Fill in year if not explicitly stated
        if yyyy.count == 0 && mm.count > 0 {
            let month:Int? = Int(mm)
            if year2.count > 0 && month != nil && month! < 7 {
                yyyy = year2
            } else {
                yyyy = year1
            }
            var year:Int? = Int(yyyy)
            if year == nil {
                year = 2025
            }
        }
        normalizeDate()
    } // end func set
    
    /**
     Process each parsed word once it's been completed.
     */
    func processWord(context: ParseContext, word: DateWord) {

        if word.letters {
            processWhenLetters(context: context, word: word)
        } else if word.numbers {
            processWhenNumbers(context: context, word: word)
        } else {
            // contains something other than digits or letters?
        }
    }
    
    /**
     Process a word containing letters.
     */
    func processWhenLetters(context: ParseContext, word: DateWord) {
        if word.lowercased() == "today" {
            originalValue = DateUtils.shared.ymdToday
            self.yyyy  = DateUtils.shared.yyyyToday
            self.mm    = DateUtils.shared.mmToday
            self.dd    = DateUtils.shared.ddToday
        } else if word.lowercased() == "now" {
            originalValue = DateUtils.shared.ymdhmsNow
            self.yyyy  = DateUtils.shared.yyyyToday
            self.mm    = DateUtils.shared.mmToday
            self.dd    = DateUtils.shared.ddToday
        } else if word.lowercased() == "at"
            || word.lowercased() == "from" {
            context.lookingForTime = true
        } else if word.lowercased() == "am"
            || word.lowercased() == "pm" {
            ampm = word.word.lowercased()
            if end.count > 0 {
                end.append(" ")
                end.append(word.word)
            } else if start.count > 0 {
                start.append(" ")
                start.append(word.word)
            }
        } else if mm.count > 0 && dd.count > 0 {
            // Don't overlay the first month if a range was supplied
        } else {
            let monthIndex = DateUtils.shared.matchMonthName(word.word)
            if monthIndex > 0 {
                if mm.count > 0 {
                    dd = String(mm)
                }
                mm = String(format: "%02d", monthIndex)
                alphaMonth = true
            } else {
                funkyDate = true
            }
        }
    }
    
    /**
     Process a word containing digits.
     */
    func processWhenNumbers(context: ParseContext, word: DateWord) {
        let number: Int? = Int(word.word)
        if number != nil && number! > 1000 {
            yyyy = String(number!)
        } else if context.lookingForTime {
            if start.count == 0 {
                start.append(word.word)
            } else {
                end.append(word.word)
            }
            if hours.isEmpty && number != nil && number! >= 0 && number! <= 24 {
                hours = String(format: "%02d", number!)
            } else if minutes.isEmpty && number != nil && number! >= 0 && number! <= 60 {
                minutes = String(format: "%02d", number!)
            } else if seconds.isEmpty && number != nil && number! >= 0 && number! <= 60 {
                seconds = String(format: "%02d", number!)
            } else {
                funkyDate = true
            }
        } else if context.startOfDateRangeCompleted {
            // Let's not overwrite the start of the range with an ending date
        } else {
            // Let's use the number as part of a date
            if mm.count == 0 && number != nil && number! >= 1 && number! <= 12 {
                mm = String(format: "%02d", number!)
            } else if dd.count == 0 && number != nil && number! >= 1 && number! <= 31 {
                dd = String(format: "%02d", number!)
            } else if yyyy.count == 0 {
                if number != nil && number! > 1900 {
                    yyyy = String(number!)
                } else if number != nil && number! > 9 {
                    yyyy = "20" + String(number!)
                } else if number != nil {
                    yyyy = "2000" + String(number!)
                } else {
                    funkyDate = true
                }
            } else {
                funkyDate = true
            }
        } // end if we're just examining a normal number that is part of a date
    } // end of func processWhenNumbers
    
    /// Use the provided format string to format the date.
    ///
    /// - Parameter with: The format string to be used.
    /// - Returns: The formatted date.
    func format(with: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = with
        let possibleDate = date
        if possibleDate == nil {
            return format2(with: with)
        } else {
            return formatter.string(from: possibleDate!)
        }
    }
    
    var formatted = ""
    var formatWord = ""
    var startChar: Character = " "
    var endChar: Character = " "
    
    /// Let's do our own formatting, when we don't have a complete standard ate.
    /// - Parameter with: The fiormatting string to be used.
    /// - Returns: The formatted date.
    func format2(with: String) -> String {
        formatted = ""
        formatWord = ""
        startChar = " "
        endChar = " "
        for c in with {
            if c.isPunctuation || c.isNumber {
                applyFormatWord(termChar: c)
                formatted.append(c)
            } else if c.isWhitespace {
                applyFormatWord(termChar: c)
                if !formatted.isEmpty {
                    formatted.append(" ")
                }
            } else if formatWord.isEmpty {
                formatWord.append(c)
            } else if c == formatWord.first! {
                formatWord.append(c)
            } else {
                applyFormatWord(termChar: c)
                formatWord.append(c)
            }
        }
        applyFormatWord(termChar: " ")
        return formatted
    }
    
    func applyFormatWord(termChar: Character) {
        startChar = endChar
        endChar = termChar
        let strictDate = (!startChar.isWhitespace || !endChar.isWhitespace)
        guard !formatWord.isEmpty else { return }
        if formatWord.first! == "d" {
            if dd.isEmpty || dd == "00" {
                if strictDate {
                    if formatWord == "d" {
                        formatted.append("1")
                    } else {
                        formatted.append("01")
                    }
                }
            } else if formatWord == "d" {
                formatted.append(d)
            } else {
                formatted.append(dd)
            }
        } else if formatWord.first! == "M" {
            if mm.isEmpty || mm == "00" {
                if strictDate {
                    switch formatWord.count {
                    case 1:
                        formatted.append("6")
                    case 2:
                        formatted.append("06")
                    case 3:
                        formatted.append("Jun")
                    default:
                        formatted.append("June")
                    }
                }
            } else {
                switch formatWord.count {
                case 1:
                    formatted.append(m)
                case 2:
                    formatted.append(mm)
                case 3:
                    formatted.append(DateUtils.shared.getShortMonthName(for: mm))
                default:
                    formatted.append(DateUtils.shared.getMonthName(for: mm))
                }
            }
        } else if formatWord.first! == "y" {
            if formatWord.count > 2 {
                formatted.append(yyyy)
            } else {
                formatted.append(yy)
            }
        }
        formatWord = ""
    }
    
    /// Return an optional Date object based on the user's text input
    var date: Date? {
        return DateUtils.shared.dateFromYMD(ymdDate)
    }
    
    public var simpleDate: SimpleDate? {
        guard isFullDate else { return nil }
        return SimpleDate(yr: year, mn: month, dy: day)
    }
    
    public var isFullDate: Bool {
        guard yyyy.count > 0 else { return false }
        guard mm.count > 0 else { return false }
        guard dd.count > 0 else { return false }
        return true
    }
    
    public var year: Int? {
        return Int(yyyy)
    }
    
    /// Return the month value without any zero padding.
    public var m: String {
        if let monthInt = day {
            if monthInt > 9 {
                return mm
            } else {
                return String(mm.suffix(1))
            }
        }
        return dd
    }
    
    /// Return the month as an Integer, if possible.
    public var month: Int? {
        return Int(mm)
    }
    
    /// Return the day value without zero padding.
    public var d: String {
        if let dayInt = day {
            if dayInt > 9 {
                return dd
            } else {
                return String(dd.suffix(1))
            }
        }
        return dd
    }
    
    /// Return the day as an Integer, if possible.
    public var day: Int? {
        return Int(dd)
    }
    
    var isToday: Bool {
        return DateUtils.shared.ymdToday == self.ymdDate
    }

    /// Return a full or partial date in a yyyy-MM-dd format.
    public var ymdDate: String {
        if mm.count == 0 {
            return yyyy
        } else if dd.count == 0 {
            return yyyy + "-" + mm
        } else {
            return yyyy + "-" + mm + "-" + dd
        }
    }
    
    public var yearAndMonth: String {
        if mm.count == 0 {
            return yyyy
        } else {
            return yyyy + "-" + mm
        }
    }
    
    public var dMyDate: String {
        if mm.count == 0 {
            return yyyy
        } else if dd.count == 0 {
            return "   " + DateUtils.shared.getShortMonthName(for: mm) + " " + yyyy
        } else {
            return dd + " " + DateUtils.shared.getShortMonthName(for: mm) + " " + yyyy
        }
    }
    
    public var dMyWDate: String {
        if mm.count == 0 {
            return yyyy
        } else if dd.count == 0 {
            return "   " + DateUtils.shared.getShortMonthName(for: mm) + " " + yyyy
        } else {
            let simple = SimpleDate(yr: self.year, mn: self.month, dy: self.day)
            if simple.goodDate {
                let monthName = DateUtils.shared.getShortMonthName(for: mm)
                let dayOfWeekName = DateUtils.dayOfWeekNames[simple.dayOfWeek]
                return "\(dd) \(monthName) \(yyyy) - \(dayOfWeekName)"
            } else {
                return dd + " " + DateUtils.shared.getShortMonthName(for: mm) + " " + yyyy
            }
        }
    }
    
    /// Return date in YYYY mmm dd ww format, with a 2-letter day of the week at the end.
    public var dMyW2Date: String {
        if mm.count == 0 {
            return yyyy
        } else if dd.count == 0 {
            return "   " + DateUtils.shared.getShortMonthName(for: mm) + " " + yyyy
        } else {
            let simple = SimpleDate(yr: self.year, mn: self.month, dy: self.day)
            if simple.goodDate {
                let monthName = DateUtils.shared.getShortMonthName(for: mm)
                let dayOfWeekName = DateUtils.dayOfWeekNames[simple.dayOfWeek].prefix(2)
                return "\(dd) \(monthName) \(yyyy) / \(dayOfWeekName)"
            } else {
                return dd + " " + DateUtils.shared.getShortMonthName(for: mm) + " " + yyyy
            }
        }
    }
    
    /// Generate a normalized date representation, if possible.
    func normalizeDate() {
        time = ""
        normalizedDate = yyyy
        guard mm.count == 2 else { return }
        normalizedDate.append("-" + mm)
        guard dd.count == 2 else { return }
        normalizedDate.append("-" + dd)
        guard hours.count == 2 else { return }
        var normalizedHours = hours
        time = hours
        if ampm.count == 2 {
            if let hoursInt = Int(hours) {
                if ampm == "pm" {
                    if hoursInt < 12 {
                        normalizedHours = String(format: "%02d", hoursInt + 12)
                    }
                } else if ampm == "am" && hoursInt == 12 {
                    normalizedHours = "00"
                }
            }
        }
        normalizedDate.append(" " + normalizedHours)
        guard minutes.count == 2 else { return }
        normalizedDate.append(":" + minutes)
        time.append(":" + minutes)
        guard seconds.count == 2 else { return }
        normalizedDate.append(":" + seconds)
        time.append(":" + seconds)
    }
    
    /// An inner class containing the parsing context.
    class ParseContext {
        var lookingForTime = false
        var startOfDateRangeCompleted = false
    }
    
    /// An inner class representing one word parsed from a date string.
    class DateWord {
        var word = ""
        var lower = ""
        var numbers = false
        var letters = false
        
        init() {
            
        }
        
        func append(_ c: Character) {
            word.append(c)
        }
        
        var isEmpty: Bool {
            return (word.count == 0)
        }
        
        var hasData: Bool {
            return (word.count > 0)
        }
        
        var count: Int {
            return word.count
        }
        
        func lowercased() -> String {
            if word.count > 0 && lower.count == 0 {
                lower = word.lowercased()
            }
            return lower
        }
    }
}
