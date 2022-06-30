//
//  HTMLFormatting.swift
//  NotenikUtils
//
//  Created by Herb Bowie on 6/26/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class HTMLFormatting {
    
    public var spacesPerIndent = 2
    public var blockSep: BlockSeparation = .newlineX2
    
    public init() {
        
    }
    
    public enum BlockSeparation {
        case none;
        case newline;
        case newlineX2
    }
}
