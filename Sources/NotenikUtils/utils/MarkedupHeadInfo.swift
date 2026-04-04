//
//  MarkedupHeadInfo.swift
//  NotenikUtils
//
//  Created by Herb Bowie on 3/31/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// Stores and manipulatues various types of information destined for the HTML head section. 
public class MarkedupHeadInfo {
    
    let xmlConverter = StringConverter()
    
    public var title:       String? = nil
    public var description: String? = nil
    public var author:      String? = nil
    public var cssCode:     String? = nil
    public var cssFile:     String? = nil
    public var javascript:  String? = nil
    public var addins:      [String] = []
    
    public init() {
        xmlConverter.addXML()
    }
    
    public convenience init(withTitle title: String?,
                            withDesc desc: String? = nil,
                            withAuthor author: String? = nil,
                            cssCode: String? = nil,
                            cssFile: String? = nil,
                            withJS js: String? = nil,
                            addins: [String] = []) {
        self.init()
        self.title = title
        self.description = desc
        self.author = author
        self.cssCode = cssCode
        self.cssFile = cssFile
        self.javascript = js
        self.addins = addins
        
    }
    
    public var titleLine: String {
        guard title != nil else { return "" }
        guard !title!.isEmpty else { return "" }
        return "<title>\(title!)</title>\n"
    }
    
    public var descriptionLine: String {
        guard description != nil else { return "" }
        guard !description!.isEmpty else { return "" }
        let xmlDesc = xmlConverter.convert(from: description!)
        return "<meta name=\"description\" content=\"\(xmlDesc)\" />\n"
    }
    
    public var authorLine: String {
        guard author != nil else { return "" }
        guard !author!.isEmpty else { return "" }
        let xmlAuthor = xmlConverter.convert(from: author!)
        return "<meta name=\"author\" content=\"\(xmlAuthor)\" />\n"
    }
    
    public var cssLines: String {
        var lines = ""
        if cssFile != nil && !cssFile!.isEmpty {
            lines = "<link rel=\"stylesheet\" href=\"\(cssFile!)\" type=\"text/css\" />"
        }
        if cssCode != nil && !cssCode!.isEmpty {
            lines.append("<style>\n")
            lines.append(cssCode!)
            lines.append("\n")
            lines.append("</style>\n")
        }
        return lines
    }
    
    public var javascriptLines: String {
        guard javascript != nil else { return "" }
        guard !javascript!.isEmpty else { return "" }
        return javascript!
    }
    
    public var addInLines: String {
        var lines = ""
        for addin in addins {
            if addin.hasSuffix(".css") {
                lines.append("<link rel=\"stylesheet\" href=\"\(addin)\" type=\"text/css\" />\n")
            } else if addin.hasSuffix(".js") {
                lines.append("<script src=\"\(addin)\" type=\"text/javascript\"></script>\n")
            }
        }
        return lines
    }

}
