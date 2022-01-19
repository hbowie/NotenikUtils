//
//  Markedup.swift
//  Notenik
//
//  Created by Herb Bowie on 1/25/19.
//  Copyright © 2019 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// An object capable of generating marked up text (currently HTML or Markdown)
public class Markedup: CustomStringConvertible {
    
    var format: MarkedupFormat = .htmlFragment
    public var code = ""
    
    var lastCharWasWhiteSpace = true
    var lastCharWasEmDash = false
    var startingQuote = true
    var whiteSpacePending = false
    var lastCharWasEmphasis = false
    var emphasisPending = 0
    var lastEmphasisChar: Character = " "
    public var listInProgress: Character = " "
    public var defInProgress: Character = " "
    
    var spacesPerIndent = 2
    var currentIndent = 0
    var blockQuoting = false
    
    let xmlConverter = StringConverter()
    
    public init() {
        xmlConverter.addXML()
    }
    
    public convenience init (format: MarkedupFormat) {
        self.init()
        self.format = format
    }
    
    /// Return the description, used as the String value for the object
    public var description: String {
        return code
    }
    
    public func flushCode() {
        code = ""
    }
    
    public func templateNextRec() {
        writeLine("<?nextrec?>")
    }
    
    public func templateLoop() {
        writeLine("<?loop?>")
    }
    
    public func templateOutput(filename: String) {
        writeLine("<?output \"\(filename)\" ?>")
    }
    
    public func templateIfField(fieldname: String) {
        writeLine("<?if \"\(fieldname)\" ?>")
    }
    
    public func templateEndIf() {
        writeLine("<?endif?>")
    }
    
    public func templateAllFields() {
        writeLine("<?allfields?>")
    }
    
    // Make sure we're not generating HTML doc stuff. 
    public func noDoc() {
        if format == .htmlDoc {
            format = .htmlFragment
        }
    }
    
    /// Start the document with appropriate markup.
    /// - Parameters:
    ///   - title: The page title, if one is available.
    ///   - css: The CSS to be used, or the filename containing the CSS.
    ///   - linkToFile: If true, then interpet the CSS string as a file name, rather than the actual CSS. 
    public func startDoc(withTitle title: String?,
                         withCSS css: String?,
                         linkToFile: Bool = false,
                         withJS js: String? = nil) {
        currentIndent = 0
        switch format {
        case .htmlDoc:
            writeLine("<!DOCTYPE html>")
            writeLine("<html lang=\"en\">")
            writeLine("<head>")
            writeLine("<meta charset=\"utf-8\" />")
            if title != nil && title!.count > 0 {
                writeLine("<title>\(title!)</title>")
            }
            writeLine("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />")
            if css != nil && css!.count > 0 {
                if linkToFile {
                    writeLine("<link rel=\"stylesheet\" href=\"\(css!)\" type=\"text/css\" />")
                } else {
                    writeLine("<style>")
                    writeLine(css!)
                    writeLine("</style>")
                }
            }
            if js != nil && js!.count > 0 {
                writeLine(js!)
            }
            writeLine("</head>")
            writeLine("<body>")
        case .netscapeBookmarks:
            writeLine("<!DOCTYPE NETSCAPE-Bookmark-file-1>")
            increaseIndent()
            writeLine("<HTML>")
            writeLine("<META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=UTF-8\">")
            writeLine("<Title>Bookmarks</Title>")
            writeLine("<H1>Bookmarks</H1>")
            writeLine("<DL><p>")
            increaseIndent()
        case .opml:
            writeLine("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
            writeLine("<opml version=\"2.0\">")
            writeLine("<head>")
            if title != nil {
                writeLine("<title>\(title!)</title>")
            }
            writeLine("</head>")
            writeLine("<body>")
        default:
            break
        }
    }
    
    public func finishDoc() {
        switch format {
        case .htmlDoc:
            writeLine("</body>")
            writeLine("</html>")
        case .netscapeBookmarks:
            writeLine("</DL>")
            decreaseIndent()
            writeLine("</HTML>")
            decreaseIndent()
        case .opml:
            writeLine("</body>")
            writeLine("</opml>")
        case .htmlFragment, .markdown:
            break
        }
    }
    
    public func writeDoc(to url: URL) -> Bool {
        do {
            try code.write(to: url, atomically: true, encoding: String.Encoding.utf8)
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "Markedup",
                              level: .info,
                              message: "Document written to \(url.path)")
        } catch {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "Markedup",
                              level: .error,
                              message: "Problems writing document to \(url.path)")
            return false
        }
        return true
    }
    
    public func startDiv(klass: String?) {
        if format == .htmlFragment || format == .htmlDoc {
            ensureNewLine()
            append("<div")
            if klass != nil && klass!.count > 0 {
                append(" class=\"\(klass!)\"")
            }
            append(">")
            newLine()
        }
    }
    
    public func finishDiv() {
        if format == .htmlFragment || format == .htmlDoc {
            writeLine("</div>")
        }
    }
    
    public func startBlockQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("<blockquote>")
        default:
            break
        }
        blockQuoting = true
    }
    
    public func finishBlockQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("</blockquote>")
        default:
            break
        }
        blockQuoting = false
    }
    
    public func startOrderedList(klass: String?) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("<ol")
            if klass != nil && klass!.count > 0 {
                append(" class=\"\(klass!)\"")
            }
            append(">")
            newLine()
        case .markdown:
            if code.count > 0 {
                newLine()
            }
        case .opml:
            break
        }
        listInProgress = "o"
    }
    
    public func finishOrderedList() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("</ol>")
        default:
            break
        }
        listInProgress = " "
    }
    
    public func startUnorderedList(klass: String?) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("<ul")
            if klass != nil && klass!.count > 0 {
                append(" class=\"\(klass!)\"")
            }
            append(">")
            newLine()
        case .markdown:
            if code.count > 0 {
                newLine()
            }
        case .opml:
            break
        }
        listInProgress = "u"
    }
    
    public func finishUnorderedList() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("</ul>")
        default:
            break
        }
        listInProgress = " "
    }
    
    public func startListItem() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            ensureNewLine()
            append("<li>")
        case .markdown:
            switch listInProgress {
            case "u":
                append("* ")
            case "o":
                append("1. ")
            default:
                break
            }
        case .opml:
            break
        }
    }
    
    public func finishListItem() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("</li>")
            newLine()
        case .markdown:
            break
        case .opml:
            break
        }
    }
    
    public func startDefinitionList(klass: String?) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("<dl")
            if klass != nil && klass!.count > 0 {
                append(" class=\"\(klass!)\"")
            }
            append(">")
            newLine()
        case .markdown:
            if code.count > 0 {
                newLine()
            }
        case .opml:
            break
        }
        listInProgress = "d"
        defInProgress = " "
    }
    
    public func startDefTerm() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            ensureNewLine()
            append("<dt>")
        case .markdown:
            ensureNewLine()
            newLine()
        case .opml:
            break
        }
        defInProgress = "t"
    }
    
    public func finishDefTerm() {
        switch format {
        case .htmlDoc, .netscapeBookmarks, .htmlFragment:
            append("</dt>")
            newLine()
        case .markdown:
            newLine()
        case .opml:
            break
        }
        defInProgress = " "
    }
    
    public func startDefDef() {
        switch format {
        case .htmlDoc, .netscapeBookmarks, .htmlFragment:
            ensureNewLine()
            append("<dd>")
        case .markdown:
            ensureNewLine()
            append(": ")
        case .opml:
            break
        }
        defInProgress = "d"
    }
    
    public func finishDefDef() {
        switch format {
        case .htmlDoc, .netscapeBookmarks, .htmlFragment:
            append("</dd>")
            newLine()
        case .markdown:
            newLine()
        case .opml:
            break
        }
        defInProgress = " "
    }
    
    public func finishDefinitionList() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("</dl>")
        default:
            break
        }
        listInProgress = " "
    }
    
    public func startPreformatted() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("<pre>")
        case .markdown:
            break
        case .opml:
            break
        }
    }
    
    public func finishPreformatted() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("</pre>")
        case .markdown:
            break
        case .opml:
            break
        }
    }
    
    public func startCode() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            write("<code>")
        case .markdown:
            break
        case .opml:
            break
        }
    }
    
    public func finishCode() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            write("</code>")
        case .markdown:
            break
        case .opml:
            break
        }
    }
    
    public func startDetails(summary: String) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("<details>")
            if summary.count > 0 {
                writeLine("<summary>\(summary)</summary>")
            }
        case .markdown:
            break
        case .opml:
            break
        }
    }
    
    public func finishDetails() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("</details>")
        case .markdown:
            break
        case .opml:
            break
        }
    }
    
    public func paragraph(text: String) {
        startParagraph()
        write(text)
        finishParagraph()
    }
    
    public func startParagraph() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            ensureNewLine()
            append("<p>")
        case .markdown:
            ensureNewLine()
        case .opml:
            break
        }
    }
    
    public func startParagraph(klass: String?) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            ensureNewLine()
            append("<p")
            if klass != nil && klass!.count > 0 {
                append(" class=\"\(klass!)\"")
            }
            append(">")
        case .markdown:
            ensureNewLine()
        case .opml:
            break
        }
    }
    
    public func lineBreak() {
        switch format {
        case .htmlDoc, .netscapeBookmarks, .htmlFragment:
            append("<br />")
            newLine()
        case .markdown:
            append("  ")
            newLine()
        case .opml:
            break
        }
    }
    
    public func finishParagraph() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("</p>")
            newLine()
        case .markdown:
            newLine()
            newLine()
        case .opml:
            break
        }
    }
    
    public func startStrong() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("<strong>")
        case .markdown:
            append("**")
        case .opml:
            break
        }
        emphasisPending = 2
        lastCharWasEmphasis = true
    }
    
    public func finishStrong() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("</strong>")
        case .markdown:
            append("**")
        case .opml:
            break
        }
        emphasisPending = 0
    }
    
    public func startEmphasis() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("<em>")
        case .markdown:
            append("*")
        case .opml:
            break
        }
        emphasisPending = 1
    }
    
    public func finishEmphasis() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("</em>")
        case .markdown:
            append("*")
        case .opml:
            break
        }
        emphasisPending = 0
    }
    
    public func startItalics() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("<i>")
        case .markdown:
            append("*")
        case .opml:
            break
        }
        emphasisPending = 1
    }
    
    public func finishItalics() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("</i>")
        case .markdown:
            append("*")
        case .opml:
            break
        }
        emphasisPending = 0
    }
    
    public func startCite() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("<cite>")
        case .markdown:
            append("*")
        case .opml:
            break
        }
    }
    
    public func finishCite() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("</cite>")
        case .markdown:
            append("*")
        case .opml:
            break
        }
    }
    
    public func heading(level: Int, text: String, addID: Bool = false, idText: String? = nil) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            if addID {
                if idText == nil {
                    startHeading(level: level, id: StringUtils.toCommonFileName(text))
                } else {
                    startHeading(level: level, id: StringUtils.toCommonFileName(idText!))
                }
            } else {
                startHeading(level: level)
            }
            write(text)
            finishHeading(level: level)
        case .markdown:
            writeLine(String(repeating: "#", count: level) + " " + text)
            newLine()
        case .opml:
            break
        }
    }
    
    public func startHeading(level: Int, id: String = "") {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            if id.count > 0 {
                write("<h\(level) id=\"\(id)\">")
            } else {
                write("<h\(level)>")
            }
        case .markdown:
            ensureNewLine()
            newLine()
            write(String(repeating: "#", count: level) + " ")
        case .opml:
            break
        }
    }
    
    public func finishHeading(level: Int) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("</h\(level)>")
        case .markdown:
            newLine()
        case .opml:
            break
        }
    }
    
    public func link(text: String, path: String, title: String? = nil) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("<a href=\"" + path + "\"")
            if title != nil && title!.count > 0 {
                append(" title=\"\(title!)\"")
            }
            append(">" + text + "</a>")
        case .markdown:
            append("[" + text + "](" + path + ")")
        case .opml:
            break
        }
    }
    
    public func startLink(path: String, title: String? = nil) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("<a href=\"" + path + "\"")
            if title != nil && title!.count > 0 {
                append(" title=\"\(title!)\"")
            }
            append(">")
        case .markdown:
            append("[")
        case .opml:
            break
        }
    }
    
    public func finishLink() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("</a>")
        case .markdown:
            break
        case .opml:
            break
        }
    }
    
    public func image(path: String,
                      alt: String,
                      title: String,
                      captionPrefix: String,
                      captionText: String,
                      captionLink: String) {
        
        var caption = ""
        caption.append(captionPrefix)
        if !captionLink.isEmpty {
            caption.append("<a href=\"" + captionLink + "\">")
        }
        caption.append(captionText)
        if !captionLink.isEmpty {
            caption.append("</a>")
        }
        
        image(path: path, alt: alt, title: title, caption: caption)
    }
    
    public func image(path: String,
                      alt: String,
                      title: String,
                      caption: String) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            startFigure()
            append("<img src=\"\(path)\" alt=\"\(alt)\"")
            if !title.isEmpty {
                append(" title=\"\(title)\"")
            }
            append(">")
            startFigureCaption()
            append(caption)
            finishFigureCaption()
            finishFigure()
        case .markdown:
            append("![" + alt + "](" + path + " \"" + title + "\")")
        case .opml:
            break
        }
    }
    
    public func startFigure() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("<figure>")
        default:
            break
        }
    }
    
    public func finishFigure() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("</figure>")
        default:
            break
        }
    }
    
    public func startFigureCaption() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("<figcaption>")
        default:
            break
        }
    }
    
    public func finishFigureCaption() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("</figcaption>")
        default:
            break
        }
    }
    
    public func image(alt: String, path: String, title: String? = nil) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("<img src=\"\(path)\" alt=\"\(alt)\"")
            if title != nil && title!.count > 0 {
                append(" title=\"\(title!)\"")
            }
            append(">")
        case .markdown:
            append("![" + alt + "](" + path + ")")
        case .opml:
            break
        }
    }
    
    public func horizontalRule() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("<hr>")
        case .markdown:
            newLine()
            append("---")
            newLine()
        case .opml:
            break
        }
    }
    
    public func codeBlock(_ block: String) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("<pre><code>")
            writeLine(block)
            writeLine("</code></pre>")
        case .markdown:
            let reader: LineReader = BigStringReader(block)
            reader.open()
            var line = reader.readLine()
            while line != nil {
                append("    " + line! + "\n")
                line = reader.readLine()
            }
            reader.close()
        case .opml:
            break
        }
    }
    
    public func openTag(_ tag: String) {
        append("<" + tag)
    }
    
    public func addHref(_ value: String) {
        addAttribute(label: "href", value: value)
    }
    
    public func addID(_ value: String) {
        addAttribute(label: "id", value: value)
    }
    
    public func addTitle(_ value: String) {
        addAttribute(label: "title", value: value)
    }
    
    public func addClass(_ value: String) {
        addAttribute(label: "class", value: value)
    }
    
    public func addAttribute(label: String, value: String) {
        append(" \(label)=\"")
        appendXML(value)
        append("\"")
    }
    
    public func closeTag() {
        append(">")
    }
    
    /// Open up the starting outline tag.
    public func startOutlineOpen(_ text: String) {
        append("<outline text=\"")
        appendXML(text)
        append("\"")
    }
    
    public func addOutlineAttribute(label: String, value: String) {
        append(" \(label)=\"")
        appendXML(value)
        append("\"")
    }
    
    /// Close out the starting outline tag.
    public func startOutlineClose(finishToo: Bool = true) {
        if finishToo {
            append("/")
        }
        append(">")
        newLine()
    }
    
    /// Finish up an open OPML outline.
    public func finishOutline() {
        writeLine("</outline>")
    }
    
    /// Write a comment line.
    public func comment(_ text: String) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("<!-- \(text) -->")
        case .markdown:
            newLine()
            writeLine("<!-- \(text) -->")
            newLine()
        case .opml:
            writeLine("<!-- \(text) -->")
        }
    }
    
    public func startMultiLineComment(_ text: String) {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("<!-- \(text) ")
        case .markdown:
            newLine()
            writeLine("<!-- \(text) ")
        case .opml:
            writeLine("<!-- \(text) ")
        }
    }
    
    public func finishMultiLineComment(_ text: String) {
        var paddedText = text
        if text.count > 0 {
            paddedText = text + " "
        }
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            writeLine("\(paddedText)-->")
        case .markdown:
            newLine()
            writeLine("\(paddedText)-->")
            newLine()
        case .opml:
            writeLine("\(paddedText)-->")
        }
    }
    
    /// Encode restricted characters as XML entities.
    func appendXML(_ text: String) {
        append(xmlConverter.convert(from: text))
    }
    
    /// Enclose a value in a span tag, with a class.
    ///
    /// - Parameters:
    ///   - value: The value to be enclosed between starting and ending span tags.
    ///   - klass: The class to be embedded in the starting span tag.
    ///   - prefix: A prefix to precede the span.
    ///   - suffix: A suffix to follow the span. 
    public func spanConditional(value: String, klass: String, prefix: String, suffix: String, tag: String = "span") {
        if value.count > 0 && value.lowercased() != "unknown" {
            append(prefix)
            append("<\(tag) class=\'\(klass)\'>")
            append(value)
            append("</\(tag)>")
            append(suffix)
        }
    }
    
    public func leftDoubleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("&#8220;")
        case .markdown:
            append("\"")
        case .opml:
            append("&quot;")
        }
    }
    
    public func rightDoubleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("&#8221;")
        case .markdown:
            append("\"")
        case .opml:
            append("&quot;")
        }
    }
    
    public func leftSingleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("&#8216;")
        case .markdown:
            append("'")
        case .opml:
            append("&apos;")
        }
    }
    
    public func rightSingleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("&#8217;")
        case .markdown:
            append("'")
        case .opml:
            append("&apos;")
        }
    }
    
    public func appendNumberedAttribute(number: Int) {
        append("&#\(number);")
    }
    
    public func shortDash() {
        writeEnDash()
    }
    
    public func longDash() {
        writeEmDash()
    }
    
    public func increaseIndent() {
        currentIndent += spacesPerIndent
    }
    
    public func decreaseIndent() {
        currentIndent -= spacesPerIndent
        if currentIndent < 0 {
            currentIndent = 0
        }
    }
    
    public func writeBlockOfLines(_ block: String) {
        let reader = BigStringReader(block)
        reader.open()
        var line: String?
        repeat {
            line = reader.readLine()
            if line != nil {
                writeLine(line!)
            }
        } while line != nil
        reader.close()
    }
    
    public func writeLine(_ text: String) {
        indent()
        if blockQuoting && format == .markdown {
            write("> ")
        }
        write(text)
        newLine()
    }
    
    func indent() {
        write(String(repeating: " ", count: currentIndent))
    }
    
    public func write(_ text: String) {
        append(text)
    }
    
    var newLineStarted = true
    
    func ensureNewLine() {
        if !newLineStarted {
            newLine()
        }
    }
    
    public func newLine() {
        code.append("\n")
        newLineStarted = true
    }
    
    public func append(_ more: String) {
        code.append(more)
        newLineStarted = false
    }
    
    func append(_ char: Character) {
        code.append(char)
        newLineStarted = false
    }
    
    /// Parse the passed text line, using a subset of Markdown syntax, and convert it
    /// to the desired output format.
    ///
    /// - Parameters:
    ///   - text: The text to be parsed.
    ///   - startingLastCharWasWhiteSpace: An indicator of whether the last character
    ///                                    was some sort of white space.
    public func parse(text: String, startingLastCharWasWhiteSpace: Bool) {
        startDoc(withTitle: nil, withCSS: nil)
        lastCharWasWhiteSpace = startingLastCharWasWhiteSpace
        whiteSpacePending = true
        if lastCharWasWhiteSpace {
            whiteSpacePending = false
        }
        emphasisPending = 0
        lastCharWasEmDash = false
        if whiteSpacePending {
            writeSpace()
        }
        
        var index = text.startIndex
        for char in text {
            
            // If this is the second char in the -- sequence, then just
            // let it go by, since we already wrote out the em dash.
            if lastCharWasEmDash {
                lastCharWasEmDash = false
                lastCharWasWhiteSpace = false
            }
                
                // If we have white space, write out only one space
            else if char.isWhitespace {
                writeSpace()
            }
                
                // If we have an en dash, replace it with an appropriate entity
            else if (char == "-" && lastCharWasWhiteSpace
                && text.charAtOffset(index: index, offsetBy: 1).isWhitespace) {
                writeEnDash()
            }
                
                // If we have two dashes, replace them witn an em dash
            else if char == "-" && text.charAtOffset(index: index, offsetBy: 1) == "-" {
                writeEmDash()
            }
                
                // If we have a double quotion mark, replace it with a smart quote
            else if char == "\"" {
                writeDoubleQuote()
            }
                
                // If we have a single quotation mark, replace it with the appropriate entity
            else if char == "'" {
                if text.charAtOffset(index: index, offsetBy: 1).isLetter {
                    writeApostrophe()
                } else {
                    writeSingleQuote()
                }
            }
                
                // If an isolated ampersand, replace it with an appropriate entity
            else if char == "&" && text.charAtOffset(index: index, offsetBy: 1).isWhitespace {
                writeAmpersand()
            }
                
                // Check for emphasis
            else if char == "*" || char == "_" {
                if lastCharWasEmphasis {
                    // If this is the second char in the emphasis sequence, then just let
                    // it go by, since we already wrote out the appropriate html.
                    lastCharWasEmphasis = false
                } else if (emphasisPending == 1
                    && char == lastEmphasisChar
                    && !lastCharWasWhiteSpace) {
                    finishEmphasis()
                } else if (emphasisPending == 2
                    && char == lastEmphasisChar
                    && text.charAtOffset(index: index, offsetBy: 1) == lastEmphasisChar
                    && !lastCharWasWhiteSpace) {
                    finishStrong()
                    lastCharWasEmphasis = true
                } else if (emphasisPending == 0
                    && text.charAtOffset(index: index, offsetBy: 1) == char
                    && !text.charAtOffset(index: index, offsetBy: 2).isWhitespace) {
                    startStrong()
                    lastEmphasisChar = char
                } else if (emphasisPending == 0
                    && !text.charAtOffset(index: index, offsetBy: 1).isWhitespace) {
                    startEmphasis()
                    lastEmphasisChar = char
                } else {
                    lastCharWasWhiteSpace = false
                    lastCharWasEmDash  = false
                    append(char)
                }
            } else {
                lastCharWasWhiteSpace = false
                lastCharWasEmDash = false
                append(char)
            }
            index = text.index(after: index)
        }
        finishDoc()
    }
    
    /// Write out a space, but don't write more than one in a row
    func writeSpace() {
        lastCharWasEmDash = false
        whiteSpacePending = false
        if !lastCharWasWhiteSpace {
            append(" ")
            lastCharWasWhiteSpace = true
        }
        newLineStarted = false
    }
    
    /// Write out an en dash
    public func writeEnDash() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("&#8211;")
        case .markdown:
            append("-")
        case .opml:
            append("-")
        }
        lastCharWasWhiteSpace = false
        lastCharWasEmDash = false
    }
    
    public func writeEmDash() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("&#8212;")
        case .markdown:
            append("--")
        case .opml:
            append("--")
        }
        lastCharWasWhiteSpace = false
        lastCharWasEmDash = true
    }
    
    public func ellipsis() {
        switch format {
        case .htmlDoc, .netscapeBookmarks, .htmlFragment:
            append("&#8230;")
        case .markdown:
            append("...")
        case .opml:
            append("...")
        }
    }
    
    func writeDoubleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            if startingQuote {
                append("&#8220;")
                startingQuote = false
            } else {
                append("&#8221;")
                startingQuote = true
            }
        case .markdown:
            append("\"")
        case .opml:
            append("&quot;")
        }
        lastCharWasWhiteSpace = false
        lastCharWasEmDash = false
    }
    
    func writeApostrophe() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("&apos;")
        case .markdown:
            append("'")
        case .opml:
            append("&apos;")
        }
    }
    
    func writeSingleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            if startingQuote {
                append("&#8216;")
                startingQuote = false
            } else {
                append("&#8217;")
                startingQuote = true
            }
        case .markdown:
            append("'")
        case .opml:
            append("&apos;")
        }
        lastCharWasWhiteSpace = false
        lastCharWasEmDash = false
    }
    
    public func writeLeftAngleBracket() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("&lt;")
        case .markdown:
            append("<")
        case .opml:
            append("&lt;")
        }
        lastCharWasWhiteSpace = false
        lastCharWasEmDash = false
    }
    
    public func writeRightAngleBracket() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("&gt;")
        case .markdown:
            append(">")
        case .opml:
            append("&gt;")
        }
        lastCharWasWhiteSpace = false
        lastCharWasEmDash = false
    }
    
    public func writeAmpersand() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            append("&amp;")
        case .markdown:
            append("&")
        case .opml:
            append("&amp;")
        }
        lastCharWasWhiteSpace = false
        lastCharWasEmDash = false
    }
}
