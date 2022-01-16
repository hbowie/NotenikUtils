//
//  HTMLtoMarkdown.swift
//  NotenikUtils
//
//  Created by Herb Bowie on 1/14/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class HTMLtoMarkdown {
    
    var html = ""
    
    var currIndex:  String.Index
    var nextIndex:  String.Index
    
    var currChar: Character = " "
    
    var nextChunk: HTMLChunk
    
    var dropSpaces = true
    
    var chunks: [HTMLChunk] = []
    
    var markedUp = Markedup(format: .markdown)
    
    public init(html: String) {
        self.html = html
        nextChunk = HTMLChunk(type: .text, start: html.startIndex, end: html.startIndex)
        currIndex = self.html.startIndex
        if html.isEmpty {
            nextIndex = self.html.endIndex
        } else {
            nextIndex = self.html.index(after: currIndex)
        }
    }
    
    public func toMarkdown() -> String {
        breakIntoChunks()
        convertChunksToMarkdown()
        return markedUp.code
    }
    
    func breakIntoChunks() {
  
        nextChunk = HTMLChunk(type: .text, start: html.startIndex, end: html.startIndex)
        currIndex = html.startIndex
        dropSpaces = true
        while currIndex < html.endIndex {
            currChar = html[currIndex]
            nextIndex = html.index(after: currIndex)
            var nextChar: Character = " "
            if nextIndex < html.endIndex {
                nextChar = html[nextIndex]
            }
            var skipTrailingDelim = false
            // print("  - curr char = \(currChar), next char = \(nextChar), drop spaces? \(dropSpaces), next chunk type = \(nextChunk.type)")
            switch currChar {
            case ">":
                if nextChunk.type == .tag {
                    nextChunk.end = nextIndex
                    endChunk()
                    skipTrailingDelim = true
                }
            case ";":
                if nextChunk.type == .entity {
                    nextChunk.end = nextIndex
                    endChunk()
                    skipTrailingDelim = true
                }
            case "<":
                if !nextChar.isWhitespace {
                    nextChunk.end = currIndex
                    endChunk()
                }
            case "&":
                if !nextChar.isWhitespace {
                    nextChunk.end = currIndex
                    endChunk()
                }
            default:
                break
            }
            
            // print("  - curr char = \(currChar), next char = \(nextChar), drop spaces? \(dropSpaces), next chunk type = \(nextChunk.type)")
            // print(" ")
            
            switch nextChunk.type {
            case .entity:
                break
            case .tag:
                if nextChunk.element.isEmpty && currChar == "/" {
                    nextChunk.endTag = true
                } else if !nextChunk.elementComplete {
                    if currChar == "<" {
                        // do nothing
                    } else if currChar.isWhitespace || currChar.isPunctuation {
                        nextChunk.elementComplete = true
                        if nextChunk.element == "p" {
                            dropSpaces = true
                        }
                    } else {
                        nextChunk.element.append(currChar.lowercased())
                    }
                }
            case .text:
                if skipTrailingDelim {
                    // This is not really text
                } else if currChar.isWhitespace || currChar == " " {
                    if dropSpaces {
                        nextChunk.start = nextIndex
                    }
                } else {
                    dropSpaces = false
                }
            }
            currIndex = nextIndex
            nextChunk.end = nextIndex
        }
        currChar = " "
        nextChunk.end = html.endIndex
        endChunk()
    }
    
    func endChunk() {
        
        if nextChunk.end > nextChunk.start {
            if nextChunk.type == .tag && currChar != ">" {
                nextChunk.type = .text
            } else if nextChunk.type == .entity && currChar != ";" {
                nextChunk.type = .text
            }
            chunks.append(nextChunk)
            if nextChunk.type == .tag && nextChunk.element == "p" {
                dropSpaces = true
            }
            // display(nextChunk)
        }
        
        switch currChar {
        case "<":
            nextChunk = HTMLChunk(type: .tag, start: currIndex, end: currIndex)
        case "&":
            nextChunk = HTMLChunk(type: .entity, start: currIndex, end: currIndex)
        case ">":
            nextChunk = HTMLChunk(type: .text, start: nextIndex, end: nextIndex)
        case ";":
            nextChunk = HTMLChunk(type: .text, start: nextIndex, end: nextIndex)
        default:
            nextChunk = HTMLChunk(type: .text, start: currIndex, end: currIndex)
        }
        
    }
    
    func convertChunksToMarkdown() {
        markedUp = Markedup(format: .markdown)
        for chunk in chunks {
            switch chunk.type {
            case .text:
                markedUp.append(String(html[chunk.start..<chunk.end]))
            case .entity:
                convertEntity(chunk)
            case .tag:
                convertTag(chunk)
            }
        }
    }
                    
    func convertTag(_ chunk: HTMLChunk) {
        switch chunk.element {
        case "p":
            if chunk.endTag {
                markedUp.finishParagraph()
            } else {
                markedUp.startParagraph()
            }
        default:
            markedUp.append(String(html[chunk.start..<chunk.end]))
        }
    }
    
    func convertEntity(_ chunk: HTMLChunk) {
        let entity = String(html[chunk.start..<chunk.end])
        switch entity {
        case "&#8212;":
            markedUp.writeEmDash()
        case "&#8216;":
            markedUp.leftSingleQuote()
        case "&#8217;":
            markedUp.writeApostrophe()
        case "&#8220;":
            markedUp.leftDoubleQuote()
        case "&#8221;":
            markedUp.rightDoubleQuote()
        default:
            markedUp.append(entity)
        }
    }
    
    func display(_ chunk: HTMLChunk) {
        print(" ")
        print("HTMLChunk")
        print("  - type = \(chunk.type)")
        print("  - str = '\(html[chunk.start..<chunk.end])'")
        if chunk.type == .tag {
            print("  - element = '\(chunk.element)'")
            print("  - end tag? \(chunk.endTag)")
        }
    }
    
    class HTMLChunk {
        
        var type: HTMLChunkType = .text
        var start: String.Index
        var end: String.Index
        var element = ""
        var elementComplete = false
        var endTag = false
        
        init(type: HTMLChunkType, start: String.Index, end: String.Index) {
            self.type = type
            self.start = start
            self.end = end
        }
        
    }
    
    enum HTMLChunkType {
        case entity
        case tag
        case text
    }
}
