//
//  CleanString.swift
//  NotenikUtils
//
//  Created by Herb Bowie on 3/11/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A string that has been cleansed in one of several ways, depending on its format. This is meant to be used for
/// relatively short runs of text, as might be found in a title or subject line.
/// - trimmed: leading and trailing white space removed, with no other modifications
/// - html: Some minimal Markdown formatting converted to HTML
/// - plain: cleansed of HTML and Markdown codes
/// - common: A "lowest common denominator" representation meant to be used as an identifying key
/// - macFileName: suitable for saving a file to disk
/// - webFileName: suitable for saving a file to a web server

public class CleanString: CustomStringConvertible {
    
    var format: CleanFormat = .trimmed
    
    private var _str = ""
    
    public var str: String {
        return _str
    }
    
    var pendingSpaces = 0
    
    var pendingDoubleQuote = false
    
    var startingTagCount = 0
    var charsWithinTags = 0
    var element = ""
    
    var closingTag = ""
    var codePending: Bool {
        return closingTag == "</code>"
    }
    
    /// Simple init.
    public init(format: CleanFormat) {
        self.format = format
    }
    
    public var count: Int {
        return _str.count
    }
    
    /// Conforming to CustomStringConvertible.
    public var description: String {
        return _str
    }
    
    public var hasData: Bool {
        return !_str.isEmpty
    }
    
    public var isEmpty: Bool {
        return _str.isEmpty
    }
    
    public func set(_ str: String) {
        var char: Character = " "
        var lastChar: Character = " "
        var nextChar: Character = " "
        
        var primed = false
        for c in str {
            lastChar = char
            char = nextChar
            nextChar = c
            if primed {
                append(char, nextChar: nextChar, lastChar: lastChar)
            } else {
                primed = true
            }
        }
        if primed {
            lastChar = char
            char = nextChar
            nextChar = " "
            append(char, nextChar: nextChar, lastChar: lastChar)
        }
    }
    
    /// Append another character, omitting excessive spacing.
    public func append(_ char: Character, nextChar: Character, lastChar: Character) {
        
        // Handle trimming logic
        if char.isWhitespace || char.isNewline {
            if _str.isEmpty {
                return
            }
            if format == .trimmed {
                pendingSpaces += 1
                return
            }
        } else if format == .trimmed {
            drainPendingSpaces()
            _str.append(char)
            return
        }
        
        // Handle backticks indicating code spans
        if char == "`" {
            handleBacktick()
            return
        }

        // Handle special characters within code spans
        if codePending {
            if char.isWhitespace {
                appendSpace()
                return
            } else if char == "<" {
                appendLessThan()
                return
            } else if char == ">" {
                appendGreaterThan()
                return
            }
        }
        
        // Handle beginning of an HTML tag
        if char == "<" && (nextChar.isLetter || nextChar == "/") {
            if startingTagCount == 0 {
                charsWithinTags = 0
                element = ""
            }
            startingTagCount += 1
            if format == .html {
                _str.append("<")
            }
            return
        }
        
        // Handle end of an HTML tag
        if startingTagCount > 0 && char == ">" {
            startingTagCount -= 1
            if startingTagCount == 0 {
                if element.starts(with: "br") {
                    if format == .html {
                        _str.removeLast(charsWithinTags + 1)
                        _str.append("<br />")
                    } else {
                        ensurePendingSpace()
                    }
                    return
                }
            }
            if format == .html {
                _str.append(">")
            }
            return
        }
    
        // Handle stuff within an HTML tag
        if startingTagCount > 0 {
            element.append(char)
            charsWithinTags += 1
            if format == .html {
                _str.append(char)
            }
            return
        }
        
        // Handle remaining spaces
        if char.isWhitespace || char.isNewline {
            if format == .common {
                if _str == "a" || _str == "an" || _str == "the" {
                    _str = ""
                }
            } else {
                pendingSpaces += 1
            }
            return
        }
        
        // Handle Markdown emphasis
        if char == "*"
            || (char == "_" && lastChar.isWhitespace)
            || (char == "_" && lastChar == "_")
            || (char == "_" && !closingTag.isEmpty) {
            handleMarkdownEmphasis(char, lastChar: lastChar, nextChar: nextChar)
            return
        }
        
        // Non-blank character — write out any needed spaces
        drainPendingSpaces()
        
        let charLowered: Character = char.lowercased().first!
        
        // Handle letters and digits
        if char.isLetter || char.isNumber  {
            appendWordChar(char, lowered: charLowered)
            return
        }
        
        // Now handle remaining punctuation
        switch char {
        case "<":
            appendLessThan()
        case ">":
            appendGreaterThan()
        case "=":
            if format == .webFileName {
                _str.append("equals")
            } else {
                _str.append(char)
            }
        case "+":
            if format == .webFileName {
                _str.append("plus")
            } else {
                _str.append(char)
            }
        case "-":
            if format != .common {
                appendNonRepeatingDash()
            }
        case ":", "/":
            appendColonOrSlash(char, lastChar: lastChar)
        case "&":
            if nextChar.isWhitespace {
                appendAmpersand(char, lastChar: lastChar, nextChar: nextChar)
            } else {
                if format == .html {
                    _str.append(char)
                }
            }
        case "\'":
            appendSingleQuote(char, lastChar: lastChar, nextChar: nextChar)
        case "\"":
            appendDoubleQuote(char, lastChar: lastChar, nextChar: nextChar)
        default:
            appendMiscPunctuation(char)
        }
    }
    
    func handleBacktick() {
        drainPendingSpaces()
        if !closingTag.isEmpty {
            if format == .html {
                _str.append(closingTag)
            }
            closingTag = ""
        } else {
            if format == .html {
                _str.append("<code>")
            }
            closingTag = "</code>"
        }
    }
    
    func handleMarkdownEmphasis(_ char: Character, lastChar: Character, nextChar: Character) {
        guard char != lastChar else { return }
        drainPendingSpaces()
        if !closingTag.isEmpty {
            if format == .html {
                _str.append(closingTag)
            }
            closingTag = ""
        } else {
            if nextChar == char {
                if format == .html {
                    _str.append("<strong>")
                }
                closingTag = "</strong>"
            } else {
                if format == .html {
                    _str.append("<em>")
                }
                closingTag = "</em>"
            }
        }
    }
    
    func ensurePendingSpace() {
        if pendingSpaces == 0 {
            pendingSpaces = 1
        }
    }
    
    // Handle letters and digits
    func appendWordChar(_ char: Character, lowered: Character) {
        switch format {
        case .trimmed:
            _str.append(char)
        case .plain:
            _str.append(char)
        case .common:
            _str.append(lowered)
        case .macFileName:
            _str.append(char)
        case .webFileName:
            _str.append(lowered)
        case .html:
            _str.append(char)
        }
    }
    
    func drainPendingSpaces() {
        guard pendingSpaces > 0 else { return }
        switch format {
        case .trimmed:
            while pendingSpaces > 0 {
                _str.append(" ")
                pendingSpaces -= 1
            }
        case .plain:
            _str.append(" ")
        case .common:
            break
        case .macFileName:
            _str.append(" ")
        case .webFileName:
            appendNonRepeatingDash()
        case .html:
            _str.append(" ")
        }
        pendingSpaces = 0
    }
    
    func appendSpace() {
        switch format {
        case .trimmed:
            _str.append(" ")
        case .plain:
            _str.append(" ")
        case .common:
            break
        case .macFileName:
            _str.append(" ")
        case .webFileName:
            _str.append("_")
        case .html:
            _str.append(" ")
        }
    }
    
    func appendLessThan() {
        switch format {
        case .trimmed:
            _str.append("<")
        case .plain:
            _str.append("<")
        case .common:
            _str.append("<")
        case .macFileName:
            _str.append("<")
        case .webFileName:
            _str.append("less-than")
        case .html:
            _str.append("&lt;")
        }
    }
    
    func appendGreaterThan() {
        switch format {
        case .trimmed:
            _str.append(">")
        case .plain:
            _str.append(">")
        case .common:
            _str.append(">")
        case .macFileName:
            _str.append(">")
        case .webFileName:
            _str.append("greater-than")
        case .html:
            _str.append("&gt;")
        }
    }
    
    func appendColonOrSlash(_ char: Character, lastChar: Character) {
        switch format {
        case .trimmed:
            _str.append(char)
        case .plain:
            _str.append(char)
        case .common:
            break
        case .macFileName:
            if lastChar.isWhitespace {
                _str.append("-")
            } else {
                _str.append(" ")
            }
        case .webFileName:
            appendNonRepeatingDash()
        case .html:
            _str.append(char)
        }
    }
    
    func appendAmpersand(_ char: Character, lastChar: Character, nextChar: Character) {
        switch format {
        case .trimmed:
            _str.append(char)
        case .plain:
            _str.append(char)
        case .common:
            break
        case .macFileName:
            _str.append(char)
        case .webFileName:
            _str.append("and")
        case .html:
            _str.append("&#38;")
        }
    }
    
    func appendSingleQuote(_ char: Character, lastChar: Character, nextChar: Character) {
        let trueApostrophe = !nextChar.isWhitespace && !nextChar.isPunctuation && !lastChar.isWhitespace && !lastChar.isPunctuation
        switch format {
        case .trimmed:
            _str.append(char)
        case .plain:
            _str.append(char)
        case .common:
            break
        case .macFileName:
            _str.append(char)
        case .webFileName:
            break
        case .html:
            if trueApostrophe {
                _str.append("&#8217;")
            } else {
                _str.append(char)
            }
        }
    }
    
    func appendDoubleQuote(_ char: Character, lastChar: Character, nextChar: Character) {
        
        var leftQuote = false
        var rightQuote = false
        if lastChar.isWhitespace && !nextChar.isPunctuation && !nextChar.isWhitespace {
            leftQuote = true
        } else if !lastChar.isWhitespace {
            rightQuote = true
        }
        
        switch format {
        case .trimmed:
            _str.append(char)
        case .plain:
            _str.append(char)
        case .common:
            break
        case .macFileName:
            _str.append(char)
        case .webFileName:
            break
        case .html:
            if leftQuote {
                _str.append("&#8220;")
            } else if rightQuote {
                _str.append("&#8221;")
            } else {
                _str.append(char)
            }
        }
    }
    
    func appendMiscPunctuation(_ char: Character) {
        switch format {
        case .trimmed:
            _str.append(char)
        case .plain:
            _str.append(char)
        case .common:
            break
        case .macFileName:
            _str.append(char)
        case .webFileName:
            appendNonRepeatingDash()
        case .html:
            _str.append(char)
        }
    }
    
    func appendNonRepeatingDash() {
        guard _str.last != "-" else { return }
        _str.append("-")
    }
    
}
