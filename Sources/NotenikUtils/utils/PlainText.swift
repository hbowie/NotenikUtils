//
//  PlainText.swift
//  NotenikUtils
//
//  Created by Herb Bowie on 12/19/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class PlainText {
    
    public var text = ""
    
    var trailing: TrailingCode = .blankLine
    
    public init() {
        
    }
    
    public func append(_ more: String) {
        text.append(more)
        if text.hasSuffix(" ") || text.hasSuffix("\t") {
            trailing = .space
        } else if text.hasSuffix("\n\n") || text.hasSuffix("\n \n") {
            trailing = .blankLine
        } else if text.hasSuffix("\n") {
            trailing = .newline
        } else {
            trailing = .na
        }
    }
    
    public func ensureBlankLine() {
        switch trailing {
        case .blankLine:
            break
        case .newline:
            text.append("\n")
        case .space, .na:
            text.append("\n\n")
        }
        trailing = .blankLine
    }
    
    public func ensureNewLine() {
        switch trailing {
        case .blankLine, .newline:
            break
        case .space, .na:
            text.append("\n")
            trailing = .newline
        }
    }
    
    public func ensureSpace() {
        switch trailing {
        case .blankLine, .newline, .space:
            break
        case .na:
            text.append(" ")
            trailing = .space
        }
    }
    
    enum TrailingCode {
        case na
        case blankLine
        case newline
        case space
    }
}
