//
//  QuoteFrom.swift
//  NotenikUtils
//
//  Created by Herb Bowie on 10/8/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation


/// Format an attribution/citation for a quotation, generating appropriate HTML.
public class QuoteFrom {
    
    public var author = ""
    public var pubDate = ""
    public var workType = ""
    public var workTitle = ""
    public var authorLink = ""
    public var workLink = ""
    
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
            writer.write(" from ")
            if !workType.isEmpty {
                writer.write("the \(workType) ")
            }
            var citeType: CiteType = .minor
            switch workType.lowercased() {
            case "", "album", "book", "cd", "decision", "film", "major", "novel", "play", "television show", "unknown", "video", "web page":
                citeType = .major
            default:
                break
            }
            
            // Write out the title of the work, if we have one
            formatLink(writer: writer, link: workLink, text: workTitle, citeType: citeType)
        }
        
        // End the paragraph
        writer.finishParagraph()
    }
    
    func formatLink(writer: Markedup, link: String, text: String, citeType: CiteType, relationship: String? = nil) {
        guard !text.isEmpty else { return }
        var pre = ""
        var post = ""
        switch citeType {
        case .none:
            break
        case .minor:
            pre = "&ldquo;"
            post = "&rdquo;"
        case .major:
            pre = "<cite>"
            post = "</cite>"
        }
        let textPlus = pre + text + post
        if link.isEmpty {
            writer.write(textPlus)
        } else if link.starts(with: "https://ntnk.app") {
            writer.link(text: textPlus, path: link, title: nil, style: nil, klass: nil, blankTarget: false, relationship: relationship)
        } else if link.starts(with: "http://") || link.starts(with: "https://") {
            writer.link(text: textPlus, path: link, title: nil, style: nil, klass: "ext-link", blankTarget: true, relationship: relationship)
        } else {
            writer.link(text: textPlus, path: link, title: nil, style: nil, klass: nil, blankTarget: false, relationship: relationship)
        }
    }
    
    enum CiteType {
        case none
        case minor
        case major
    }
}

