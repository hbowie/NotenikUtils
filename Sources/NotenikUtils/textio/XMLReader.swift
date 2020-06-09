//
//  XMLReader.swift
//
//  Created by Herb Bowie on 6/7/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class XMLReader: NSObject, RowImporter, XMLParserDelegate {
    
    let fileManager = FileManager.default
    
    var consumer:           RowConsumer!
    
    var labels:             [String] = []
    var fields:             [String] = []
    
    /// Initialize the class with a Row Consumer.
    public func setContext(consumer: RowConsumer) {
        self.consumer = consumer
    }
    
    public func read(fileURL: URL) {
        if FileUtils.isDir(fileURL.path) {
            scanFolderForXML(fileURL)
        } else {
            importXMLfromFile(fileURL)
        }
    }
    
    func scanFolderForXML(_ folderURL: URL) {
         do {
             let folderPath = folderURL.path
             let dirContents = try
                 fileManager.contentsOfDirectory(atPath: folderPath)
             for itemPath in dirContents {
                 let itemFullPath = FileUtils.joinPaths(path1: folderPath, path2: itemPath)
                 let itemURL = URL(fileURLWithPath: itemFullPath)
                 if itemPath.hasPrefix(".") {
                     // Skip dot files
                 } else if FileUtils.isDir(itemFullPath) {
                     switch itemPath {
                     case "backups":
                         break
                     case "export":
                         break
                     default:
                         scanFolderForXML(itemURL)
                     }
                 } else if itemPath.hasSuffix(".xml") {
                     if itemPath != "header.xml" {
                         importXMLfromFile(itemURL)
                     }
                 }
             }
         } catch let error {
             logError("Failed reading contents of directory: \(error)")
             return
         }
     }
      
     func importXMLfromFile(_ fileURL: URL) {
         print("Import XML from file \(fileURL.path)")
         guard let parser = XMLParser(contentsOf: fileURL) else {
             logError("Could not get an XML Parser for file at \(fileURL.path)")
             return
         }
         parser.delegate = self
         let ok = parser.parse()
         if !ok {
             logError("Trouble parsing XML file at: \(fileURL.path)")
         }
     }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "XMLReader",
                          level: .error,
                          message: msg)
    }
}
