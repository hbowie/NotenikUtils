//
//  RTFtoMarkdown.swift
//  NotenikUtils
//
//  Created by Herb Bowie on 1/16/25.
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A utility to parse RTF and generate Markdown from it.
public class RTFtoMarkdown {
    
    var streamState: StreamState = .normal
    var groupLevel = 0
    var skipLevel = 99
    var controlWord: String {
        get {
            return controlWordAlpha + controlWordNumeric
        }
        set {
            controlWordAlpha = newValue
            controlWordNumeric = ""
            controlParm = ""
        }
    }
    var controlWordAlpha = ""
    var controlWordNumeric = ""
    var controlParm = ""
    var fieldState: FieldState = .none
    var fieldLabel = ""
    var fieldValue = ""
    var quoting = false
    var lastCharIn: Character = " "
    var lineIn = ""
    
    var consecutiveNewlines: Int = 99

    var md = ""
    
    public init() {
        
    }
    
    public func convert(str rtf: String) -> String {
        md = ""
        groupLevel = 0
        skipLevel = 99
        streamState = .normal
        controlWord = ""
        fieldState = .none
        consecutiveNewlines = 99
        var ix = rtf.startIndex
        while ix < rtf.endIndex {
            let c = rtf[ix]
            
            /*
            if c.isNewline {
                print("  - newline")
            } else if c == "\r" {
                print("  - carriage return")
            }
            print("  - char in = \(c), lastCharIn = \(lastCharIn), stream state = \(streamState), field state = \(fieldState), group level = \(groupLevel), skip level = \(skipLevel)")
            if c.isNewline {
                print("- line in = \(lineIn)")
                print(" ")
                lineIn = ""
            } else {
                lineIn.append(c)
            } */
            
            var inc = 1
            switch streamState {
                
            // Normal processing of input stream
            case .normal:
                if c == "{" {
                    processControlWord(terminatedBy: c)
                    startGroup()
                } else if c == "}" {
                    processControlWord(terminatedBy: c)
                    endGroup()
                } else if c == "\\" {
                    processControlWord(terminatedBy: c)
                    streamState = .precedingBackslash
                    controlWord = ""
                } else if c.isNewline {
                    break
                } else {
                    processDocText(c)
                }
                
            // Let's see what follows the preceding backslash
            case .precedingBackslash:
                if c == "*" {
                    streamState = .normal
                    skipGroup()
                } else if c.isNewline {
                    newParagraph()
                    streamState = .normal
                } else if c.isLetter {
                    controlWord = String(c)
                    streamState = .buildingControlWord
                } else if c == "\'" {
                    controlWord = String(c)
                    streamState = .buildingControlWord
                } else {
                    processDocText(c)
                    streamState = .normal
                }
                
            // We're in the process of building a control word
            case .buildingControlWord:
                if c == "{" {
                    processControlWord(terminatedBy: c)
                    startGroup()
                } else if c == "}" {
                    processControlWord(terminatedBy: c)
                    endGroup()
                } else if c == ";" {
                    processControlWord(terminatedBy: c)
                    // if expectingExtraSemiColon {
                    //     expectingExtraSemiColon = false
                    // } else {
                    streamState = .normal
                    // }
                } else if c == "\\" {
                    processControlWord(terminatedBy: c)
                    streamState = .normal
                    inc = 0
                } else if c == " " {
                    if controlWordAlpha == "fcharset" {
                        streamState = .buildingControlParm
                    } else if controlWordAlpha == "\'" {
                        processControlWord(terminatedBy: c)
                        streamState = .normal
                        inc = 0
                    } else {
                        processControlWord(terminatedBy: c)
                        streamState = .normal
                    }
                } else if c.isNumber {
                    controlWordNumeric.append(c)
                } else if controlWordAlpha == "\'" && c.isHexDigit && controlWordNumeric.count < 2 {
                    controlWordNumeric.append(c)
                } else if !controlWordNumeric.isEmpty {
                    processControlWord(terminatedBy: c)
                    inc = 0
                    streamState = .normal
                } else {
                    controlWordAlpha.append(c)
                }
                
            // We're in the process of building a control parm
            case .buildingControlParm:
                if c.isWhitespace {
                    // skip it
                } else if c == ";" {
                    processControlWord(terminatedBy: c)
                    streamState = .normal
                } else {
                    controlParm.append(c)
                }
                
            // We're building a field label
            case .buildingLabel:
                if c == " " {
                    streamState = .buildingValue
                } else if c == "}" {
                    endGroup()
                    // streamState = .normal
                } else {
                    fieldLabel.append(c)
                }
                
            // We're building a field value
            case .buildingValue:
                if fieldValue.isEmpty && c == "\"" {
                    quoting = true
                } else if quoting && c == "\"" {
                    quoting = false
                } else if c == "}" && !quoting {
                    endGroup()
                } else {
                    fieldValue.append(c)
                }
            }
            
            ix = rtf.index(ix, offsetBy: inc)
            lastCharIn = c
        }
        
        processControlWord(terminatedBy: " ")
        return md
    }
    
    func startGroup() {
        groupLevel += 1
    }
    
    func endGroup() {
        if fieldState == .fldinst {
            if fieldLabel == "HYPERLINK" {
                charOut("[")
            }
            // streamState = .normal
            fieldState = .field
        } else if fieldState == .fldrslt {
            if fieldLabel == "HYPERLINK" && !fieldValue.isEmpty {
                strOut("](\(fieldValue))")
            }
            fieldLabel = ""
            fieldValue = ""
            fieldState = .none
        }
        groupLevel -= 1
        if groupLevel < skipLevel {
            skipLevel = 99
        }
        streamState = .normal
    }
    
    func processControlWord(terminatedBy: Character) {
        guard !controlWord.isEmpty else { return }
        switch controlWordAlpha {
        case "b":
            strOut("__")
        case "endash":
            charOut("–")
        case "emdash":
            charOut("—")
        case "i":
            charOut("*")
        case "field":
            if terminatedBy == "{" {
                fieldState = .field
            }
        case "fldinst":
            if terminatedBy == "{" && fieldState == .field {
                fieldState = .fldinst
                streamState = .buildingLabel
                fieldLabel = ""
                fieldValue = ""
                quoting = false
            }
        case "fldrslt":
            fieldState = .fldrslt
        case "fonttbl":
            skipGroup()
        case "ldblquote":
            charOut("“")
        case "lquote":
            charOut("‘")
        case "par":
            newParagraph()
        case "rdblquote":
            charOut("”")
        case "rquote":
            charOut("’")
        case "stylesheet":
            skipGroup()
        case "tab":
            processDocText(" ")
        case "\'":
            switch controlWordNumeric {
            case "91":
                charOut("‘")
            case "92":
                charOut("’")
            case "93":
                charOut("“")
            case "94":
                charOut("”")
            case "96":
                charOut("–")
            case "97":
                charOut("—")
            case "b7":
                charOut("+")
            default:
                break
            }
        default:
            // print(" - ignored control word \(controlWord) group level is \(groupLevel), star level is \(skipLevel)")
            break
        }
        controlWord = ""
    }
    
    func newParagraph() {
        newLine()
        newLine()
    }
    
    func newLine() {
        guard !md.isEmpty else { return }
        guard lastCharIn != "}" else { return }
        charOut("\n")
    }
    
    func skipGroup() {
        if skipLevel >= 99 {
            skipLevel = groupLevel
        }
    }
    
    func processDocText(_ char: Character) {
        if groupLevel >= skipLevel {
            if fieldState == .fldrslt {
                charOut(char)
            }
        } else {
            charOut(char)
        }
    }
    
    func strOut(_ str: String) {
        md.append(str)
        consecutiveNewlines = 0
    }
    
    func charOut(_ char: Character) {
        if char.isNewline {
            consecutiveNewlines += 1
            if consecutiveNewlines <= 2 {
                md.append(char)
            }
        } else {
            consecutiveNewlines = 0
            md.append(char)
        }
    }
    
    enum StreamState {
        case normal
        case precedingBackslash
        case buildingControlWord
        case buildingControlParm
        case buildingLabel
        case buildingValue
    }
    
    enum FieldState {
        case none
        case field
        case fldinst
        case fldrslt
    }
}
