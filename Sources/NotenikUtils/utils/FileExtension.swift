//
//  FileExtension.swift
//  NotenikUtils
//
//  Created by Herb Bowie on 8/30/22.
//
//  Copyright © 2022 - 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A useful class for handling file extensions. 
public class FileExtension: CustomStringConvertible, Comparable, Equatable {
    
    let dot: Character = "."
    let dotStr = "."
    
    var ext = ""
    var extLower = ""
    
    /// Initialize from the given file extension.
    /// - Parameter ext: A file extension, which may or may not begin with a dot (aka period). 
    public init(_ ext: String) {
        if ext.starts(with: dotStr) {
            self.ext = String(ext.dropFirst(1))
        } else {
            self.ext = ext
        }
        extLower = self.ext.lowercased()
    }
    
    /// Initialize from a file name, extracting the extension from the end of the provided string.
    /// - Parameter fileName: Filename or path.
    public init(fileName: String) {
        var workExt = ""
        var dotFound = false
        var ix = fileName.endIndex
        while !dotFound && ix > fileName.startIndex {
            ix = fileName.index(before: ix)
            let c = fileName[ix]
            if c == dot {
                dotFound = true
            } else {
                workExt.insert(c, at: workExt.startIndex)
            }
        }
        if dotFound {
            ext = workExt
            extLower = workExt.lowercased()
        }
    }
    
    public var isEmpty: Bool {
        return ext.isEmpty
    }
    
    public var description: String {
        return withDot
    }
    
    public var originalExtWithDot: String {
        return dotStr + ext
    }
    
    public var originalExtSansDot: String {
        return ext
    }
    
    public var lowercaseExtWithDot: String {
        return dotStr + extLower
    }
    
    public var lowercaseExtSansDot: String {
        return extLower
    }
    
    public var withDot: String {
        return dotStr + extLower
    }
    
    public var withoutDot: String {
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
    
    public static func < (lhs: FileExtension, rhs: FileExtension) -> Bool {
        return lhs.extLower < rhs.extLower
    }
    
    public static func == (lhs: FileExtension, rhs: FileExtension) -> Bool {
        return lhs.extLower == rhs.extLower
    }
}
