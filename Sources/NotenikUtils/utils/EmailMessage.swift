//
//  EmailMessage.swift
//
//  Created by Herb Bowie on 5/15/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A Class to parse a string and separate out some key email message components.
public class EmailMessage {
    
    public var from = ""
    public var to = ""
    public var date = ""
    public var subject = ""
    public var importance = ""
    public var body = ""
    
    let fromPrefix = "From: "
    let toPrefix   = "To: "
    let datePrefix = "Date: "
    let subjectPrefix = "Subject: "
    let importancePrefix = "Importance: "
    let plainTextContentTypePrefix = "Content-Type: text/plain"
    
    var fieldType = FieldType.na
    var fieldValue1 = BigStringWriter()
    var fieldValue2 = BigStringWriter()
    
    var reader = BigStringReader()
    var line: String?
    var mimeInProcess = false
    var textStarted = false
    
    /// Create a new instance.
    public init() {
        
    }
    
    /// Scan a string; following the scan, the from, to, date, subject and body
    /// fields may be available.
    public func scan(str: String) {
        fieldType = .na
        fieldValue1 = BigStringWriter()
        reader = BigStringReader(str)
        reader.open()
        line = reader.readLine()
        while line != nil {
            if !mimeInProcess && line!.hasPrefix("MIME-version: ") {
                startMime()
            } else if mimeInProcess {
                anotherMimeLine()
            }
            line = reader.readLine()
        }
        endMime()
        reader.close()
    }
    
    /// Start processing MIME lines.
    func startMime() {
        mimeInProcess = true
    }
    
    /// Finish processing MIME lines.
    func endMime() {
        endField()
        mimeInProcess = false
    }
    
    /// Scan MIME lines, trying to build fields.
    func anotherMimeLine() {
        if line!.hasPrefix("--_") {
            endField()
        } else if fieldType == .body {
            scanLine1(str: line!)
        } else if line!.hasPrefix(fromPrefix) {
            startField(type: .from, line: line!)
        } else if line!.hasPrefix(toPrefix) {
            startField(type: .to, line: line!)
        } else if line!.hasPrefix(datePrefix) {
            startField(type: .date, line: line!)
        } else if line!.hasPrefix(subjectPrefix) {
            startField(type: .subject, line: line!)
        } else if line!.hasPrefix(importancePrefix) {
            endField()
            fieldType = .na
        } else if line!.hasPrefix(plainTextContentTypePrefix) {
            startField(type: .body, line: "")
        } else if fieldType != .na {
            scanLine1(str: line!)
        }
    }
    
    /// Start a new field of a specified type, and possibly with some initial content.
    func startField(type: FieldType, line: String) {
        endField()
        fieldValue1 = BigStringWriter()
        fieldValue1.open()
        fieldType = type
        var bypass = 0
        switch type {
        case .from:
            bypass = fromPrefix.count
        case .date:
            bypass = datePrefix.count
        case .to:
            bypass = toPrefix.count
        case .subject:
            bypass = subjectPrefix.count
        case .body:
            bypass = 0
        case .na:
            bypass = 0
        case .importance:
            bypass = 0
        }
        scanLine1(str: String(line.suffix(line.count - bypass)))
    }
    
    /// Perform an initial scan of content lines, with trailing equals signs indicating
    /// that the line break should be suppressed.
    func scanLine1(str: String) {
        if str.hasSuffix("=") {
            fieldValue1.write(String(str.prefix(str.count - 1)))
        } else if str.hasSuffix("=20") {
            fieldValue1.writeLine(String(str.prefix(str.count - 3)))
            fieldValue1.writeLine("")
        } else {
            fieldValue1.writeLine(str)
        }
    }
    
    /// Handle the end of a field.
    func endField() {
        guard fieldValue1.count > 0 else { return }
        fieldValue1.close()
        let reader1 = BigStringReader(fieldValue1.bigString)
        fieldValue2 = BigStringWriter()
        reader1.open()
        fieldValue2.open()
        var line1 = reader1.readLine()
        while line1 != nil {
            fieldValue2.writeLine("\(deMimed(line1: line1!))  ")
            line1 = reader1.readLine()
        }
        reader1.close()
        fieldValue2.close()
        switch fieldType {
        case .body:
            body = fieldValue2.bigString
        case .date:
            date = StringUtils.cleanAndTrim(fieldValue2.bigString)
        case .from:
            from = StringUtils.cleanAndTrim(fieldValue2.bigString)
        case .importance:
            break
        case .na:
            break
        case .subject:
            subject = StringUtils.cleanAndTrim(fieldValue2.bigString)
        case .to:
            to = StringUtils.cleanAndTrim(fieldValue2.bigString)
        }
        fieldValue1 = BigStringWriter()
        fieldType = .na
    }
    
    var line2 = ""
    var possibleThree = ""
    var possibleChain = ""
    
    func deMimed(line1: String) -> String {
        line2 = ""
        possibleThree = ""
        possibleChain = ""
        for c in line1 {
            if c == "=" {
                appendEquals()
            } else if possibleThree.count > 0 {
                if possibleThree.count < 3 {
                    possibleThree.append(c)
                } else {
                    processThree()
                    processChain()
                    line2.append(c)
                }
            } else {
                processChain()
                line2.append(c)
            }
        }
        processThree()
        processChain()
        return line2
    }
    
    func appendEquals() {
        if possibleThree.count == 3 {
            processThree()
        } else if possibleThree.count > 0 {
            processChain()
            line2.append(possibleThree)
        }
        possibleThree = "="
    }
    
    func processThree() {
        guard possibleThree.count > 0 else { return }
        possibleChain.append(possibleThree)
        possibleThree = ""
    }
    
    func processChain() {
        guard possibleChain.count > 0 else { return }
        switch possibleChain {
        case "=20":
            line2.append(" ")
        case "=C2=A0":
            line2.append(" ")
        case "=E2=80=99":
            line2.append("'")
        case "=E2=80=94":
            line2.append("--")
        case "=E2=80=9C":
            line2.append("\"")
        case "=E2=80=9D":
            line2.append("\"")
        default:
            line2.append(possibleChain)
        }
        possibleChain = ""
    }
    
    enum FieldType {
        case na
        case from
        case to
        case date
        case subject
        case importance
        case body
    }
}
