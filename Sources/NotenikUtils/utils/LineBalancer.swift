//
//  LineBalancer.swift
//  NotenikUtils
//
//  Created by Herb Bowie on 1/11/23.
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A utility to try to evenly balance text across multiple lines of HTML. 
public class LineBalancer {
    
    var maxChars = 45
    var sep = "<br />"
    
    var numberOfLines = 0
    var charsPerLine = 50
    var lineCount = 0
    var charsInStr = 0
    var charsInLine = 0
    var charsInWord = 0
    var strWithBreaks = ""
    var word = ""
    var html = false
    
    public init(maxChars: Int = 50, sep: String = "<br />") {
        self.maxChars = maxChars
        self.sep = sep
    }
    
    public func balance(str: String, prepending: Int = 0) -> String {
        
        guard str.count + prepending > maxChars else { return str }
        
        charsInStr = 0
        html = false
        for char in str {
            if !html && char == "<" {
                html = true
            } else if html && char == ">" {
                html = false
            } else if !html {
                charsInStr += 1
            }
        }
        
        guard charsInStr + prepending > maxChars else { return str }
        
        numberOfLines = ((charsInStr + prepending) / (maxChars - 4)) + 1
        
        charsPerLine = charsInStr / numberOfLines
        let diff = maxChars - charsPerLine
        if diff > 10 {
            charsPerLine += (diff / 2)
        }
        
        lineCount = 1
        charsInLine = prepending
        charsInWord = 0
        strWithBreaks = ""
        word = ""
        html = false
        
        for char in str {
            if !html && char == "<" {
                html = true
                word.append(char)
            } else if html && char == ">" {
                html = false
                word.append(char)
            } else if html {
                word.append(char)
            } else if char.isWhitespace {
                endOfWord(endChar: char)
            } else {
                word.append(char)
                charsInWord += 1
            }
        }
        endOfWord(endChar: nil)
        
        return strWithBreaks
    }
    
    func endOfWord(endChar: Character?) {
        
        guard word.count > 0 else { return }
        
        let lineCharsWithWord = charsInLine + charsInWord

        if lineCharsWithWord > maxChars {
            lineBreak()
        } else if charsInLine > charsPerLine {
            lineBreak()
        } else if lineCount > 1 && lineCharsWithWord > charsPerLine {
            lineBreak()
        } else if lineCharsWithWord > (charsPerLine + 5) {
            lineBreak()
        }
        
        strWithBreaks.append(word)
        charsInLine += charsInWord
        if endChar != nil {
            strWithBreaks.append(endChar!)
            charsInLine += 1
        }
        word = ""
        charsInWord = 0
    }
    
    func lineBreak() {
        strWithBreaks.append(sep)
        lineCount += 1
        charsInLine = 0
    }
    
}
