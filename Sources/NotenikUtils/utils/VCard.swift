//
//  VCard.swift
//  
//
//  Created by Herb Bowie on 5/13/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class VCard {
    public var version = "3.0"
    public var prodid = ""
    public var nameParts: [String] = []
    public var emailPrefIndex = -1
    public var emails:    [VEmail] = []
    public var fullName = ""
    public var org = ""
    public var title = ""
    
    public init() {
        
    }
    
    public func addEmail(type: String, preferred: Bool, address: String) {
        let newEmail = VEmail()
        newEmail.type = type
        newEmail.preferred = preferred
        newEmail.address = address
        if preferred {
            emailPrefIndex = emails.count
        }
        emails.append(newEmail)
    }
    
    public var primaryEmail: String {
        if emailPrefIndex >= 0 {
            return emails[emailPrefIndex].address
        } else if emails.count > 0 {
            return emails[0].address
        } else {
            return ""
        }
    }
    
    public class VEmail {
        public var type = ""
        public var preferred = false
        public var address = ""
    }
}
