//
//  LineDisplayOption.swift
//  NotenikUtils
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//
//  Created by Herb Bowie on 2/24/22.
//

import Foundation

public enum LineDisplayOption: String, CaseIterable {
    case p  = "p"
    case pBold = "p bold"
    case pItalics = "p italic"
    case pBoldItalic = "p bold and italic"
    case h1 = "h1"
    case h2 = "h2"
    case h3 = "h3"
    case h4 = "h4"
    case h5 = "h5"
    case h6 = "h6"
    case l0 = "level"
    case l1 = "level + 1"
    case l2 = "level + 2"
    case l3 = "level + 3"
}
