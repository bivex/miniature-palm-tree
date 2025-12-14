//
//  MarkdownFileWriter.swift
//  ASTAnalyzer
//
//  Created on 2025-12-14.
//

import Foundation

/// Service for writing Markdown content to the filesystem
public final class MarkdownFileWriter {

    private let fileManager: FileManager

    public init() {
        self.fileManager = .default
    }

    public init(fileManager: FileManager) {
        self.fileManager = fileManager
    }

    /// Creates a directory if it doesn't exist
    /// - Parameter path: The directory path to create
    /// - Throws: File system errors
    public func createDirectoryIfNeeded(at path: String) throws {
        if !fileManager.fileExists(atPath: path) {
            try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
        }
    }

    /// Writes content to a file
    /// - Parameters:
    ///   - content: The content to write
    ///   - filePath: The file path to write to
    /// - Throws: File system errors
    public func writeContent(_ content: String, to filePath: String) throws {
        try content.write(to: URL(fileURLWithPath: filePath), atomically: true, encoding: .utf8)
    }

    /// Writes multiple files to a directory
    /// - Parameters:
    ///   - files: Dictionary mapping filenames to content
    ///   - directory: The directory to write files to
    /// - Throws: File system errors
    public func writeFiles(_ files: [String: String], to directory: String) throws {
        for (filename, content) in files {
            let filePath = "\(directory)/\(filename)"
            try writeContent(content, to: filePath)
        }
    }
}