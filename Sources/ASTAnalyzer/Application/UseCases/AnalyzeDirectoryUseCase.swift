//
//  AnalyzeDirectoryUseCase.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//

import Foundation

/// Use case for analyzing a directory recursively for architectural defects
public final class AnalyzeDirectoryUseCase {

    private let fileReader: FileReader
    private let analyzeFileUseCase: AnalyzeFileUseCase

    public init(
        fileReader: FileReader,
        analyzeFileUseCase: AnalyzeFileUseCase
    ) {
        self.fileReader = fileReader
        self.analyzeFileUseCase = analyzeFileUseCase
    }

    /// Executes the directory analysis use case
    /// - Parameter request: The analysis request containing directory path
    /// - Returns: Directory analysis result or throws an error
    public func execute(request: AnalyzeDirectoryRequest) async throws -> AnalyzeDirectoryResponse {
        let startTime = Date()

        // Find all Swift files recursively
        let swiftFiles = try await findSwiftFiles(in: request.directoryPath)

        guard !swiftFiles.isEmpty else {
            throw AnalysisError.noSwiftFilesFound(directoryPath: request.directoryPath)
        }

        // Analyze each file
        var fileResults: [AnalysisResult] = []
        var failedFiles: [(String, Error)] = []

        for filePath in swiftFiles {
            do {
                let fileRequest = AnalyzeFileRequest(filePath: filePath)
                let response = try await analyzeFileUseCase.execute(request: fileRequest)
                fileResults.append(response.result)
            } catch {
                failedFiles.append((filePath, error))
            }
        }

        let endTime = Date()
        let totalDuration = endTime.timeIntervalSince(startTime)

        // Create summary result
        let summaryResult = DirectoryAnalysisResult(
            directoryPath: request.directoryPath,
            fileResults: fileResults,
            failedFiles: failedFiles,
            analysisDuration: totalDuration,
            analyzedAt: endTime
        )

        return AnalyzeDirectoryResponse(result: summaryResult)
    }

    // MARK: - Private Methods

    private func findSwiftFiles(in directoryPath: String) async throws -> [String] {
        let fileManager = FileManager.default

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
}

/// Request model for directory analysis
public struct AnalyzeDirectoryRequest {
    public let directoryPath: String

    public init(directoryPath: String) {
        self.directoryPath = directoryPath
    }
}

/// Response model for directory analysis
public struct AnalyzeDirectoryResponse {
    public let result: DirectoryAnalysisResult

    public init(result: DirectoryAnalysisResult) {
        self.result = result
    }
}

/// Result model for directory analysis containing summary of all files
public struct DirectoryAnalysisResult {
    public let directoryPath: String
    public let fileResults: [AnalysisResult]
    public let failedFiles: [(String, Error)]
    public let analysisDuration: TimeInterval
    public let analyzedAt: Date

    // Computed properties for summary
    public var totalFiles: Int {
        fileResults.count
    }

    public var totalFailedFiles: Int {
        failedFiles.count
    }

    public var totalDefects: Int {
        fileResults.reduce(0) { $0 + $1.totalDefects }
    }

    public var criticalDefects: Int {
        fileResults.reduce(0) { $0 + $1.criticalDefects.count }
    }

    public var highPriorityDefects: Int {
        fileResults.reduce(0) { $0 + $1.highPriorityDefects.count }
    }

    public var averageMaintainabilityScore: Double {
        guard !fileResults.isEmpty else { return 0.0 }
        let totalScore = fileResults.reduce(0.0) { $0 + $1.maintainabilityScore }
        return totalScore / Double(fileResults.count)
    }

    public var hasIssues: Bool {
        totalDefects > 0
    }

    public var requiresRefactoring: Bool {
        criticalDefects > 0 || averageMaintainabilityScore < 50.0
    }

    public var hasCriticalIssues: Bool {
        criticalDefects > 0
    }

    public var defectsBySeverity: [Severity: [ArchitecturalDefect]] {
        var result: [Severity: [ArchitecturalDefect]] = [:]

        for fileResult in fileResults {
            for (severity, defects) in fileResult.defectsBySeverity {
                result[severity, default: []].append(contentsOf: defects)
            }
        }

        return result
    }
}