//
//  BigStringReader.swift
//  Notenik
//
//  Created by Herb Bowie on 12/9/18.
//  Copyright © 2018 - 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Breaks a string down into characters and lines
public class BigStringReader: LineReader {
    
    /// The string to be read.
    public var bigString:  String = ""
    
    /// An index pointing to the next position in the string to be read.
    public var currIndex:  String.Index
    var nextIndex:  String.Index
    var lastIndex:  String.Index
    
    var currChar:   Character = " "
    public var endOfLine = false
    public var endOfFile = false
    
    var lastChar:   Character = " "
    
    var line       = ""
    var lineLength = 0
    public var lineStartIndex: String.Index
    
    var lineCount : Int = 0
    var charCount : Int = 0
    
    /// Initialize with a blank initial value.
    public init() {
        currIndex = bigString.startIndex
        nextIndex = bigString.startIndex
        lastIndex = bigString.startIndex
        lineStartIndex = bigString.startIndex
    }
    
    /// Initialize with a passed string. 
    public convenience init(_ bigString: String) {
        self.init()
        set(bigString)
    }
    
    /// Attempt to initialize directly from a file URL.
    public init?(fileURL: URL) {
        do {
            bigString = try String(contentsOf: fileURL, encoding: .utf8)
            currIndex = bigString.startIndex
            nextIndex = bigString.startIndex
            lastIndex = bigString.startIndex
            lineStartIndex = bigString.startIndex
        } catch {
            bigString = ""
            currIndex = bigString.startIndex
            nextIndex = bigString.startIndex
            lastIndex = bigString.startIndex
            lineStartIndex = bigString.startIndex
            return nil
        }
    }
    
    /// Set a new value for the string to be read, and position ourselves at the
    /// beginning of the string.
    func set (_ bigString: String) {
        self.bigString = bigString
        initVars()
    }
    
    /// Get ready to read some lines
    public func open() {
        initVars()
    }
    
    func initVars() {
        currIndex = bigString.startIndex
        nextIndex = bigString.startIndex
        lastIndex = bigString.startIndex
        lineStartIndex = bigString.startIndex
        currChar = " "
        lastChar = " "
        lineCount = 0
        charCount = 0
        endOfLine = false
        endOfFile = false
        checkForInvisibleStart()
    }
    
    /// Some UTF-8 files start with a BOM (byte order mark) character. This seems
    /// to be a bit of an anachronism, but may occasionally be encountered. This method
    /// works around such a character, when found. 
    func checkForInvisibleStart() {
        guard nextIndex < bigString.endIndex else { return }
        let firstChar = bigString[nextIndex]
        if firstChar.isASCII { return }
        if firstChar.isWhitespace { return }
        if firstChar.isLetter { return }
        if firstChar.isNumber { return }
        if firstChar.isSymbol { return }
        if firstChar.isPunctuation { return }
        nextIndex = bigString.index(after: nextIndex)
    }
    
    /// Read the next line, returning nil at end of file
    public func readLine() -> String? {
        
        guard !endOfFile else { return nil }
        
        lineCount += 1
        lineStartIndex = nextIndex
        lineLength = 0
        line = ""
        endOfLine = false
        
        while !endOfFile && !endOfLine {
            _ = nextChar()
            if !endOfLine {
                lineLength += 1
            }
        }
        
        if lineLength > 0 {
            line = String(bigString[lineStartIndex...lastIndex])
            return line
        } else if endOfFile {
            return nil
        } else {
            return ""
        }
    }
    
    /// Read the next character, setting a flag at the end of a line.
    public func nextChar() -> Character {
        guard !endOfFile else { return " " }
        lastChar = currChar
        lastIndex = currIndex
        if nextIndex < bigString.endIndex {
            currChar = bigString[nextIndex]
            currIndex = nextIndex
            nextIndex = bigString.index(after: currIndex)
            if endOfLine {
                // If the last character returned indicated the end of a line,
                // then start a new one now.
                lineStartIndex = currIndex
                lineLength = 0
            }
            endOfLine = currChar.isNewline
        } else {
            endOfLine = true
            endOfFile = true
            currChar = " "
        }
        return currChar
    }
    
    /// When using nextChar to retrieve characters, this method can be used to retrieve
    /// the line just completed, after hitting end of line with nextChar.
    public var lastLine: String {
        guard lineStartIndex < bigString.endIndex else { return "" }
        var lineEndIndex = currIndex
        if endOfFile {
            lineEndIndex = bigString.endIndex
        }
        guard lineStartIndex < lineEndIndex else { return "" }
        return String(bigString[lineStartIndex..<lineEndIndex])
    }
    
    /// Return the remaining contents of the string, dropping any trailing spaces or newlines. 
    public var remaining: String {
        var lastIndex = bigString.index(before: bigString.endIndex)
        while lastIndex > nextIndex &&
            (bigString[lastIndex].isWhitespace || bigString[lastIndex].isNewline) {
            lastIndex = bigString.index(before: lastIndex)
        }
        if nextIndex < lastIndex {
            return String(bigString[nextIndex...lastIndex])
        } else {
            endOfFile = true
            return ""
        }
    }
    
    /// All done reading
    public func close() {
        currIndex = bigString.startIndex
        lastChar = " "
    }
    
}
