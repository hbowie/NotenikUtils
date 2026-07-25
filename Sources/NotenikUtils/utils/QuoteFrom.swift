//
//  QuoteFrom.swift
//  NotenikUtils
//
//  Created by Herb Bowie on 10/8/24.
//
//  Copyright © 2024 - 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Format an attribution/citation for a quotation, generating appropriate HTML.
public class QuoteFrom {
    
    public static let shared = QuoteFrom()
    
    public var author = ""
    public var authorIdBasis = ""
    public var authorTitle = ""
    public var pubDate = ""
    public var workType = ""
    public var workTitle = ""
    public var workIdBasis = ""
    public var authorLink = ""
    public var workLink = ""
    
    public let workTypes = ["unknown", "Album", "Article", "Blog Post", "Book", "CD", "Comment", "Conference", "Decision", "Editorial", "Essay", "Film", "Interview", "Lecture", "Letter", "Liner Notes", "Major Work", "Minor Work", "Novel", "Obituary", "Opinion", "Paper", "Play", "Podcast", "Poem", "Preface", "Presentation", "Quotation", "Quotation from minor", "Remarks", "Sermon", "Song", "Speech", "Story", "Television Show", "Video", "Web Page", "Web Site"]
    
    public init() {
        
    } 
    
    public func formatFrom(writer: Markedup, str: String) {
        
        // Get necessary info or exit
        guard !str.isEmpty else { return }
        
        // See what info we have
        author = ""
        authorTitle = ""
        pubDate = ""
        workType = ""
        workTitle = ""
        authorLink = ""
        workLink = ""
        
        let parms = str.split(separator: "|", omittingEmptySubsequences: false)
        
        var nextParm = 0
        
        if parms.count > nextParm {
            author = StringUtils.trim(String(parms[nextParm]))
            nextParm += 1
        }
        
        if parms.count > nextParm {
            let possibleDate = FreeformDate(String(parms[nextParm]))
            if possibleDate.funkyDate {
                authorTitle = StringUtils.trim(String(parms[nextParm]))
                nextParm += 1
            }
        }
        
        if parms.count > nextParm {
            pubDate = StringUtils.trim(String(parms[nextParm]))
            nextParm += 1
        }
        
        if parms.count > nextParm {
            workType =  StringUtils.trim(String(parms[nextParm]))
            nextParm += 1
        }
        
        if parms.count > nextParm {
            workTitle =  StringUtils.trim(String(parms[nextParm]))
            nextParm += 1
        }
        
        if parms.count > nextParm {
            authorLink =  StringUtils.trim(String(parms[nextParm]))
            nextParm += 1
        }
        if parms.count > nextParm {
            workLink =  StringUtils.trim(String(parms[nextParm]))
            nextParm += 1
        }
        
        formatFrom(writer: writer)
    }
    
    public func formatFrom(writer: Markedup) {
        
        if writer.format == .markdown {
            formatFromInMarkdown(writer: writer)
            return
        }
        
        // Start the paragraph
        writer.startParagraph(klass: "quote-from")
        
        // Write out the author's name, with an optional link
        formatLink(writer: writer, link: authorLink, text: author, citeType: .none)
        
        
        var comma = ""
        if !pubDate.isEmpty || !workTitle.isEmpty || !authorTitle.isEmpty {
            writer.write(",")
        }
        
        // Write out the author's title, if we have one
        if !authorTitle.isEmpty {
            if !pubDate.isEmpty || !workTitle.isEmpty {
                comma = ","
            }
            writer.write(" \(authorTitle)\(comma)")
        }
        
        // Write out the date, if we have one
        comma = ""
        if !pubDate.isEmpty {
            if !workTitle.isEmpty {
                comma = ","
            }
            let dateValue = FreeformDate(pubDate)
            writer.write(" \(dateValue.dMyDate)\(comma)")
        }
        
        if !workTitle.isEmpty {
            formatWorkTypeString(writer: writer)
            
            var citeType: CiteType = .minor
            if isMajor(workType: workType) {
                citeType = .major
            }
            
            let formatter = TitleFormatter(workTitle)
            
            // Write out the title of the work, if we have one
            formatLink(writer: writer, link: workLink, text: formatter.html, citeType: citeType)
        }
        
        // End the paragraph
        writer.finishParagraph()
    }
    
    /// Format  a quote citation in Markdown, deferring any HTML conversion until later.
    /// - Parameter writer: A Markedup writer to receive the code.
    public func formatFromInMarkdown(writer: Markedup) {
        guard !author.isEmpty else { return }
        
        // Write out the author's name, with an optional link
        if !authorIdBasis.isEmpty {
            writer.write("[[")
        }
        writer.write(authorIdBasis)
        if !authorIdBasis.isEmpty && author != authorIdBasis {
            writer.write("|\(author)")
        }
        if !authorIdBasis.isEmpty {
            writer.write("]]")
        }
        
        if !pubDate.isEmpty || !workTitle.isEmpty {
            writer.write(",")
        }
        
        // Write out the date, if we have one
        var comma = ""
        if !pubDate.isEmpty {
            if !workTitle.isEmpty {
                comma = ","
            }
            let dateValue = FreeformDate(pubDate)
            writer.write(" \(dateValue.dMyDate)\(comma)")
        }
        
        if !workTitle.isEmpty {
            
            formatWorkTypeString(writer: writer)
 
            var citeType: CiteType = .minor
            if isMajor(workType: workType) {
                citeType = .major
            }
            
            // Write out the title of the work, if we have one
            if citeType == .major {
                writer.write("*")
            } else {
                writer.write("\"")
            }
            
            if !workIdBasis.isEmpty {
                writer.write("[[")
            }
            
            let formatter = TitleFormatter(workTitle)
            if !workIdBasis.isEmpty && workTitle != workIdBasis {
                writer.write("\(workIdBasis)|\(formatter.trimmed)")
            } else {
                writer.write(formatter.trimmed)
            }
            
            if !workIdBasis.isEmpty {
                writer.append("]]")
            }
            
            if citeType == .major {
                writer.write("*")
            } else {
                writer.write("\"")
            }
        }
        writer.newLine()
    }
    
    public func formatWorkFromInMarkdown(writer: Markedup) {
        guard !author.isEmpty else { return }
        
        // Write out the author's name, with an optional link
        if !authorIdBasis.isEmpty {
            writer.write("[[")
        }
        writer.write(authorIdBasis)
        if !authorIdBasis.isEmpty && author != authorIdBasis {
            writer.write("|\(author)")
        }
        if !authorIdBasis.isEmpty {
            writer.write("]]")
        }
        
        if !pubDate.isEmpty || !workType.isEmpty {
            writer.write(",")
        }
        
        // Write out the date, if we have one
        if !pubDate.isEmpty {
            let dateValue = FreeformDate(pubDate)
            writer.write(" \(dateValue.dMyDate)")
        }
        
        writer.newLine()
    }
    
    func formatLink(writer: Markedup, link: String, text: String, citeType: CiteType, relationship: String? = nil) {
        guard !text.isEmpty else { return }
        if citeType == .major {
            writer.startCite()
        } else if citeType == .minor {
            writer.write("&ldquo;")
        }
        
        if link.isEmpty {
            writer.write(text)
        } else if link.starts(with: "https://ntnk.app") {
            writer.link(text: text, path: link, title: nil, style: nil, klass: nil, blankTarget: false, relationship: relationship)
        } else if link.starts(with: "http://") || link.starts(with: "https://") {
            writer.link(text: text, path: link, title: nil, style: nil, klass: "ext-link", blankTarget: true, relationship: relationship)
        } else {
            writer.link(text: text, path: link, title: nil, style: nil, klass: nil, blankTarget: false, relationship: relationship)
        }
        
        if citeType == .major {
            writer.finishCite()
        } else if citeType == .minor {
            writer.write("&rdquo;")
        }
    }
    
    func formatWorkTypeString(writer: Markedup) {
        switch workType {
        case "Quotation", "Quotation from minor":
            handleQuotation(writer: writer)
        case "Letter":
            handleLetter(writer: writer)
        default:
            writer.write(" from ")
            if !workType.isEmpty {
                writer.write("the \(workType.lowercased()) ")
            }
        }
    }
    
    func handleQuotation(writer: Markedup) {
        writer.write(" as quoted in ")
        
        // If present, remove "quoted in/from" verbiage from start of work title
        let titleLowered = workTitle.lowercased()
        if titleLowered.hasPrefix("quot") && (titleLowered.contains(" from ") || titleLowered.contains(" in ")) {
            var stage = 0
            var word1 = ""
            var word2 = ""
            var prefixLength = 0
            forEachChar: for char in titleLowered {
                prefixLength += 1
                switch stage {
                case 0:
                    // looking for start of first word
                    if !char.isWhitespace {
                        stage  = 1
                        word1.append(char)
                    }
                case 1:
                    // looking for end of first word
                    if !char.isWhitespace {
                        word1.append(char)
                    } else if word1.hasPrefix("quot") {
                        stage = 2
                    } else {
                        break forEachChar
                    }
                case 2:
                    // looking for start of second word
                    if !char.isWhitespace {
                        stage = 3
                        word2.append(char)
                    }
                case 3:
                    // looking for end of second word
                    if !char.isWhitespace {
                        word2.append(char)
                    } else if word2 == "from" || word2 == "in" {
                        stage = 4
                    } else {
                        word2 = ""
                        stage = 2
                    }
                case 4:
                    // looking for start of title beyond second word
                    if !char.isWhitespace {
                        stage = 5
                        prefixLength -= 1
                        break forEachChar
                    }
                default:
                    stage = 6
                    break forEachChar
                } // end of stage switch
            } // end of leading character inspection
            if stage == 5 {
                workTitle.removeFirst(prefixLength)
            }
            
            if workTitle.hasSuffix(")") && workTitle.contains(" (") {
                while !workTitle.hasSuffix("(") {
                    workTitle.removeLast()
                }
                workTitle.removeLast(2)
            }
        }
    }
    
    func handleLetter(writer: Markedup) {
        writer.write(" from the letter ")
        if workTitle.lowercased().hasPrefix("letter ") {
            workTitle.removeFirst(7)
        }
    }
        
    public func isMajor(workType: String) -> Bool {
        let workTypeCommon = StringUtils.toCommon(workType)
        switch workTypeCommon {
        case "", "album", "book", "cd", "decision", "film", "majorwork", "novel", "play", "quotation", "televisionshow", "unknown", "video", "website":
            return true
        default:
            return false
        }
    }
    
    enum CiteType {
        case none
        case minor
        case major
    }
}

