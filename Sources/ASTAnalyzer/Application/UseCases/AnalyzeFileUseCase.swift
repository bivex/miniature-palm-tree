//
//  AnalyzeFileUseCase.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//

import Foundation

/// Use case for analyzing a Swift file for architectural defects
public final class AnalyzeFileUseCase {

    private let fileReader: FileReader
    private let syntaxParser: SyntaxParser
    private let analysisCoordinator: AnalysisCoordinator

    public init(
        fileReader: FileReader,
        syntaxParser: SyntaxParser,
        analysisCoordinator: AnalysisCoordinator
    ) {
        self.fileReader = fileReader
        self.syntaxParser = syntaxParser
        self.analysisCoordinator = analysisCoordinator
    }

    /// Executes the file analysis use case
    /// - Parameter request: The analysis request containing file path
    /// - Returns: Analysis result or throws an error
    public func execute(request: AnalyzeFileRequest) async throws -> AnalyzeFileResponse {
        // Read file content
        let fileContent = try await fileReader.readFile(at: request.filePath)

        // Validate it's a Swift file
        guard request.filePath.hasSuffix(".swift") else {
            throw AnalysisError.invalidFileType(filePath: request.filePath)
        }

        // Parse syntax
        let sourceFile = try await syntaxParser.parse(source: fileContent, filePath: request.filePath)

        // Analyze for defects
        let analysisResult = analysisCoordinator.analyze(sourceFile: sourceFile, filePath: request.filePath)

        return AnalyzeFileResponse(result: analysisResult)
    }
}

/// Request model for file analysis
public struct AnalyzeFileRequest {
    public let filePath: String

    public init(filePath: String) {
        self.filePath = filePath
    }
}

/// Response model for file analysis
public struct AnalyzeFileResponse {
    public let result: AnalysisResult

    public init(result: AnalysisResult) {
        self.result = result
    }
}