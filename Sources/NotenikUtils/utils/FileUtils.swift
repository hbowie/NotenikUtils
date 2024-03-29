//
//  FileUtils.swift
//  Notenik
//
//  Created by Herb Bowie on 12/24/18.
//  Copyright © 2019 - 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

public class FileUtils {
    
    /// Conditionally save a string to disk, logging any errors encountered.
    /// - Parameters:
    ///   - strToWrite: The string to be written to disk.
    ///   - outputURL: The disk location to which we are to write.
    ///   - createDirectories: Create any enclosing folders needed (or not). 
    ///   - checkForChanges: If true, try to read the existing file first, and then write only if the contents have changed.
    public static func saveToDisk(strToWrite: String,
                                  outputURL: URL,
                                  createDirectories: Bool = false,
                                  checkForChanges: Bool = false) -> Bool {
        
        var written = false
        
        var bypassWrite = false
        
        if checkForChanges {
            do {
                let existing = try String(contentsOf: outputURL, encoding: .utf8)
                if existing == strToWrite {
                    bypassWrite = true
                }
            } catch {
                // Don't worry about it.
            }
        }
        
        if !bypassWrite {
            do {
                if createDirectories {
                    let outputFolder = outputURL.deletingLastPathComponent()
                    _ = FileUtils.ensureFolder(forURL: outputFolder)
                }
                try strToWrite.write(to: outputURL, atomically: true, encoding: .utf8)
                written = true
            } catch let error {
                Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                                  category: "FileUtils",
                                  level: .error,
                                  message: "Could not write file at \(outputURL.path) due to \(error)")
            }
        }
        
        return written
    }
    
    /// See if a path points to a directory / folder.
    ///
    /// - Parameter path: A string containing a path pointing to a file system object.
    /// - Returns: True if the path points to a folder; otherwise false. 
    public static func isDir (_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        guard exists else { return false }
        return isDirectory.boolValue
    }
    
    /// See if the specified folder is empty (ignoring hidded macOS trickery). . 
    public static func isEmpty(_ path: String) -> Bool {
        do {
            let items = try FileManager.default.contentsOfDirectory(atPath: path)
            if items.count == 0 {
                return true
            } else {
                for item in items {
                    if item != ".DS_Store" {
                        return false
                    }
                }
                return true
            }
        } catch {
            return false
        }
    }
    
    /// Join two path Strings, ensuring one and only one slash between the two.
    ///
    /// - Parameters:
    ///   - path1: A string containing the beginning of a file path.
    ///   - path2: A string containing a continuation of a file path.
    /// - Returns: A combination of the two. 
    public static func joinPaths(path1: String, path2: String) -> String {
        var e1 = path1.endIndex
        if path1.hasSuffix("/") {
            e1 = path1.index(path1.startIndex, offsetBy: path1.count - 1)
        }
        let sub1 = path1[..<e1]
        var s2 = path2.startIndex
        if path2.hasPrefix("/") {
            s2 = path2.index(path2.startIndex, offsetBy: 1)
        }
        let sub2 = path2[s2..<path2.endIndex]
        return sub1 + "/" + sub2
    }
    
    /// Ensure the given folder exists, creating it if necessary.
    /// - Parameters:
    ///   - path1: The beginning of the path.
    ///   - path2: The rest of the path.
    /// - Returns: The combined path, if it exists, otherwise nil. 
    public static func ensureFolder(path1: String, path2: String) -> String? {
        let dirPath = FileUtils.joinPaths(path1: path1, path2: path2)
        let ok = FileUtils.ensureFolder(forDir: dirPath)
        if ok {
            return dirPath
        } else {
            return nil
        }
    }
    
    /// Check to see if the given folder already exists.
    /// If it does not, then try to create it.
    ///
    /// - Parameter forDir: The path to the directory to be ensured.
    /// - Returns: True if folder now exists, false if it didn't already
    ///            exist and couldn't be created.
    public static func ensureFolder(forDir dirPath: String) -> Bool {
        let folderURL = URL(fileURLWithPath: dirPath)
        return FileUtils.ensureFolder(forURL: folderURL)
    }
    
    /// Check to see if the given folder already exists.
    /// If it does not, then try to create it.
    /// - Parameters:
    ///   - parentURL: The URL of a parent folder.
    ///   - folder: A string containing a path component to be added to the parent.
    /// - Returns: The URL of the target folder, if it now exists; if it did not already exist,
    ///            and it could not be created, then return nil. 
    public static func ensureFolder(parentURL: URL, folder: String) -> URL? {
        let folderURL = parentURL.appendingPathComponent(folder)
        if FileManager.default.fileExists(atPath: folderURL.path) {
            return folderURL
        }
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "FileUtils",
                              level: .error,
                              message: "Could not create a new directory at \(folderURL.path)")
            return nil
        }
        return folderURL
    }
    
    /// Check to see if the given folder already exists.
    /// If it does not, then try to create it.
    ///
    /// - Parameter dirPath: The path to the directory to be ensured.
    /// - Returns: True if folder now exists, false if it didn't already
    ///            exist and couldn't be created.
    public static func ensureFolder(forURL folderURL: URL) -> Bool {
        if FileManager.default.fileExists(atPath: folderURL.path) { return true }
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "FileUtils",
                              level: .error,
                              message: "Could not create a new directory at \(folderURL.path)")
            return false
        }
        return true
    }
    
    /// Check to see if the folder enclosing this file already exists.
    /// If it does not, then try to create it.
    ///
    /// - Parameter filePath: The path to the file whose folder is to be ensured.
    /// - Returns: True if folder now exists, false if it didn't already
    ///            exist and couldn't be created.
    public static func ensureFolder(forFile filePath: String) -> Bool {
        let fileURL = URL(fileURLWithPath: filePath)
        let folderURL = fileURL.deletingLastPathComponent()
        if FileManager.default.fileExists(atPath: folderURL.path) { return true }
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            Logger.shared.log(subsystem: "com.",
                              category: "com.powersurgepub.notenik",
                              level: .error,
                              message: "Could not create a new directory at \(folderURL.path)")
            return false
        }
        return true
    }
    
    /// Attempt to make a new directory at the given location.
    public static func makeDirectory(at dirURL: URL, withIntermediateDirectories: Bool = true) -> MkDirResults {
        let dirPath = dirURL.path
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: dirPath, isDirectory: &isDir) {
            if isDir.boolValue {
                return .alreadyExists
            } else {
                return .failure
            }
        }
        do {
            try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: withIntermediateDirectories)
        } catch {
            return .failure
        }
        return .created
    }
    
    /// Attempt to remove the file or folder at the given file path.
    public static func removeItem(at filePath: String) -> Bool {
        let url = URL(fileURLWithPath: filePath)
        return removeItem(at: url)
    }
    
    /// Attempt to remove the file or folder at the given URL.
    public static func removeItem(at: URL?) -> Bool {
        guard let urlToRemove = at else { return false }
        var removed = false
        do {
            if #available(iOS 11.0, *) {
                try FileManager.default.trashItem(at: urlToRemove, resultingItemURL: nil)
                removed = true
            }
        } catch {
            print("Error trashing item: \(error)")
            removed = false
        }
        if !removed {
            do {
                try FileManager.default.removeItem(at: urlToRemove)
                removed = true
            } catch {
                print ("Error deleting item: \(error)")
                removed = false
            }
        }
        return removed
    }
}
