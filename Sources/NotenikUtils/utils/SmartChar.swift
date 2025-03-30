//
//  SmartChar.swift
//  NotenikUtils
//
//  Created by Herb Bowie on 3/25/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//
import Foundation

// A Character substitute with some special smarts, to improve efficiency.
public class SmartChar {
    
    var c: Character = " "
    
    /// Is this a letter or a digit -- a character that provides some meaning?
    var isMeaningChar: Bool = false
    
    /// Is this some form of whitespace?
    var isWhitespace: Bool = true
    
    /// Is this a colon?
    var isColon: Bool = false
    
    /// Is this a dash or an underscore?
    var isWordSep: Bool = false
    
    /// Is this some ofther form of punctuation that is likely not needed to preserve the
    /// basic meaning of the string.?
    var isFancyPunctuation: Bool = false
    
    /// Initialize with a space.
    public init() {
        
    }
    
    
    /// Initialize with the given character.
    /// - Parameter c: The character to be stored and evaluated.
    public init(_ c: Character) {
        self.c = c
        getSmart()
    }
    
    /// Set to a new character -- to be stored and evaluated.
    /// - Parameter c: The new character.
    public func set(_ c: Character) {
        self.c = c
        getSmart()
    }
    
    
    /// Set this character to a space.
    public func setBlank() {
        self.c = " "
        getSmart()
    }
    
    /// Perform interesting evaluations and store the results of the analysis.
    func getSmart() {
        if c.isLetter || c.isNumber {
            isMeaningChar = true
        } else {
            isMeaningChar = false
        }
        self.isWhitespace = c.isWhitespace
        isColon = false
        isWordSep = false
        isFancyPunctuation = false
        switch c {
        case ":":
            isColon = true
        case "-":
            isWordSep = true
        case "_":
            isWordSep = true
        case "\\":
            isFancyPunctuation = true
        case "(":
            isFancyPunctuation = true
        case ")":
            isFancyPunctuation = true
        case "[":
            isFancyPunctuation = true
        case "]":
            isFancyPunctuation = true
        case "{":
            isFancyPunctuation = true
        case "}":
            isFancyPunctuation = true
        case "?":
            isFancyPunctuation = true
        default:
            break
        }
    }
    
    /// Get the basic character back (without smarts).
    /// - Returns: Just the basic character.
    public func getChar() -> Character {
        return c
    }
}
