//
//  HTMLtoMarkdown.swift
//  NotenikUtils
//
//  Created by Herb Bowie on 1/14/22.

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
    
    var chunks: [HTMLChunk] = []
    
    var markdown = ""
    
    public init(html: String) {
        self.html = html
        nextChunk = HTMLChunk(type: .text, start: html.startIndex, end: html.startIndex)
        currIndex = self.html.startIndex
        nextIndex = self.html.index(after: currIndex)
    }
    
    public func toMarkdown() -> String {
        breakIntoChunks()
        return markdown
    }
    
    func breakIntoChunks() {
        nextChunk = HTMLChunk(type: .text, start: html.startIndex, end: html.startIndex)
        currIndex = html.startIndex
        while currIndex < html.endIndex {
            currChar = html[currIndex]
            nextIndex = markdown.index(after: currIndex)
            var nextChar: Character = " "
            if nextIndex < html.endIndex {
                nextChar = html[nextIndex]
            }
            switch currChar {
            case ">":
                if nextChunk.type == .tag {
                    endChunk()
                }
            case ";":
                if nextChunk.type == .entity {
                    endChunk()
                }
            case "<":
                if !nextChar.isWhitespace {
                    endChunk()
                }
            case "&":
                if !nextChar.isWhitespace {
                    endChunk()
                }
            default:
                break
            }
            
            switch nextChunk.type {
            case .entity:
                break
            case .tag:
                if nextChunk.element.isEmpty && currChar == "/" {
                    nextChunk.endTag = true
                } else if !nextChunk.elementComplete {
                    if currChar.isWhitespace {
                        nextChunk.elementComplete = true
                    } else {
                        nextChunk.element.append(currChar.lowercased())
                    }
                }
            case .text:
                break
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
