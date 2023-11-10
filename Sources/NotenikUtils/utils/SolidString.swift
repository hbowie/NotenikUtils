//
//  SolidString.swift
//  NotenikUtils
//
//  Created by Herb Bowie on 1/27/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A class representing a string built by appending characters, but omitting
/// leading and trailing spaces, and multiple internal spaces.
public class SolidString: CustomStringConvertible {
    
    public var str = ""
    
    var pendingSpaces = 0
    
    /// Simple init.
    public init() {
        
    }
    
    /// Init with another solid string. 
    public init(_ str2: SolidString) {
        self.str = str2.str
    }
    
    /// Init with any string.
    public init(_ basicStr: String) {
        for char in basicStr {
            append(char)
        }
    }
    
    /// Conforming to CustomStringConvertible.
    public var description: String {
        return str
    }
    
    public var hasData: Bool {
        return !str.isEmpty
    }
    
    public var isEmpty: Bool {
        return str.isEmpty
    }
    
    /// Return the lowest common denominator form of the string.
    public var common: String {
        return StringUtils.toCommon(str)
    }
    
    /// Make the size of the string easily accessible.
    public var count: Int {
        return str.count
    }
    
    /// Append the characters within the string.
    public func append(_ chars: String) {
        for char in chars {
            append(char)
        }
    }
    
    /// Append another character, omitting excessive spacing. 
    public func append(_ char: Character) {
        if char.isWhitespace {
            if str.count == 0 {
                // Discard leading spaces
            } else {
                pendingSpaces += 1
            }
        } else {
            if pendingSpaces > 0 {
                str.append(" ")
                pendingSpaces = 0
            }
            str.append(char)
        }
    }
    
}
