//
//  Markedup.swift
//  Notenik
//
//  Created by Herb Bowie on 1/25/19.
//  Copyright © 2019 - 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// An object capable of generating marked up text (currently HTML or Markdown)
public class Markedup: CustomStringConvertible {
    
    // -----------------------------------------------------------
    //
    // MARK: Constants, Variables, Initialization
    // and simple utilities.
    //
    // -----------------------------------------------------------
    
    public static let htmlClassWikiLink = "wiki-link"
    public static let htmlClassNavLink  = "nav-link"
    public static let htmlClassExtLink  = "ext-link"
    
    var format: MarkedupFormat = .htmlFragment
    
    var htmlFormatting = HTMLFormatting()
    
    public var code = ""
    var lastCodeAdded = ""
    
    var lastCharWasWhiteSpace = true
    var lastCharWasEmDash = false
    var startingQuote = true
    var whiteSpacePending = false
    var lastCharWasEmphasis = false
    var emphasisPending = 0
    var lastEmphasisChar: Character = " "
    
    public var defInProgress: Character = " "
    
    var currentIndent = 0
    var blockQuoting = false
    
    let xmlConverter = StringConverter()
    let codeConverter = StringConverter()
    
    var compacting = false
    
    var listsInProgress: [Character] = []
    
    public var listInProgress: Character {
        get {
            if listsInProgress.isEmpty {
                return " "
            } else {
                return listsInProgress[listsInProgress.count - 1]
            }
        }
        set {
            if newValue == " " {
                if !listsInProgress.isEmpty {
                    listsInProgress.removeLast()
                }
            } else {
                listsInProgress.append(newValue)
            }
        }
    }
    
    public init() {
        xmlConverter.addXML()
        codeConverter.addHTML()
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
    
    public func startCompacting() {
        compacting = true
    }
    
    public func finishCompacting() {
        compacting = false
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Generate Notenik Template commands.
    //
    // -----------------------------------------------------------
    
    public func templateNextRec() {
        ensureNewLine()
        writeLine("<?nextrec?>")
    }
    
    public func templateLoop() {
        ensureNewLine()
        writeLine("<?loop?>")
    }
    
    public func templateOutput(filename: String) {
        ensureNewLine()
        writeLine("<?output \"\(filename)\" ?>")
    }
    
    public func templateIfField(fieldname: String) {
        ensureNewLine()
        writeLine("<?if \"\(fieldname)\" ?>")
    }
    
    public func templateEndIf() {
        ensureNewLine()
        writeLine("<?endif?>")
    }
    
    public func templateAllFields() {
        ensureNewLine()
        writeLine("<?allfields?>")
    }
    
    public func templateVariable(name: String, mods: String? = nil) {
        if mods != nil && !mods!.isEmpty {
            write("=$\(name)\(mods!)$=")
        } else {
            write("=$\(name)$=")
        }
        
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Start and complete a document, if requested.
    //
    // -----------------------------------------------------------
    
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
                         withJS js: String? = nil,
                         epub3: Bool = false) {
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
        case .xhtmlDoc:
            if epub3 {
                writeLine("<!DOCTYPE html>")
                writeLine("<html lang=\"en\" xmlns=\"http://www.w3.org/1999/xhtml\" xmlns:epub=\"http://www.idpf.org/2007/ops\">")
            } else {
                writeLine("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>")
                writeLine("<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">")
                writeLine("<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\">")
            }
            writeLine("<head>")
            if epub3 {
                writeLine("<meta http-equiv=\"content-type\" content=\"text/html; charset=UTF-8\" />")
            } else {
                writeLine("<meta http-equiv=\"Content-Type\" content=\"application/xhtml+xml; charset=UTF-8\" />")
            }
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
        case .htmlDoc, .xhtmlDoc:
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
    
    // -----------------------------------------------------------
    //
    // MARK: Output the completed code.
    //
    // -----------------------------------------------------------
    
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
    
    // -----------------------------------------------------------
    //
    // MARK: Major body sections.
    //
    // -----------------------------------------------------------
    
    public func header(_ text: String) {
        startHeader()
        writeLine(text)
        finishHeader()
    }
    
    public func startHeader() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc:
            spaceBeforeBlock()
            writeLine("<header>")
        default:
            break
        }
    }
    
    public func finishHeader() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc:
            spaceBeforeBlock()
            writeLine("</header>")
        default:
            break
        }
    }
    
    public func nav(_ text: String) {
        startNav()
        writeLine(text)
        finishNav()
    }
    
    public func startNav() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc:
            spaceBeforeBlock()
            writeLine("<nav>")
        default:
            break
        }
    }
    
    public func finishNav() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc:
            spaceBeforeBlock()
            writeLine("</nav>")
        default:
            break
        }
    }
    
    public func footer(_ text: String) {
        startFooter()
        writeLine(text)
        finishFooter()
    }
    
    public func startFooter() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc:
            spaceBeforeBlock()
            writeLine("<footer>")
        default:
            break
        }
    }
    
    public func finishFooter() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc:
            spaceBeforeBlock()
            writeLine("</footer>")
        default:
            break
        }
    }
    
    public func main(_ text: String) {
        startMain()
        writeLine(text)
        finishMain()
    }
    
    public func startMain() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc:
            spaceBeforeBlock()
            writeLine("<main>")
        default:
            break
        }
    }
    
    public func finishMain() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc:
            spaceBeforeBlock()
            writeLine("</main>")
        default:
            break
        }
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Block Level Tags.
    //
    // -----------------------------------------------------------
    
    public func startSegment(element: String, klass: String? = nil, id: String? = nil) {
        if format == .htmlFragment || format == .htmlDoc || format == .xhtmlDoc {
            spaceBeforeBlock()
            append("<\(element)")
            if klass != nil && !klass!.isEmpty {
                append(" class=\"\(klass!)\"")
            }
            if id != nil && !id!.isEmpty {
                append(" id=\"\(id!)\"")
            }
            append(">")
            newLine()
        }
    }
    
    public func finishSegment(element: String) {
        if format == .htmlFragment || format == .htmlDoc || format == .xhtmlDoc {
            ensureNewLine()
            writeLine("</\(element)>")
            spaceAfterBlock()
        }
    }
    
    public func startDiv(klass: String?, id: String? = nil) {
        if format == .htmlFragment || format == .htmlDoc || format == .xhtmlDoc {
            spaceBeforeBlock()
            append("<div")
            if klass != nil && klass!.count > 0 {
                append(" class=\"\(klass!)\"")
            }
            if id != nil && !id!.isEmpty {
                append(" id=\"\(id!)\"")
            }
            append(">")
            newLine()
        }
    }
    
    public func finishDiv() {
        if format == .htmlFragment || format == .htmlDoc || format == .xhtmlDoc {
            writeLine("</div>")
            spaceAfterBlock()
        }
    }
    
    public func startBlockQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            spaceBeforeBlock()
            writeLine("<blockquote>")
        default:
            break
        }
        blockQuoting = true
    }
    
    public func finishBlockQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            if htmlFormatting.blockSep == .newline || htmlFormatting.blockSep == .newlineX2 {
                ensureNewLine()
            }
            writeLine("</blockquote>")
            spaceAfterBlock()
        default:
            break
        }
        blockQuoting = false
    }
    
    public func startOrderedList(klass: String?) {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            ensureNewLine()
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
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            withinListItem = false
            blocksWithinListItem = 0
            writeLine("</ol>")
            spaceAfterBlock()
        default:
            break
        }
        listInProgress = " "
    }
    
    public func startUnorderedList(klass: String?) {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            ensureNewLine()
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
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            withinListItem = false
            blocksWithinListItem = 0
            writeLine("</ul>")
            spaceAfterBlock()
        default:
            break
        }
        listInProgress = " "
    }
    
    public func startListItem(klass: String? = nil, level: Int = 0) {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            ensureNewLine()
            if klass != nil && !klass!.isEmpty {
                append("<li class=\"\(klass!)\">")
            } else {
                append("<li>")
            }
            withinListItem = true
            blocksWithinListItem = 0
        case .markdown:
            ensureNewLine()
            var indent = ""
            if level > 1 {
                indent = String(repeating: " ", count: ((level - 1) * 4))
            }
            switch listInProgress {
            case "u":
                append(indent)
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
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("</li>")
            withinListItem = false
            blocksWithinListItem = 0
            newLine()
        case .markdown:
            break
        case .opml:
            break
        }
    }
    
    public func startDefinitionList(klass: String?) {
        termsWithinList = 0
        defsWithinTerm = 0
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            spaceBeforeBlock()
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
        termsWithinList += 1
        defsWithinTerm = 0
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            spaceBeforeBlock(itemNumber: termsWithinList)
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
        case .htmlDoc, .xhtmlDoc, .netscapeBookmarks, .htmlFragment:
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
        defsWithinTerm += 1
        switch format {
        case .htmlDoc, .xhtmlDoc, .netscapeBookmarks, .htmlFragment:
            spaceBeforeBlock(itemNumber: defsWithinTerm)
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
        case .htmlDoc, .xhtmlDoc, .netscapeBookmarks, .htmlFragment:
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
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            writeLine("</dl>")
            spaceAfterBlock()
        default:
            break
        }
        listInProgress = " "
    }
    
    public func startPreformatted() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            spaceBeforeBlock()
            append("<pre>")
        case .markdown:
            break
        case .opml:
            break
        }
    }
    
    public func finishPreformatted() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            writeLine("</pre>")
        case .markdown:
            break
        case .opml:
            break
        }
    }
    
    public func startDetails(summary: String, klass: String? = nil, openParm: String? = nil) {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            spaceBeforeBlock()
            append("<details")
            if klass != nil && klass!.count > 0 {
                append(" class=\"\(klass!)\"")
            }
            if openParm != nil && !openParm!.isEmpty {
                append(" open=\"\(openParm!)\"")
            }
            writeLine(">")
            if summary.count > 0 {
                writeLine("<summary>\(summary)</summary>")
            }
        case .markdown:
            break
        case .opml:
            break
        }
    }
    
    public func startDetails(klass: String? = nil, openParm: String? = nil) {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            spaceBeforeBlock()
            append("<details")
            if klass != nil && klass!.count > 0 {
                append(" class=\"\(klass!)\"")
            }
            if openParm != nil && !openParm!.isEmpty {
                append(" open=\"\(openParm!)\"")
            }
            writeLine(">")
        case .markdown:
            break
        case .opml:
            break
        }
    }
    
    public func startSummary(id: String = "", klass: String? = nil) {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            spaceBeforeBlock()
            append("<summary")
            if id.count > 0 {
                append(" id=\"\(id)\"")
            }
            if klass != nil && klass!.count > 0 {
                append(" class=\"\(klass!)\"")
            }
            writeLine(">")
        case .markdown:
            break
        case .opml:
            break
        }
    }
    
    public func finishSummary() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            writeLine("</summary>")
        case .markdown:
            break
        case .opml:
            break
        }
    }
    
    public func finishDetails() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
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
    
    public func startParagraph(id: String = "") {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            spaceBeforeBlock()
            if id.isEmpty {
                append("<p>")
            } else {
                append("<p id=\"\(id)\">")
            }
        case .markdown:
            ensureNewLine()
        case .opml:
            break
        }
    }
    
    public func startParagraph(klass: String?) {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            spaceBeforeBlock()
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
        case .htmlDoc, .xhtmlDoc, .netscapeBookmarks, .htmlFragment:
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
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("</p>")
            // spaceAfterBlock()
        case .markdown:
            newLine()
            newLine()
        case .opml:
            break
        }
    }
    
    public func startTable(klass: String? = nil, id: String? = nil) {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            var tag = "<table"
            if id != nil && !id!.isEmpty {
                tag.append(" id=\"\(id!)\"")
            }
            if klass != nil && !klass!.isEmpty {
                tag.append(" class=\"\(klass!)\"")
            }
            tag.append(">")
            append(tag)
            newLine()
        case .markdown:
            newLine()
            newLine()
        case .opml:
            break
        }
    }
    
    public func finishTable() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("</table>")
            newLine()
        case .markdown:
            newLine()
            newLine()
        case .opml:
            break
        }
    }
    
    public func startTableRow() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("<tr>")
            newLine()
        case .markdown:
            newLine()
        case .opml:
            break
        }
    }
    
    public func finishTableRow() {
        finishTableCellIfOpen()
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("</tr>")
            newLine()
        case .markdown:
            newLine()
        case .opml:
            break
        }
    }
    
    var openTableCellTag = ""
    
    public func finishTableCellIfOpen() {
        if openTableCellTag == "th" {
            finishTableHeader()
        } else if openTableCellTag == "td" {
            finishTableData()
        }
        openTableCellTag = ""
    }
    
    public func startTableHeader(onclick: String? = nil, style: String? = nil, klass: String? = nil, colspan: Int = 1) {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            var tag = "<th"
            if onclick != nil && !onclick!.isEmpty {
                tag.append(" onclick=\"\(onclick!)\"")
            }
            if style != nil && !style!.isEmpty {
                tag.append(" style=\"\(style!)\"")
            }
            if klass != nil && !klass!.isEmpty {
                tag.append(" class=\"\(klass!)\"")
            }
            if colspan > 1 {
                tag.append(" colspan=\"\(colspan)\"")
            }
            tag.append(">")
            append(tag)
            newLine()
        case .markdown:
            append("|")
        case .opml:
            break
        }
        openTableCellTag = "th"
    }
    
    public func finishTableHeader() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("</th>")
            newLine()
        case .markdown:
            append(" ")
        case .opml:
            break
        }
        openTableCellTag = ""
    }
    
    public func startTableData(style: String? = nil, klass: String? = nil, colspan: Int = 1) {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            var tag = "<td"
            if style != nil && !style!.isEmpty {
                tag.append(" style=\"\(style!)\"")
            }
            if klass != nil && !klass!.isEmpty {
                tag.append(" class=\"\(klass!)\"")
            }
            if colspan > 1 {
                tag.append(" colspan=\"\(colspan)\"")
            }
            tag.append(">")
            append(tag)
            newLine()
        case .markdown:
            append("|")
        case .opml:
            break
        }
        openTableCellTag = "td"
    }
    
    public func finishTableData() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("</td>")
            newLine()
        case .markdown:
            append(" ")
        case .opml:
            break
        }
        openTableCellTag = ""
    }
    
    public func startForm(action: String, method: String, id: String) {
        spaceBeforeBlock()
        append("<form action=\"\(action)\" method=\"\(method)\" id=\"\(id)\">")
    }
    
    public func finishForm() {
        append("</form>")
    }
    
    public func formLabel(labelFor: String, labelText: String) {
        spaceBeforeBlock()
        append("<label for=\"\(labelFor)\">\(labelText)</label>")
    }
    
    public func formInput(inputType: String, name: String, value: String?, id: String?) {
        spaceBeforeBlock()
        append("<input type=\"\(inputType)\" name=\"\(name)\"")
        if value != nil && !value!.isEmpty {
            append(" value=\"\(value!)\"")
        }
        if id != nil && !id!.isEmpty {
            append(" id=\"\(id!)\"")
        }
        append(">")
    }
    
    public func formButton(buttonType: String, buttonText: String, klass: String? = nil, id: String? = nil) {
        spaceBeforeBlock()
        append("<button type=\"\(buttonType)\"")
        if klass != nil && !klass!.isEmpty {
            append(" class=\"\(klass!)\"")
        }
        if id != nil && !id!.isEmpty {
            append(" id=\"\(id!)\"")
        }
        append(">\(buttonText)</button>")
    }
    
    public func checkbox(id: String? = nil,
                         name: String? = nil,
                         value: String? = nil,
                         onclick: String? = nil,
                         checked: Bool = false) {
        spaceBeforeBlock()
        append("<input type=\"checkbox\"")
        if id != nil && !id!.isEmpty {
            append(" id=\"\(id!)\"")
        }
        if name != nil && !name!.isEmpty {
            append("  name=\"\(name!)\"")
        }
        if value != nil && !value!.isEmpty {
            append("  value=\"\(value!)\"")
        }
        if onclick != nil && !onclick!.isEmpty {
            append(" onclick=\"\(onclick!)\"")
        }
        if checked {
            append(" checked")
        }
        append(" />")
    }
    
    public func script(src: String) {
        ensureNewLine()
        writeLine("<script src=\"\(src)\" type=\"text/javascript\" />")
    }
    
    public func startScript() {
        ensureNewLine()
        writeLine("<script>")
    }
    
    public func finishScript() {
        spaceBeforeBlock()
        writeLine("</script>")
    }
    
    public func startStrong() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
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
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
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
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
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
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
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
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
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
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("</i>")
        case .markdown:
            append("*")
        case .opml:
            break
        }
        emphasisPending = 0
    }
    
    public func startStrikethrough() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("<s>")
        case .markdown:
            append("~~")
        case .opml:
            break
        }
    }
    
    public func finishStrikethrough() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("</s>")
        case .markdown:
            append("~~")
        case .opml:
            break
        }
    }
    
    public func startSubscript() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("<sub>")
        case .markdown:
            append("~")
        case .opml:
            break
        }
    }
    
    public func finishSubscript() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("</sub>")
        case .markdown:
            append("~")
        case .opml:
            break
        }
    }
    
    public func startSuperscript() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("<sup>")
        case .markdown:
            append("^")
        case .opml:
            break
        }
    }
    
    public func finishSuperscript() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("</sup>")
        case .markdown:
            append("^")
        case .opml:
            break
        }
    }
    
    public func startCite(klass: String? = nil) {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("<cite")
            if klass != nil && !klass!.isEmpty {
                append(" class=\"\(klass!)\"")
            }
            append(">")
        case .markdown:
            append("*")
        case .opml:
            break
        }
    }
    
    public func finishCite() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("</cite>")
        case .markdown:
            append("*")
        case .opml:
            break
        }
    }
    
    public func displayLine(opt: LineDisplayOption,
                            text: String,
                            depth: Int = 1,
                            addID: Bool = false,
                            idText: String? = nil) {
        
        var adjDepth = depth
        if adjDepth < 1 {
            adjDepth = 1
        } else if adjDepth > 6 {
            adjDepth = 6
        }
        
        var headingLevel = 0
        var bold = false
        var italic = false
        
        switch opt {
        case .p:
            break
        case .pBold:
            bold = true
        case .pItalics:
            italic = true
        case .pBoldItalic:
            bold = true
            italic = true
        case .h1:
            headingLevel = 1
        case .h2:
            headingLevel = 2
        case .h3:
            headingLevel = 3
        case .h4:
            headingLevel = 4
        case .h5:
            headingLevel = 5
        case .h6:
            headingLevel = 6
        case .l0:
            headingLevel = adjDepth
        case .l1:
            headingLevel = adjDepth + 1
        case .l2:
            headingLevel = adjDepth + 2
        case .l3:
            headingLevel = adjDepth + 3
        }
        
        if headingLevel < 0 {
            headingLevel = 0
        } else if headingLevel > 6 {
            headingLevel = 6
        }
        
        var htmlID = ""
        if addID {
            if idText == nil {
                htmlID = StringUtils.autoID(text)
            } else {
                htmlID = StringUtils.autoID(idText!)
            }
        }
        
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .markdown, .netscapeBookmarks:
            if headingLevel == 0 {
                startParagraph(id: htmlID)
                if bold {
                    startStrong()
                }
                if italic {
                    startEmphasis()
                }
            } else {
                startHeading(level: headingLevel, id: htmlID)
            }
            write(text)
            if headingLevel == 0 {
                if bold {
                    finishStrong()
                }
                if italic {
                    finishEmphasis()
                }
                finishParagraph()
            } else {
                finishHeading(level: headingLevel)
            }
            if format == .markdown {
                newLine()
            }
        case .opml:
            break
        }
    }
    
    public func heading(level: Int, text: String, addID: Bool = false, idText: String? = nil) {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            if addID {
                if idText == nil {
                    startHeading(level: level, id: StringUtils.autoID(text))
                } else {
                    startHeading(level: level, id: StringUtils.autoID(idText!))
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
    
    public func startHeading(level: Int, id: String = "", klass: String? = nil) {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            spaceBeforeBlock()
            append("<h\(level)")
            if id.count > 0 {
                append(" id=\"\(id)\"")
            } 
            if klass != nil && klass!.count > 0 {
                append(" class=\"\(klass!)\"")
            }
            append(">")
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
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            write("</h\(level)>")
            spaceAfterBlock()
        case .markdown:
            newLine()
        case .opml:
            break
        }
    }
    
    public func link(text: String,
                     path: String,
                     title: String? = nil,
                     style: String? = nil,
                     klass: String? = nil,
                     blankTarget: Bool = false,
                     relationship: String? = nil) {
        
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("<a href=\"" + path + "\"")
            if title != nil && title!.count > 0 {
                append(" title=\"\(title!)\"")
            }
            if style != nil && !style!.isEmpty {
                append(" style=\"\(style!)\"")
            }
            if klass != nil && klass!.count > 0 {
                append(" class=\"\(klass!)\"")
            }
            if blankTarget {
                append(" target=\"_blank\"")
            }
            if let relValue = relationship {
                append(" rel=\"\(relValue)\"")
            } else if blankTarget {
                append(" rel=\"noopener\"")
            }
            append(">" + text + "</a>")
        case .markdown:
            append("[" + text + "](" + path + ")")
        case .opml:
            break
        }
    }
    
    public func startLink(path: String, title: String? = nil, klass: String? = nil, blankTarget: Bool = false) {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("<a href=\"" + path + "\"")
            if title != nil && title!.count > 0 {
                append(" title=\"\(title!)\"")
            }
            if klass != nil && klass!.count > 0 {
                append(" class=\"\(klass!)\"")
            }
            if blankTarget {
                append(" target=\"_blank\" rel=\"noopener\"")
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
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
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
            caption.append("<a href=\"" + captionLink + "\" />")
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
        let pathFixed = path.replacingOccurrences(of: "?", with: "%3F")
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            startFigure()
            append("<img src=\"\(pathFixed)\" alt=\"\(alt)\"")
            if !title.isEmpty {
                append(" title=\"\(title)\"")
            }
            append(" />")
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
    
    public func startFigure(klass: String? = nil) {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            var klassAttr = ""
            if klass != nil && !klass!.isEmpty {
                klassAttr = " class=\"\(klass!)\""
            }
            writeLine("<figure\(klassAttr)>")
        default:
            break
        }
    }
    
    public func finishFigure() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            writeLine("</figure>")
        default:
            break
        }
    }
    
    public func startFigureCaption() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("<figcaption>")
        default:
            break
        }
    }
    
    public func finishFigureCaption() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("</figcaption>")
        default:
            break
        }
    }
    
    public func image(alt: String, path: String, title: String? = nil, klass: String? = nil) {
        let pathFixed = path.replacingOccurrences(of: "?", with: "%3F")
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("<img src=\"\(pathFixed)\" alt=\"\(alt)\"")
            if title != nil && title!.count > 0 {
                append(" title=\"\(title!)\"")
            }
            if klass != nil && !klass!.isEmpty {
                append(" class=\"\(klass!)\"")
            }
            append(" />")
        case .markdown:
            append("![" + alt + "](" + path + ")")
        case .opml:
            break
        }
    }
    
    public func horizontalRule() {
        switch format {
        case .htmlFragment, .htmlDoc, .netscapeBookmarks:
            spaceBeforeBlock()
            writeLine("<hr />")
            spaceAfterBlock()
        case .xhtmlDoc:
            spaceBeforeBlock()
            writeLine("<hr />")
            spaceAfterBlock()
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
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            spaceBeforeBlock()
            writeLine("<pre><code>")
            writeLine(codeConverter.convert(from: block))
            writeLine("</code></pre>")
            spaceAfterBlock()
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
    
    public func startCode() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            // if lastCodeAdded == "<pre>" {
                write("<code>")
            // } else {
            //     write("<code>")
            // }
        case .markdown:
            break
        case .opml:
            break
        }
    }
    
    public func finishCode() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            write("</code>")
        case .markdown:
            break
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
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
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
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
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
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
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
    public func appendXML(_ text: String) {
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
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("&#8220;")
        case .markdown:
            append("\"")
        case .opml:
            append("&quot;")
        }
    }
    
    public func rightDoubleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("&#8221;")
        case .markdown:
            append("\"")
        case .opml:
            append("&quot;")
        }
    }
    
    public func leftSingleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("&#8216;")
        case .markdown:
            append("'")
        case .opml:
            append("&apos;")
        }
    }
    
    public func rightSingleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
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
        currentIndent += htmlFormatting.spacesPerIndent
    }
    
    public func decreaseIndent() {
        currentIndent -= htmlFormatting.spacesPerIndent
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
        append(text)
        newLine()
    }
    
    func indent() {
        write(String(repeating: " ", count: currentIndent))
    }
    
    public func write(_ text: String) {
        append(text)
    }
    
    var newLineStarted = true
    var lastLineBlank = true
    var withinListItem = false
    var blocksWithinListItem = 0
    var termsWithinList = 0
    var defsWithinTerm = 0
    
    public func spaceBeforeBlock(itemNumber: Int = -1) {
        if withinListItem {
            blocksWithinListItem += 1
        }
        switch htmlFormatting.blockSep {
        case .none:
            break
        case .newline:
            if !withinListItem || blocksWithinListItem > 1 {
                ensureNewLine()
            }
        case .newlineX2:
            if !withinListItem  || blocksWithinListItem > 1 {
                ensureNewLine()
                if itemNumber < 0 {
                    if !code.isEmpty {
                        newLine()
                    }
                } else if itemNumber > 1 {
                    if !code.isEmpty {
                        newLine()
                    }
                }
            }
        }
    }
    
    func spaceAfterBlock() {
        switch htmlFormatting.blockSep {
        case .none:
            break
        case .newline:
            if !withinListItem || blocksWithinListItem > 1 {
                ensureNewLine()
            }
        case .newlineX2:
            if !withinListItem || blocksWithinListItem > 1 {
                ensureNewLine()
            }
        }
    }
    
    public func ensureBlankLine() {
        if !lastLineBlank {
            ensureNewLine()
            newLine()
        }
    }
    
    public func ensureNewLine() {
        if !newLineStarted {
            newLine()
        }
    }
    
    public func newLine() {
        if !compacting {
            code.append("\n")
        }
        lastLineBlank = newLineStarted
        newLineStarted = true
    }
    
    public func append(_ more: String) {
        code.append(more)
        newLineStarted = false
        lastLineBlank = false
        lastCodeAdded = more
    }
    
    func append(_ char: Character) {
        code.append(char)
        newLineStarted = false
        lastLineBlank = false
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
        lastLineBlank = false
    }
    
    public func writeNonBreakingSpace() {
        lastCharWasEmDash = false
        whiteSpacePending = false
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("&nbsp;")
        case .markdown:
            append("&nbsp;")
        case .opml:
            append(" ")
        }
        lastCharWasWhiteSpace = true
        newLineStarted = false
        lastLineBlank = false
    }
    
    /// Write out an en dash
    public func writeEnDash() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
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
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
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
        case .htmlDoc, .xhtmlDoc, .netscapeBookmarks, .htmlFragment:
            append("&#8230;")
        case .markdown:
            append("...")
        case .opml:
            append("...")
        }
    }
    
    func writeDoubleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
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
    
    public func writeApostrophe() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
            append("&apos;")
        case .markdown:
            append("'")
        case .opml:
            append("&apos;")
        }
    }
    
    func writeSingleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
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
    
    public func writeEndingSingleQuote() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc:
            append("&#8217;")
        case .markdown, .netscapeBookmarks:
            append("'")
        case .opml:
            append("&apos;")
        }
        lastCharWasWhiteSpace = false
        lastCharWasEmDash = false
    }
    
    public func writeLeftAngleBracket() {
        switch format {
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
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
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
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
        case .htmlFragment, .htmlDoc, .xhtmlDoc, .netscapeBookmarks:
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
