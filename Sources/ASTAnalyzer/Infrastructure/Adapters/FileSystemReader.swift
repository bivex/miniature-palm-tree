//
//  FileSystemReader.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//

import Foundation

/// Adapter for reading files from the local filesystem
public final class FileSystemReader: FileReader {

    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func readFile(at filePath: String) async throws -> String {
        // Check if file exists
        guard fileManager.fileExists(atPath: filePath) else {
            throw AnalysisError.fileNotFound(filePath: filePath)
        }

        // Check if we have read permissions
        guard fileManager.isReadableFile(atPath: filePath) else {
            throw AnalysisError.insufficientPermissions(filePath: filePath)
        }

        do {
            return try String(contentsOfFile: filePath, encoding: .utf8)
        } catch {
            throw AnalysisError.parsingFailed(reason: "Failed to read file content: \(error.localizedDescription)")
        }
    }
}