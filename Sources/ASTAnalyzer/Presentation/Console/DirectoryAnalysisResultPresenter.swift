//
//  DirectoryAnalysisResultPresenter.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//

import Foundation

/// Presenter responsible for coordinating the presentation of directory analysis results
/// Delegates actual output operations to a DirectoryOutputFormatter to separate concerns
public final class DirectoryAnalysisResultPresenter {

    private let filePresenter: AnalysisResultPresenter
    private let outputFormatter: DirectoryOutputFormatter

    public init(filePresenter: AnalysisResultPresenter = AnalysisResultPresenter(),
                outputFormatter: DirectoryOutputFormatter = ConsoleDirectoryOutputFormatter()) {
        self.filePresenter = filePresenter
        self.outputFormatter = outputFormatter
    }

    /// Presents the directory analysis result in a formatted output
    /// - Parameter result: The directory analysis result to present
    public func present(result: DirectoryAnalysisResult) {
        outputFormatter.outputDirectoryHeader(for: result)
        outputFormatter.outputDirectorySummary(for: result)

        if !result.failedFiles.isEmpty {
            outputFormatter.outputFailedFiles(for: result)
        }

        if result.hasIssues {
            outputFormatter.outputDirectoryDefects(for: result)
        } else {
            outputFormatter.outputSuccessMessage()
        }

        outputFormatter.outputDirectoryFooter(for: result)
        outputFormatter.outputDetailedFileAnalysis(for: result, filePresenter: filePresenter)
    }
}