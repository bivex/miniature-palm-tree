//
//  FileReader.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//

import Foundation

/// Port for reading files from the filesystem
public protocol FileReader {
    /// Reads the content of a file at the specified path
    /// - Parameter filePath: Absolute path to the file
    /// - Returns: File content as a string
    /// - Throws: File reading errors
    func readFile(at filePath: String) async throws -> String
}