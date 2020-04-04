//
//  Logger.swift
//  Notenik
//
//  Created by Herb Bowie on 12/27/18.
//  Copyright © 2019 - 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa
import os

public class Logger {
    
    public static let shared = Logger()
    
    var dateFormatter: DateFormatter
    var dateFormat: String
    
    public var logDestPrint   = false
    public var logDestWindow  = false
    public var logDestUnified = true
    
    public var logThreshold: LogLevel = .info
    
    public var log = ""
    
    var oslogs = [String:OSLog]()
    
    var auxLogs: [AuxiliaryLogger] = []
    
    init() {
        dateFormatter = DateFormatter()
        dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.dateFormat = dateFormat
    }
    
    public func addAuxiliaryLogger(aux: AuxiliaryLogger) -> Int {
        auxLogs.append(aux)
        return auxLogs.count - 1
    }
    
    public func removeAuxiliaryLogger(atIndex: Int) {
        guard atIndex >= 0 && atIndex < auxLogs.count else { return }
        auxLogs.remove(at: atIndex)
    }
    
    /// Log a new event. 
    public func log (_ event: LogEvent) {
        log(subsystem: event.subsystem,
            category: event.category,
            level: event.level,
            message: event.msg)
    }
    
    /// Process a loggable event
    public func log (subsystem: String, category: String, level: LogLevel, message: String) {
        if level.rawValue >= logThreshold.rawValue {
            if logDestUnified {
                if #available(OSX 10.12, *) {
                    logToUnified(subsystem: subsystem, category: category, level: level, message: message)
                } else {
                    // Fallback on earlier versions
                }
            }
            guard logDestPrint || logDestWindow else { return }
            
            var logLine = ""
            let date = Date()
            logLine.append(dateFormatter.string(from: date) + " ")
            if subsystem.count > 0 {
                logLine.append(subsystem)
            }
            if category.count > 0 {
                logLine.append("/" + category)
            }
            logLine.append(" " )
            switch level  {
            case .info:
                logLine.append("Info: ")
            case .debug:
                logLine.append("DEBUG: ")
            case .error:
                logLine.append("Error! ")
            case .fault:
                logLine.append("FAULT!! ")
            }
            logLine.append(message)

            if logDestPrint {
                print(logLine)
            }
            
            if logDestWindow {
                log.append(message)
                log.append("\n")
            }
        }
        
        for aux in auxLogs {
            aux.log(subsystem: subsystem,
                    category: category,
                    level: level,
                    message: message)
        }
    }
    
    @available(OSX 10.12, *)
    func logToUnified (subsystem: String, category: String, level: LogLevel, message: String) {
        let logKey = subsystem + "/" + category
        var oslog = oslogs[logKey]
        if oslog == nil {
            oslog = OSLog(subsystem: subsystem, category: category)
            oslogs[logKey] = oslog
        }
        var logType: OSLogType = .info
        switch level {
        case .info:
            logType = .info
        case .debug:
            logType = .debug
        case .error:
            logType = .error
        case .fault:
            logType = .fault
        }
        os_log("%{PUBLIC}@", log: oslog!, type: logType, message)
    }
    
}
