//
//  StringUtils.swift
//  Notenik
//
//  Created by Herb Bowie on 11/28/18.
//  Copyright © 2018 - 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A collection of utility methods for working with Strings.
public class StringUtils {
    
    private init() {
        
    }
    
    public static let lowerChars = "a"..."z"
    public static let upperChars = "A"..."Z"
    public static let digits     = "0"..."9"
    
    public static let badMailto = "mailto:message:"
    
    public static func addCommonUrlSchemes(str: String) -> String {

        var link = str
        if link.hasPrefix(StringUtils.badMailto) {
            link.removeFirst(7)
            return link
        }
            
        if str.contains(":") {
            return str
        } else if str.contains("@") {
            return "mailto:" + str
        } else if str.hasPrefix("www.") || str.hasSuffix(".com") || str.hasSuffix(".org") || str.hasSuffix(".net") {
            return "http://" + str
        } else {
            return str
        }
    }
    
    /// Examine the passed string and separate out any preceding number from any following alphabetic label,
    /// dropping any intervening spacing and punctuation.
    /// - Parameter str: A string containing some sort of positive integer followed by some sort
    /// of alphabetic label.
    /// - Returns: The number, as an integer, if any was found; otherwise returns -1; then the
    ///  label. 
    public static func splitNumberAndLabel(str: String) -> (Int, String) {
        var number = 0
        var digitCount = 0
        let label = SolidString()
        for c in str {
            if StringUtils.isDigit(c) {
                number = (number * 10) + Int(String(c))!
                digitCount += 1
            } else if c.isLetter {
                label.append(c)
            } else if StringUtils.isWhitespace(c) && !label.isEmpty {
                label.append(" ")
            }
        }
        if number == 0 && digitCount == 0 {
            number = -1
        }
        return (number, label.str)
    }
    
    public static func websiteFromLink(str: String) -> String {
        let pieces = str.components(separatedBy: "/")
        if pieces.count >= 3 {
            return pieces[2]
        } else {
            return str
        }
    }
    
    public static func matchCounts(str1: String, str2: String) -> (Int, Int) {
        var index1 = str1.startIndex
        var index2 = str2.startIndex
        var matched = 0
        var unmatched = 0
        while index1 < str1.endIndex && index2 < str2.endIndex {
            let char1 = str1[index1]
            let lower1 = char1.lowercased()
            let char2 = str2[index2]
            let lower2 = char2.lowercased()
            if lower1 == lower2 {
                matched += 1
                index1 = str1.index(after: index1)
                index2 = str2.index(after: index2)
            } else if char1.isWhitespace || char1.isPunctuation {
                index1 = str1.index(after: index1)
            } else if char2.isWhitespace || char2.isPunctuation {
                index2 = str2.index(after: index2)
            } else if str1.count < str2.count {
                unmatched += 1
                index2 = str2.index(after: index2)
            } else {
                unmatched += 1
                index1 = str1.index(after: index1)
            }
        }
        return (matched, unmatched)
    }
    
    public static func prepHTMLforJSON(_ value: String) -> String {
        var v = value
        var i = v.startIndex
        for c in v {
            if c == "\"" {
                v.insert("\\", at: i)
                i = v.index(after: i)
                i = v.index(after: i)
            } else if c.isNewline {
                v.remove(at: i)
                v.insert(" ", at: i)
                i = v.index(after: i)
            } else {
                i = v.index(after: i)
            }
        }
        return v
    }
    
    /// Write a single column's worth of data. The writer will enclose in quotation marks
    /// and encode embedded quotation marks as needed (with two quote chars representing one).
    public static func encaseInQuotesAsNeeded(_ value: String, sepChar: Character = "\t") -> String {
        var v = value
        var quotesNeeded = false
        var i = v.startIndex
        for c in v {
            if c == sepChar {
                quotesNeeded = true
            } else if c.isNewline {
                quotesNeeded = true
            } else if c == "\"" {
                quotesNeeded = true
                v.insert("\"", at: i)
                i = v.index(after: i)
            }
            i = v.index(after: i)
        }
        if quotesNeeded {
            return("\"" + v + "\"")
        } else {
            return(v)
        }
    }
    
    /// Convert a string to its lowest common denominator, dropping white space, punctuation,
    /// and embedded tags, converting all letters to lowercase, and dropping leading articles (a, an, the).
    ///
    /// - Parameter str: The string to be converted.
    ///
    /// - Returns: The lowest common denominator, allowing easy comparison,
    ///            and eliminating trivial differences.
    ///
    public static func toCommon(_ str: String, leavingSlashes: Bool = false) -> String {
        let lower = str.lowercased()
        var common = ""
        var startingTagCount = 0
        var charsWithinTags = 0
        for c in lower {
            if isDigit(c) || c.isLetter {
                common.append(c)
                if startingTagCount > 0 {
                    charsWithinTags += 1
                }
            } else if c == "/" && leavingSlashes {
                common.append(c)
            } else if c == "<" {
                if startingTagCount == 0 {
                    charsWithinTags = 0
                }
                startingTagCount += 1
            } else if c == ">" && startingTagCount > 0 {
                startingTagCount -= 1
                if startingTagCount == 0 && charsWithinTags > 0 {
                    common.removeLast(charsWithinTags)
                    charsWithinTags = 0
                }
            } else if c == " " {
                if common == "a" || common == "the" || common == "an" {
                    common = ""
                }
            }
        }
        return common
    }
    
    /// Convert a string to a conventional, universal file name, changing spaces
    /// to dashes, removing any odd characters, making all letters lower-case, and
    /// converting white space to hyphens.
    ///
    /// - Parameter from: The file name to be converted.
    /// - Returns: The converted file name.
    public static func toCommonFileName(_ from: String, leavingSlashes: Bool = false) -> String {
        var out = ""
        var whiteSpace = true
        var index = from.startIndex
        var nextIndex = from.startIndex
        for char in from {
            var nextChar: Character = " "
            if index < from.endIndex {
                nextIndex = from.index(after: index)
                if nextIndex < from.endIndex {
                    nextChar = from[nextIndex]
                }
            }
            if char.isLetter {
                out.append(char.lowercased())
                whiteSpace = false
            } else if isDigit(char) {
                out.append(char)
                whiteSpace = false
            } else if char == "." {
                if nextIndex >= from.endIndex || nextChar != " " {
                    out.append(char)
                    whiteSpace = false
                }
            } else if char == "/" && leavingSlashes {
                out.append(char)
            } else if isWhitespace(char) || char == "_" || char == "/" || char == "-" {
                if !whiteSpace && nextIndex < from.endIndex {
                    out.append("-")
                    whiteSpace = true
                }
            }
            index = from.index(after: index)
        }
        return out
    }
    
    public static func autoID(_ from: String) -> String {
        
        let convertToLower = true
        let dotDisp:   CharDisposition = .remain
        let dashDisp:  CharDisposition = .remain
        let spaceDisp: CharDisposition = .remove
        let otherDisp: CharDisposition = .remove
        
        var id = ""
        var pendingSpaces = 0

        for char in from {
            
            if char.isLetter {
                if convertToLower {
                    append(char.lowercased(), spaceDisp: spaceDisp, str: &id, pendingSpaces: &pendingSpaces)
                } else {
                    append(char, spaceDisp: spaceDisp, str: &id, pendingSpaces: &pendingSpaces)
                }
                
            } else if StringUtils.isDigit(char) {
                append(char, spaceDisp: spaceDisp, str: &id, pendingSpaces: &pendingSpaces)
                
            } else if char == "." {
                disposeOf(char, disp: dotDisp, spaceDisp: spaceDisp, str: &id, pendingSpaces: &pendingSpaces)
                
            } else if char == "-" {
                disposeOf(char, disp: dashDisp, spaceDisp: spaceDisp, str: &id, pendingSpaces: &pendingSpaces)

            } else if isWhitespace(char) {
                append(char, spaceDisp: spaceDisp, str: &id, pendingSpaces: &pendingSpaces)
                
            } else {
                disposeOf(char, disp: otherDisp, spaceDisp: spaceDisp, str: &id, pendingSpaces: &pendingSpaces)
            }

        }
        
        return id
    }
    
    public static func disposeOf(_ char: Character,
                                 disp: CharDisposition,
                                 spaceDisp: CharDisposition,
                                 str: inout String,
                                 pendingSpaces: inout Int) {
        switch disp {
        case .remove:
            break
        case .remain:
            append(char, spaceDisp: spaceDisp, str: &str, pendingSpaces: &pendingSpaces)
        case .replaceWithDash:
            append("-", spaceDisp: spaceDisp, str: &str, pendingSpaces: &pendingSpaces)
        }
    }
    
    public static func append(_ inStr: String, 
                              spaceDisp: CharDisposition,
                              str: inout String,
                              pendingSpaces: inout Int) {
        
        for char in inStr {
            append(char, spaceDisp: spaceDisp, str: &str, pendingSpaces: &pendingSpaces)
        }
    }
    
    public static func append(_ char: Character, 
                              spaceDisp: CharDisposition,
                              str: inout String,
                              pendingSpaces: inout Int) {
        
        if char.isWhitespace {
            if str.count == 0 {
                // Discard leading spaces
            } else {
                pendingSpaces += 1
            }
        } else {
            if pendingSpaces > 0 {
                switch spaceDisp {
                case .remove:
                    break
                case .remain:
                    str.append(" ")
                case .replaceWithDash:
                    str.append("-")
                }
                pendingSpaces = 0
            }
            str.append(char)
        }
    }
    
    public enum CharDisposition {
        case remove
        case remain
        case replaceWithDash
    }
    
    /// Scan for an link starting with http:// or https:// and then, if found,
    /// surround the URL with anchor start and end tags, with the href value
    /// pointing to the URL that was found. Leave any preceding or trailing
    /// characters in place. 
    public static func convertLinks(_ from: String) -> String {
        var out = ""
        var index = from.startIndex
        var priorChar: Character = " "
        var priorIndex = from.startIndex
        var linkStartFound = false
        var linkStartIndex = from.startIndex
        var linkEndFound = false
        var linkEndIndex = from.endIndex
        while index < from.endIndex {
            let char = from[index]
            if !linkStartFound && (StringUtils.strEqual(str: from, index: index, str2: "http://") || StringUtils.strEqual(str: from, index: index, str2: "https://")) {
                linkStartFound = true
                linkStartIndex = index
            } else if linkStartFound && !linkEndFound && (char.isWhitespace || char == "<") {
                linkEndFound = true
                if priorChar == "." {
                    linkEndIndex = priorIndex
                } else {
                    linkEndIndex = index
                }
            } else if !linkStartFound {
                out.append(char)
            }
            priorChar = char
            priorIndex = index
            index = from.index(after: index)
        }
        if linkStartFound {
            if !linkEndFound && priorChar == "." {
                linkEndIndex = priorIndex
            }
            let url = String(from[linkStartIndex..<linkEndIndex])
            var postURL = ""
            if linkEndIndex < from.endIndex {
                postURL = String(from[linkEndIndex..<from.endIndex])
            }
            out.append("<a href=\"" + url + "\" target=\"ref\">")
            out.append(url)
            out.append("</a>")
            out.append(postURL)
        }
        return out
    }
    
    /// Remove punctuation from the string, replacing with spaces,
    /// but don't allow consecutive or trailing spaces.
    ///
    /// - Parameter from: The string to be purified.
    /// - Returns: The purified string.
    ///
    public static func purifyPunctuation(_ from: String, squeeze: Bool = false) -> String {
        
        var out = ""
        var pendingSpaces = 0
        for char in from {
            if char.isWhitespace || char.isPunctuation || char == "\"" {
                pendingSpaces += 1
            } else {
                if pendingSpaces > 0 {
                    if !squeeze {
                        out.append(" ")
                    }
                    pendingSpaces = 0
                }
                out.append(char)
            }
        }
        return out
    }
    
    public static func truncateOrPad(_ from: String, toLength: Int, keepOnRight: Bool = false) -> String {
        if toLength == from.count {
            return from
        } else if toLength < from.count {
            if keepOnRight {
                return String(from.suffix(toLength))
            } else {
                return String(from.prefix(toLength))
            }
        } else {
            var zeroCount = toLength - from.count
            var zeros = ""
            while zeroCount > 0 {
                zeros.append("0")
                zeroCount -= 1
            }
            return zeros + from
        }
    }
    
    /// Change the way words are  identified in the output string.
    /// - Parameters:
    ///   - from: The input String.
    ///   - caseMods: Three characters indicating where upper- and lower-case letters should be used. Each position
    ///               should be set to a 'u' or an 'l'.  The first position indicates the desired case for the first character
    ///               in the string; the second position indicates the desired case for the first character in each word;
    ///               the third position inidcates the desired case for the remaining letters. 
    ///   - delimiter: The desired delimiter to be placed between words.
    public static func wordDemarcation(_ from: String, caseMods: [String], delimiter: String) -> String {
        var out = ""
        var demarcationPending = false
        var lastChar: Character = " "
        var positionInVariable = 0
        var positionInWord = 0
        for char in from {
            if char.isWhitespace || char.isPunctuation {
                demarcationPending = true
            } else {
                
                if positionInVariable > 0 && char.isUppercase && !lastChar.isUppercase {
                    demarcationPending = true
                }
                
                if demarcationPending {
                    out.append(delimiter)
                    positionInWord = 0
                    demarcationPending = false
                }
                
                var caseModsIndex = 2
                if positionInVariable == 0 {
                    caseModsIndex = 0
                } else if positionInWord == 0 {
                    caseModsIndex = 1
                }
                
                if caseMods[caseModsIndex] == "u" {
                    out.append(char.uppercased())
                } else if caseMods[caseModsIndex] == "l" {
                    out.append(char.lowercased())
                } else {
                    out.append(char)
                }
                
                lastChar = char
                positionInWord += 1
                positionInVariable += 1
                
            }
        }
        return out
    }
    
    public static func underscoresForSpaces(_ from: String) -> String {
        var out = ""
        var pendingSpaces = 0
        for char in from {
            if char.isWhitespace || char == "_" {
                pendingSpaces += 1
            } else {
                if pendingSpaces > 0 {
                    if out.count > 0 {
                        out.append("_")
                    }
                    pendingSpaces = 0
                }
                out.append(char)
            }
        }
        return out
    }
    
    /// Turn this string into a likely WikiMedia page name.
    public static func wikiMediaPage(_ from: String) -> String {
        var out = ""
        var pendingSpaces = 0
        for char in from {
            if char.isWhitespace || char == "_" {
                pendingSpaces += 1
            } else {
                if pendingSpaces > 0 {
                    if out.count > 0 {
                        out.append("_")
                    }
                    pendingSpaces = 0
                }
                if char == "," {
                    out.append("%2C")
                } else {
                    out.append(char)
                }
            }
        }
        return out
    }
    
    /// See if the next few characters in the first string are equal to
    /// the entire contents of the second string.
    ///
    /// - Parameters:
    ///   - str: The string being indexed.
    ///   - index: An index into the first string.
    ///   - str2: The second string.
    /// - Returns: True if equal, false otherwise.
    static func strEqual(str: String, index: String.Index, str2: String) -> Bool {
        guard str[index] == str2[str2.startIndex] else { return false }
        var strIndex = str.index(index, offsetBy: 1)
        var str2Index = str2.index(str2.startIndex, offsetBy: 1)
        while strIndex < str.endIndex && str2Index < str2.endIndex {
            if str[strIndex] != str2[str2Index] {
                return false
            }
            strIndex = str.index(strIndex, offsetBy: 1)
            str2Index = str2.index(str2Index, offsetBy: 1)
        }
        if str2Index < str2.endIndex {
            return false
        } else {
            return true
        }
    }
    
    /// Extract the beginning of a long piece of text, trying to end with
    /// a complete sentence. 
    public static func summarize(_ str: String, max: Int = 250) -> String {
        
        var end = 0
        if str.count > max {
            end = max
        } else {
            end = str.count
        }
        
        var sentenceCount = 0
        var lineCharsCount = 0
        var lastChar: Character = " "
        var index = str.startIndex
        var lastSentenceEnd = str.startIndex
        var lastSpace = str.startIndex
        var i = 0
        
        var blank = true
        var spaceCount = 0
        
        while i < end {
            
            // Get the next character following the current one.
            let currChar = str[index]
            var nextChar: Character = " "
            if i < (end - 1) {
                let nextIndex = str.index(after: index)
                nextChar = str[nextIndex]
            }
            
            if currChar.isNewline {
                lineCharsCount = 0
            } else if lineCharsCount > 0 || (currChar != "#" && !currChar.isWhitespace) {
                lineCharsCount += 1
            }
            
            if (currChar == "<" && !nextChar.isWhitespace) {
                if spaceCount == 0 {
                    lastSpace = index
                }
                i = end
            } else if ((currChar == "." || currChar == ";") && nextChar == " " && (!lastChar.isWholeNumber || lineCharsCount > 5)) {
                lastSentenceEnd = str.index(after: index)
                sentenceCount += 1
                spaceCount = 0
            } else if currChar.isWhitespace {
                spaceCount += 1
                lastSpace = index
            } else {
                blank = false
                spaceCount = 0
            }
            
            lastChar = currChar
            index = str.index(after: index)
            i += 1
        }
        
        if blank {
            return ""
        } else if sentenceCount > 0 {
            return String(str[str.startIndex..<lastSentenceEnd])
        } else {
            return String(str[str.startIndex..<lastSpace]) + "..."
        }
    }
    
    // Take a String and make a readable file name (without path or extension) from it
    public static func toReadableFilename(_ from: String) -> String {
        var str = from
        if str.hasPrefix("http://") {
            str.removeFirst(7)
        } else if str.hasPrefix("https://") {
            str.removeFirst(8)
        }
        var fileName = ""
        var i = 0
        var nextChar: Character = " "
        var lastOut: Character = " "
        var lastIn: Character = " "
        for c in str {
            
            if str.count > (i + 1) {
                nextChar = StringUtils.charAt(index: i + 1, str: str)
            } else {
                nextChar = " "
            }
            
            if fileName.count > 0 {
                lastOut = StringUtils.charAt(index: fileName.count - 1, str: fileName)
            }
            
            if c.isLetter {
                fileName.append(c)
            } else if StringUtils.isDigit(c) {
                fileName.append(c)
            } else if StringUtils.isWhitespace(c) && lastOut == " " {
                // Avoid consecutive spaces
            } else if c == ":" && lastIn == ":" {
                // Avoid consecutive colons
            } else if StringUtils.isWhitespace(c) {
                fileName.append(" ")
            } else if c == "_" || c == "-" {
                fileName.append(c)
            } else if c == "\\" || c == "(" || c == ")" || c == "[" || c == "]" || c == "{" || c == "}" || c == "?" {
                // Let's just drop some punctuation
            } else if c == "/" {
                if lastOut != " " {
                    fileName.append(" ")
                }
            } else if c == "'" {
                fileName.append(c)
            } else if c == "." && (fileName.hasSuffix("vs") || fileName.hasSuffix("VS")) {
                // Drop the period on "vs."
            } else if c == "&" {
                if lastOut != " " {
                    fileName.append(" ")
                }
                fileName.append("and ")
            } else if fileName.count > 0 {
                if nextChar == " " && lastOut != " " {
                    fileName.append(" ")
                }
                fileName.append("-")
            }
            lastIn = c
            i += 1
        }
        
        if fileName.count > 0 {
            if fileName.hasSuffix("-") {
                fileName.removeLast()
            }
            if fileName.hasSuffix(" ") {
                fileName.removeLast()
            }
            if fileName.hasSuffix(".com") || fileName.hasSuffix(".COM") {
                fileName.removeLast(4)
            }
        }
    
        return fileName
    }
    
    /// Increment a passed digit or letter to its next value.
    ///
    /// If the passed character is at the end of its range, then the first
    /// character in the range will be returned. For example, incrementing '9'
    /// returns zero, incrementing 'z' returns 'a', incrementing 'Z' returns 'A'
    public static func increment(_ toInc: Character) -> Character {
        var found = false
        var nextChar : Character = toInc
        if isDigit(toInc) {
            nextChar = "0"
            for c in "0123456789" {
                if found {
                    nextChar = c
                    break
                } else if c == toInc {
                    found = true
                }
            }
        } else if isLower(toInc) {
            nextChar = "a"
            for c in "abcdefghijklmnopqrstuvwxyz" {
                if found {
                    nextChar = c
                    break
                } else if c == toInc {
                    found = true
                }
            }
        } else if isAlpha(toInc) {
            nextChar = "A"
            for c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" {
                if found {
                    nextChar = c
                    break
                } else if c == toInc {
                    found = true
                }
            }
        }
        return nextChar
    }
    
    /// Change the leading character to lower case
    public static func toLowerFirstChar(_ str: String) -> String {
        return str.prefix(1).lowercased() + str.dropFirst()
    }
    
    /// Change the leading character to upper case
    public static func toUpperFirstChar(_ str: String) -> String {
        return str.prefix(1).uppercased() + str.dropFirst()
    }
    
    /// Is this character a digit in the range 0 - 9?
    public static func isDigit(_ c : Character) -> Bool {
        return "0"..."9" ~= c
    }
    
    /// Is this character a normal alphabetic character?
    public static func isAlpha(_ c : Character) -> Bool {
        return ("a"..."z" ~= c) || ("A"..."Z" ~= c)
    }
    
    /// Is this character a lower case letter?
    public static func isLower(_ c : Character) -> Bool {
        return "a"..."z" ~= c
    }
    
    /// Is this character some form of white space?
    public static func isWhitespace(_ c : Character) -> Bool {
        return c == " " || c == "\t" || c == "\n" || c == "\r"
    }
    
    /// Remove white spaces from front and back of string
    public static func trim(_ inStr: String) -> String {
        return inStr.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Remove white space and new line characters:
    /// * Remove altogether from beginning and end of line;
    /// * Replace with spaces within the line;
    /// * Remove extra (two or more consecutive) spaces
    public static func cleanAndTrim(_ inStr: String) -> String {
        var outStr = ""
        var pendingSpace = false
        for c in inStr {
            if c.isWhitespace || c.isNewline  {
                if outStr.count > 0 {
                    pendingSpace = true
                }
            } else {
                if pendingSpace {
                    outStr.append(" ")
                    pendingSpace = false
                }
                outStr.append(c)
            }
        }
        return outStr
    }
    
    /// Remove white space and Markdown heading characters from front and back of string
    public static func trimHeading(_ inStr: String) -> String {
        guard inStr.count > 0 else { return "" }
        var headingFound = false
        var start = inStr.startIndex
        var end = inStr.endIndex
        var index = inStr.startIndex
        for c in inStr {
            if c.isWhitespace || c == "#" {
                // Skip spaces and heading characters
            } else {
                if !headingFound {
                    headingFound = true
                    start = inStr.index(index, offsetBy: 0)
                }
                end = inStr.index(index, offsetBy: 0)
            }
            index = inStr.index(index, offsetBy: 1)
        }
        if headingFound {
            return String(inStr[start...end])
        } else {
            return ""
        }
    }
    
    /// Return the character located at the given position within the passed string
    public static func charAt (index: Int, str: String) -> Character {
        let s = str.index(str.startIndex, offsetBy: index)
        return charAt(index: s, str: str)
    }
    
    /// Return the character located at the given position within the passed string
    public static func charAt (index : String.Index, str: String) -> Character {
        let substr = str[index...index]
        var char : Character = " "
        for c in substr {
            char = c
        }
        return char
    }
    
    /// Replace a character at the given index position
    public static func replaceChar(i : Int, str : inout String, newChar : Character) {
        let index = str.index(str.startIndex, offsetBy: i)
        let indexNext = str.index(index, offsetBy: 1)
        let range = index..<indexNext
        let newString = String(newChar)
        str.replaceSubrange(range, with: newString)
    }
    
    static func contains(_ target : String, within: String) -> Bool {
        return within.range(of: target) != nil
    }
    
    /// Take the passed string and turn it into a Wikipedia link.
    public static func wikify(_ str: String) -> String {
        var wikified = "https://en.wikipedia.org/wiki/"
        var workStr = str
        if str.contains(", ") {
            let lastAndFirst = str.components(separatedBy: ", ")
            if lastAndFirst.count == 2 {
                workStr = lastAndFirst[1]
                workStr.append(" ")
                workStr.append(lastAndFirst[0])
            }
        }
        for char in workStr {
            if char == " " {
                wikified.append("_")
            } else {
                wikified.append(char)
            }
        }
        return wikified
    }
    
    /// Search for the given phrase in the given HTML and surround occurrences of the search phrase
    /// with span tags calling out the specified HTML class and/or style.
    public static func highlightPhraseInHTML(phrase: String,
                                             html: String,
                                             style: String? = nil,
                                             klass: String? = nil) -> String {
        
        guard !phrase.isEmpty else { return html }
        
        var spanAttrs = ""
        if klass != nil && klass!.count > 0 {
            spanAttrs = "class=\"\(klass!)\""
        }
        if style != nil && style!.count > 0 {
            if spanAttrs.count > 0 {
                spanAttrs.append(", ")
            }
            spanAttrs.append("style=\"\(style!)\"")
        }
        let startSpan = "<span \(spanAttrs)>"
        let endSpan = "</span>"
        let inc = startSpan.count + endSpan.count
        
        var done = false
        var mod = html
        var remaining = mod.startIndex..<mod.endIndex
        if let bodyTagRange = mod.range(of: "<body>", options: .caseInsensitive) {
            remaining = bodyTagRange.upperBound..<mod.endIndex
        }
        while !done {
            if let range = mod.range(of: phrase, options: .caseInsensitive, range: remaining) {
                var charIndex = range.lowerBound
                var tagChar: Character = " "
                while charIndex >= mod.startIndex && tagChar == " " {
                    let char = mod[charIndex]
                    if char == ">" || char == "<" {
                        tagChar = char
                    }
                    charIndex = mod.index(before: charIndex)
                }
                var bump = 0
                if tagChar != "<" {
                    let original = mod[range]
                    let replacement = startSpan + original + endSpan
                    mod.replaceSubrange(range, with: replacement)
                    bump = inc
                }
                let startRemaining = mod.index(range.upperBound, offsetBy: bump)
                remaining = startRemaining..<mod.endIndex
            } else {
                done = true
            }
        }
        return mod
    }
    
    public static func display(_ value: String,
                                label: String? = nil,
                                blankBefore: Bool = false,
                                header: String? = nil,
                                sepLine: Bool = false,
                                indentLevels: Int = 0) {
        
        if blankBefore {
            print(" ")
        }
        var indent = String(repeating: "  ", count: indentLevels)
        if header != nil && !header!.isEmpty && sepLine {
            print(indent + header!)
            indent.append("  ")
        }
        
        var bullet = ""
        switch indentLevels {
        case 0:
            bullet = ""
        case 1:
            bullet = "* "
        case 2:
            bullet = "- "
        case 3:
            bullet = "+ "
        default:
            bullet = "+ "
        }
        
        var line = indent + bullet
        if header != nil && !header!.isEmpty && !sepLine {
            line.append(header! + " | ")
        }
        if label != nil && !label!.isEmpty {
            line.append(label! + ": ")
        }
        line.append(value)
        print(line)
    }
    
    /// Remove leading and trailing paragraph tags.
    public static func removeParagraphTags(_ html: String) -> String {
        guard html.count > 0 else { return html }
        var start = html.startIndex
        var end = html.endIndex
        if html.hasPrefix("<p>") || html.hasPrefix("<P>") {
            start = html.index(html.startIndex, offsetBy: 3)
        }
        var j = html.index(before: html.endIndex)
        while (j > start &&
            (StringUtils.charAt(index: j, str: html).isWhitespace ||
                StringUtils.charAt(index: j, str: html).isNewline)) {
                    j = html.index(before: j)
        }
        let i = html.index(j, offsetBy: -3)
        if i >= start {
            let possibleEndPara = html[i...j]
            if possibleEndPara == "</p>" || possibleEndPara == "</P>" {
                end = i
            }
        }
        if html.hasSuffix("</p>") || html.hasSuffix("</P>") {
            end = html.index(html.endIndex, offsetBy: -4)
        }
        return String(html[start..<end])
    }
    
    /// Split a string into a path and an item name, with the last forward slash acting
    /// as a separator between the two. If no slash is found, then the returned
    /// path will be empty.
    /// - Parameter str: A string possibly containing a slash.
    /// - Returns: A path (possibly empty) and an item name.
    public static func splitPath(_ str: String, dropPathNoise: Bool = true) -> (String, String) {
        var path = ""
        var item = ""
        var slashFound = false
        var index = str.endIndex
        while index > str.startIndex {
            index = str.index(before: index)
            if str[index] == "/" {
                slashFound = true
                break
            }
        }
        
        // No slash found.
        if !slashFound {
            return ("", str)
        }
        
        let itemStart = str.index(after: index)
        
        // Slash found at end of string -- just drop it.
        if itemStart >= str.endIndex {
            return ("", String(str[str.startIndex..<index]))
        }
        
        var startPath = str.startIndex
        if dropPathNoise {
            while startPath < index && (str[startPath] == "." || str[startPath] == "/") {
                startPath = str.index(after: startPath)
            }
        }
        path = String(str[startPath..<index])
        item = String(str[itemStart..<str.endIndex])
        return (path, item)
    }
    
}

/// See if the next few characters in the first string are equal to
/// the entire contents of the second string.
///
/// - Parameters:
///   - str: The string being indexed.
///   - index: An index into the first string.
///   - str2: The second string.
/// - Returns: True if equal, false otherwise.
extension String {
    
    /// Determines whether the passed string is equal to the
    /// equivalent portion of this string, as indexed by the
    /// given index.
    ///
    /// - Parameters:
    ///   - index: An index pointing to a location within the string.
    ///   - str2: A second string to compare to a portion of this one.
    /// - Returns: True if the next several characters of this string match
    ///            the characters of the passed string; false if characters
    ///            don't match, or if the matching takes us beyond the end
    ///            of this string.
    ///
    public func indexedEquals(index: String.Index, str2: String) -> Bool {
        guard self[index] == str2[str2.startIndex] else { return false }
        var strIndex = self.index(index, offsetBy: 1)
        var str2Index = str2.index(str2.startIndex, offsetBy: 1)
        while strIndex < self.endIndex && str2Index < str2.endIndex {
            if self[strIndex] != str2[str2Index] {
                return false
            }
            strIndex = self.index(strIndex, offsetBy: 1)
            str2Index = str2.index(str2Index, offsetBy: 1)
        }
        if str2Index < str2.endIndex {
            return false
        } else {
            return true
        }
    }
    
    /// Return the character at the given offset from the given index, or space.
    ///
    /// - Parameters:
    ///   - index: An index pointing to a position within the string.
    ///   - offsetBy: An offset from that index.
    /// - Returns: The character at the offset location, or a space, if the
    ///            offset plus the index takes us beyond the end of the string.
    ///
    public func charAtOffset(index: String.Index, offsetBy: Int) -> Character {
        var ix = index
        var offset = offsetBy
        var char: Character = " "
        while ix < self.endIndex && offset > 0 {
            ix = self.index(after: ix)
            offset -= 1
        }
        if offset == 0 && ix < self.endIndex {
            char = self[ix]
        }
        
        return char
    }

}
