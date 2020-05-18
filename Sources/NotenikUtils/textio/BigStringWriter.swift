//
//  BigStringWriter.swift
//  Notenik
//
//  Created by Herb Bowie on 2/11/19.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class BigStringWriter: LineWriter, CustomStringConvertible {
    
    public init() {
        
    }
    
    public var bigString: String = ""
    
    public var count: Int {
        return bigString.count
    }
    
    public var description: String {
        return bigString
    }
    
    /// Get ready to write some lines
    public func open() {
        bigString = ""
    }
    
    /// Write the next line.
    public func writeLine(_ line: String) {
        write(line)
        endLine()
    }
    
    /// Write some more text, without ending the line.
    public func write(_ str: String) {
        bigString.append(str)
    }
    
    /// End the line.
    public func endLine() {
        bigString.append("\n")
    }
    
    /// All done writing
    public func close() {
        
    }
}
