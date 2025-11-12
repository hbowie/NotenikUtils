//
//  QuoteFrom.swift
//  NotenikUtils
//
//  Created by Herb Bowie on 10/8/24.
//
//  Copyright © 2024 - 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation


/// Format an attribution/citation for a quotation, generating appropriate HTML.
public class QuoteFrom {
    
    public static let shared = QuoteFrom()
    
    public var author = ""
    public var pubDate = ""
    public var workType = ""
    public var workTitle = ""
    public var authorLink = ""
    public var workLink = ""
    
    public let workTypes = ["unknown", "Album", "Article", "Blog Post", "Book", "CD", "Comment", "Conference", "Decision", "Editorial", "Essay", "Film", "Interview", "Lecture", "Letter", "Major Work", "Minor Work", "Novel", "Obituary", "Opinion", "Paper", "Play", "Podcast", "Poem", "Preface", "Presentation", "Quotation", "Quotation from minor", "Remarks", "Sermon", "Song", "Speech", "Story", "Television Show", "Video", "Web Page", "Web Site"]
    
    public init() {
        
    }
    
    public func formatFrom(writer: Markedup, str: String) {
        
        // Get necessary info or exit
        guard !str.isEmpty else { return }
        
        // See what info we have
        author = ""
        pubDate = ""
        workType = ""
        workTitle = ""
        authorLink = ""
        workLink = ""
        
        let parms = str.split(separator: "|", omittingEmptySubsequences: false)
        
        if parms.count > 0 {
            author = StringUtils.trim(String(parms[0]))
        }
        if parms.count > 1 {
            pubDate = StringUtils.trim(String(parms[1]))
        }
        if parms.count > 2 {
            workType = StringUtils.trim(String(parms[2]).lowercased())
        }
        if parms.count > 3 {
            workTitle = StringUtils.trim(String(parms[3]))
        }
        if parms.count > 4 {
            authorLink = StringUtils.trim(String(parms[4]))
        }
        if parms.count > 5 {
            workLink = StringUtils.trim(String(parms[5]))
        }
        
        formatFrom(writer: writer)
    }
    
    public func formatFrom(writer: Markedup) {
        
        // Start the paragraph
        writer.startParagraph(klass: "quote-from")
        
        // Write out the author's name, with an optional link
        formatLink(writer: writer, link: authorLink, text: author, citeType: .none)
        var comma = ""
        if !pubDate.isEmpty || !workTitle.isEmpty {
            writer.write(",")
        }
        
        // Write out the date, if we have one
        comma = ""
        if !pubDate.isEmpty {
            if !workTitle.isEmpty {
                comma = ","
            }
            writer.write(" \(pubDate)\(comma)")
        }
        
        if !workTitle.isEmpty {
            if workType == "Quotation" || workType == "Quotation from minor" {
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
                }
            } else {
                writer.write(" from ")
                if !workType.isEmpty {
                    writer.write("the \(workType.lowercased()) ")
                }
            }
            var citeType: CiteType = .minor
            if isMajor(workType: workType) {
                citeType = .major
            }
            
            // Write out the title of the work, if we have one
            formatLink(writer: writer, link: workLink, text: workTitle, citeType: citeType)
        }
        
        // End the paragraph
        writer.finishParagraph()
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

