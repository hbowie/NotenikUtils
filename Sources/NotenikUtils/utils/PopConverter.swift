//
//  PopConverter.swift
//  NotenikUtils
//
//  Created by Herb Bowie on 6/22/23.
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Handy utility for popular string conversions.
public class PopConverter {
    
    public static let shared = PopConverter()
    
    let xmlConverter = StringConverter()
    
    let urlOK = NSMutableCharacterSet.alphanumeric()
    
    public static let unreserved = "-._~/:?=&"
    
    private init() {
        xmlConverter.addXML()
        urlOK.addCharacters(in: "-._~/:?=&")
    }
    
    public func toURL(_ str: String) -> String {
        if str.contains("%20") {
            return str
        } else if let encoded = str.addingPercentEncoding(withAllowedCharacters: urlOK as CharacterSet) {
            return toXML(encoded)
        } else {
            return str.replacingOccurrences(of: " ", with: "%20")
        }
    }
    
    public func toXML(_ str: String) -> String {
        if str.contains("&amp;") {
            return str
        } else {
            return xmlConverter.convert(from: str)
        }
    }
}
