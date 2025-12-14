//
//  DirectoryOutputFormatterProtocol.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Protocol for directory output formatting to separate presentation logic from side effects
//

import Foundation

/// Protocol for formatting and outputting directory analysis results
public protocol DirectoryOutputFormatter {
    /// Outputs a formatted header for directory analysis
    func outputDirectoryHeader(for result: DirectoryAnalysisResult)

    /// Outputs a formatted summary of directory analysis
    func outputDirectorySummary(for result: DirectoryAnalysisResult)

    /// Outputs information about failed files
    func outputFailedFiles(for result: DirectoryAnalysisResult)

    /// Outputs formatted defect information for directory
    func outputDirectoryDefects(for result: DirectoryAnalysisResult)

    /// Outputs a success message when no issues are found
    func outputSuccessMessage()

    /// Outputs a formatted footer for directory analysis
    func outputDirectoryFooter(for result: DirectoryAnalysisResult)

    /// Outputs detailed file analysis if needed
    func outputDetailedFileAnalysis(for result: DirectoryAnalysisResult, filePresenter: AnalysisResultPresenter)
}