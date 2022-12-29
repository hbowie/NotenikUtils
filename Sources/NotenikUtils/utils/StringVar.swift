//
//  StringVar.swift
//  NotenikUtils
//
//  Created by Herb Bowie on 12/29/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Provide String Variations in an efficient manner.
public class StringVar: CustomStringConvertible {
    
    /// The original String
    public var original: String {
        return _original
    }
    var _original = ""
    
    /// The lowercase version of the String, converted once, on demand.
    public var lowered: String {
        if _lowered == nil {
            _lowered = _original.lowercased()
        }
        return _lowered!
    }
    var _lowered: String?
    
    /// The lowest common denominator version of the String, converted once, on demand.
    public var common: String {
        if _common == nil {
            _common = StringUtils.toCommon(_original)
        }
        return _common!
    }
    var _common: String?
    
    /// Use the original version as the description, if requested.
    public var description: String {
        return _original
    }
    
    /// Initialize with the original  String. 
    public init(_ original: String) {
        self._original = original
    }
}
