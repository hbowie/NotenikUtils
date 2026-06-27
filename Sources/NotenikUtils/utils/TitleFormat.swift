//
//  TitleFormat.swift
//  NotenikUtils
//
//  Created by Herb Bowie on 2/18/26.
//
//  Copyright © 2026 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public enum TitleFormat: String, CaseIterable {
    case trimmed        = "trimmed"
    case plain          = "plain"
    case common         = "common"
    case macFileName    = "macfilename"
    case webFileName    = "webfilename"
    case html           = "html"
}

