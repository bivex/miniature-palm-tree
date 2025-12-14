//
//  AnalysisError.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//

import Foundation

/// Domain errors for architectural analysis
public enum AnalysisError: Error, Equatable {
    case invalidFileType(filePath: String)
    case emptyFile(filePath: String)
    case fileNotFound(filePath: String)
    case parsingFailed(reason: String)
    case analysisTimeout
    case insufficientPermissions(filePath: String)
    case directoryNotFound(path: String)
    case pathIsNotDirectory(path: String)
    case noSwiftFilesFound(directoryPath: String)

    public var localizedDescription: String {
        switch self {
        case .invalidFileType(let filePath):
            return "File '\(filePath)' is not a valid Swift source file"
        case .emptyFile(let filePath):
            return "File '\(filePath)' is empty"
        case .fileNotFound(let filePath):
            return "File '\(filePath)' not found"
        case .parsingFailed(let reason):
            return "Failed to parse Swift syntax: \(reason)"
        case .analysisTimeout:
            return "Analysis timed out"
        case .insufficientPermissions(let filePath):
            return "Insufficient permissions to read file '\(filePath)'"
        case .directoryNotFound(let path):
            return "Directory '\(path)' not found"
        case .pathIsNotDirectory(let path):
            return "Path '\(path)' is not a directory"
        case .noSwiftFilesFound(let directoryPath):
            return "No Swift files found in directory '\(directoryPath)'"
        }
    }
}