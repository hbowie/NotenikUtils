//
//  VCardParser.swift
//  
//
//  Created by Herb Bowie on 5/13/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class VCardParser {
    
    var word = ""
    var firstWord = ""
    var emailTypeExpected = false
    var emailPreferred = false
    var emailType = ""
    
    var card = VCard()
    var begun = false
    var cards: [VCard] = []
    
    public init() {
        
    }
    
    public func parse(_ text: String) -> [VCard] {
        let reader = BigStringReader(text)
        return parse(reader)
    }
    
    public func parse(_ reader: LineReader) -> [VCard] {
        cards = []
        begun = false
        card = VCard()
        reader.open()
        var line: String? = ""
        line = reader.readLine()
        while line != nil {
            firstWord = ""
            word = ""
            emailTypeExpected = false
            emailPreferred = false
            emailType = ""
            for c in line! {
                switch c {
                case ":", ";", "=":
                    endWord(with: c)
                default:
                    word.append(c)
                }
            }
            if word.count > 0 {
                endWord(with: " ")
            }
            line = reader.readLine()
        }
        reader.close()
        return cards
    }
    
    func endWord(with: Character) {
        guard word.count > 0 || with == ";" else { return }
        if firstWord.count == 0 {
            firstWord = word
        } else {
            endLaterWord(with: with)
        }
        word = ""
    }
    
    func endLaterWord(with: Character) {
        switch firstWord {
        case "BEGIN":
            if word == "VCARD" {
                begun = true
                card = VCard()
            }
        case "VERSION":
            card.version = word
        case "PRODID":
            card.prodid = word
        case "N":
            card.nameParts.append(word)
        case "FN":
            card.fullName = word
        case "ORG":
            card.org = word
        case "TITLE":
            card.title = word
        case "EMAIL":
            if word.contains("@") {
                card.addEmail(type: emailType, preferred: emailPreferred, address: word)
            } else if word == "type" && with == "=" {
                emailTypeExpected = true
            } else if emailTypeExpected {
                if word == "INTERNET" {
                    // yes, we know
                } else if word == "pref" {
                    emailPreferred = true
                } else {
                    emailType = word
                }
            }
        case "END":
            if word == "VCARD" {
                if begun {
                    cards.append(card)
                }
                begun = false
            }
        default:
            break
        }
    }
    
}
