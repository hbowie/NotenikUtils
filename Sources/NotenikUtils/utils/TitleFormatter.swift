//
//  TitleFormatter.swift
//  NotenikUtils
//
//  Created by Herb Bowie on 6/25/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class TitleFormatter {
    
    var value         = ""
    var trimmedCS     = CleanString(format: .trimmed)
    var plainCS       = CleanString(format: .plain)
    var commonCS      = CleanString(format: .common)
    var macFileNameCS = CleanString(format: .macFileName)
    var webFileNameCS = CleanString(format: .webFileName)
    var htmlCS        = CleanString(format: .html)
    
    public var trimmed:     String { return trimmedCS.str }
    public var plain:       String { return plainCS.str   }
    public var common:      String { return commonCS.str  }
    public var macFileName: String { return macFileNameCS.str }
    public var webFileName: String { return webFileNameCS.str }
    public var html:        String { return htmlCS.str }
    
    /// Default initialization
    init() {
        
    }
    
    /// Set an initial value as part of initialization
    convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    /// Is this value empty?
    public var isEmpty: Bool {
        return (value.count == 0 || commonCS.count == 0)
    }
    
    /// Does this value have any data stored in it?
    public var hasData: Bool {
        return (value.count > 0 && commonCS.count > 0)
    }
    
    /// Return a value that can be used as a key for comparison purposes
    public var sortKey: String {
        return commonCS.str
    }
    
    public func getTitle(format: TitleFormat) -> String {
        switch format {
        case .trimmed:      return trimmedCS.str
        case .plain:        return plainCS.str
        case .common:       return commonCS.str
        case .macFileName:  return macFileNameCS.str
        case .webFileName:  return webFileNameCS.str
        case .html:         return htmlCS.str
        }
    }
    
    /// Set a new title value, converting to a lowest common denominator form while we're at it
    public func set(_ value: String) {
        
        self.value = value
        trimmedCS     = CleanString(format: .trimmed)
        plainCS       = CleanString(format: .plain)
        commonCS      = CleanString(format: .common)
        macFileNameCS = CleanString(format: .macFileName)
        webFileNameCS = CleanString(format: .webFileName)
        htmlCS        = CleanString(format: .html)
        
        var char: Character = " "
        var lastChar: Character = " "
        var nextChar: Character = " "
        
        var primed = false
        for c in value {
            lastChar = char
            char = nextChar
            nextChar = c
            if primed {
                processChar(char, lastChar: lastChar, nextChar: nextChar)
            } else {
                primed = true
            }
        }
        if primed {
            lastChar = char
            char = nextChar
            nextChar = " "
            processChar(char, lastChar: lastChar, nextChar: nextChar)
        }
        
        self.value = trimmedCS.str
    }
    
    func processChar(_ char: Character, lastChar: Character, nextChar: Character) {
        trimmedCS.append(char, nextChar: nextChar, lastChar: lastChar)
        plainCS.append(char, nextChar: nextChar, lastChar: lastChar)
        commonCS.append(char, nextChar: nextChar, lastChar: lastChar)
        macFileNameCS.append(char, nextChar: nextChar, lastChar: lastChar)
        webFileNameCS.append(char, nextChar: nextChar, lastChar: lastChar)
        htmlCS.append(char, nextChar: nextChar, lastChar: lastChar)
    }
    
    public func display() {
        
        print("TitleFormatter.display")
        print("  - trimmed value: \(value)")
        print("  - plain:         \(plainCS)")
        print("  - common:        \(commonCS)")
        print("  - mac file name: \(macFileNameCS)")
        print("  - web file name: \(webFileNameCS)")
        print("  - html:          \(htmlCS)")
        
    }
    
}
