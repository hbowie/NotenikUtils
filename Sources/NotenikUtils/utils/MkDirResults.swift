//
//  MkDirResults.swift
//  NotenikUtils
//
//  Created by Herb Bowie on 11/14/20.
//  Copyright © 2020 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// The possible results of an attempt to create a new directory. 
public enum MkDirResults {
    case alreadyExists
    case created
    case failure
}
