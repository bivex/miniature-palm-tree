//
//  FileSystemService.swift
//  ASTAnalyzer
//
//  Created on 2025-12-14.
//

import Foundation

/// Service for file system operations
public final class FileSystemService {

    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Finds all Swift files in a directory recursively
    /// - Parameter directoryPath: Path to search in
    /// - Returns: Array of Swift file paths
    /// - Throws: File system errors or AnalysisError
    public func findSwiftFiles(in directoryPath: String) throws -> [String] {
        guard fileManager.fileExists(atPath: directoryPath) else {
            throw AnalysisError.directoryNotFound(path: directoryPath)
        }

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: directoryPath, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw AnalysisError.pathIsNotDirectory(path: directoryPath)
        }

        var swiftFiles: [String] = []

        let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: directoryPath),
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        while let fileURL = enumerator?.nextObject() as? URL {
            let path = fileURL.path

            // Skip if it's a directory
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey]),
                  let isDir = resourceValues.isDirectory,
                  !isDir else {
                continue
            }

            // Include only .swift files
            if path.hasSuffix(".swift") {
                swiftFiles.append(path)
            }
        }

        return swiftFiles.sorted()
    }

    /// Loads file content from a path
    /// - Parameter filePath: Path to the file
    /// - Returns: File content as string
    /// - Throws: File system errors
    public func loadFileContent(at filePath: String) throws -> String {
        return try String(contentsOfFile: filePath)
    }
}