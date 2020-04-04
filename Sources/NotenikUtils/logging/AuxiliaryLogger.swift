//
//  AuxiliaryLogger.swift
//
//  Created by Herb Bowie on 3/30/20.

//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

public protocol AuxiliaryLogger {
        /// Log a new event.
    func log (_ event: LogEvent)
    
    /// Process a loggable event
    func log (subsystem: String, category: String, level: LogLevel, message: String)
}
