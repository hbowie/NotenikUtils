//
//  NumberUtils.swift
//  NotenikUtils
//
//  Copyright © 2025 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//
//  Created by Herb Bowie on 3/24/25.
//
public class NumberUtils {
    
    public static let romanDecimals = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
    public static let romanNumerals = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]
    public static let romanLowers   = ["m", "cm", "d", "cd", "c", "xc", "l", "xl", "x", "ix", "v", "iv", "i"]
    
    public static let lowerChars: [Character] = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
    public static let upperChars: [Character] = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    
    private init() {
        
    }
    
    public static func testAlternates() {
        print("NumberUtils.testAlternates")
        var i = 1
        while i <= 677 {
            let alphaLower = NumberUtils.toAlpha(i, lowercase: true)
            let alphaUpper = NumberUtils.toAlpha(i, lowercase: false)
            let romanLower = NumberUtils.toRoman(i, lowercase: true)
            let romanUpper = NumberUtils.toRoman(i, lowercase: false)
            print("\(i) becomes \(alphaLower) | \(alphaUpper) | \(romanLower) | \(romanUpper)")
            i += 1
        }
    }
    
    public static func toAlternate(_ str: String, altType: Character) -> String {
        if let i = Int(str) {
            return NumberUtils.toAlternate(i, altType: altType)
        } else {
            return str
        }
    }
    
    public static func toAlternate(_ i: Int, altType: Character) -> String {
        
        switch altType {
        case "a":
            return NumberUtils.toAlpha(i, lowercase: true)
        case "A":
            return NumberUtils.toAlpha(i, lowercase: false)
        case "i":
            return NumberUtils.toRoman(i, lowercase: true)
        case "I":
            return NumberUtils.toRoman(i, lowercase: false)
        default:
            return "\(i)"
        }
    }
    
    public static func toRoman(_ i: Int, lowercase: Bool = false) -> String {
        

        
        var number = i
        var result = ""
        
        while number > 0 {
            for (index, decimal) in romanDecimals.enumerated() {
                if number - decimal >= 0 {
                    number -= decimal
                    if lowercase {
                        result += romanLowers[index]
                    } else {
                        result += romanNumerals[index]
                    }
                    break
                }
            }
        }
        
        return result
    }
    
    public static func toAlpha(_ i: Int,
                               zeroAdjusted: Bool = false,
                               lowercase: Bool = false) -> String {
        
        var number = i
        if !zeroAdjusted && number > 0 {
            number -= 1
        }

        var result = ""
        
        let (q, r) = number.quotientAndRemainder(dividingBy: 26)
        if lowercase {
            result.insert(lowerChars[r], at: result.startIndex)
        } else {
            result.insert(upperChars[r], at: result.startIndex)
        }
 
        if q > 0 && q < 26 {
            if lowercase {
                result.insert(lowerChars[q], at: result.startIndex)
            } else {
                result.insert(upperChars[q], at: result.startIndex)
            }
        }

        return result
    }
    
}
