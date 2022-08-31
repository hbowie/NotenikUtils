//
//  FileExtension.swift
//  NotenikUtils
//
//  Created by Herb Bowie on 8/30/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A useful class for handling file extensions. 
public class FileExtension {
    
    let dot = "."
    
    var ext = ""
    var extLower = ""
    
    public init(_ ext: String) {
        if ext.starts(with: dot) {
            self.ext = String(ext.dropFirst(1))
        } else {
            self.ext = ext
        }
        extLower = self.ext.lowercased()
    }
    
    public var originalExtWithDot: String {
        return dot + ext
    }
    
    public var originalExtSansDot: String {
        return ext
    }
    
    public var lowercaseExtWithDot: String {
        return dot + extLower
    }
    
    public var lowercaseExtSansDot: String {
        return extLower
    }
    
    public var isImage: Bool {
        switch extLower {
        case "gif", "jpg", "jpeg", "png", "svg":
            return true
        default:
            return false
        }
    }
    
    public func display() {
        print("FileExtension.display")
        print("  - ext: \(ext)")
        print("  - ext lower: \(extLower)")
    }
}
