//
//  OutputFormatterProtocol.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Protocol for output formatting to separate presentation logic from side effects
//

import Foundation

/// Protocol for formatting and outputting analysis results
public protocol OutputFormatter {
    /// Outputs a formatted header for the analysis result
    func outputHeader(for result: AnalysisResult)

    /// Outputs a formatted summary of the analysis result
    func outputSummary(for result: AnalysisResult)

    /// Outputs formatted defect information
    func outputDefects(for result: AnalysisResult)

    /// Outputs a success message when no issues are found
    func outputSuccessMessage()

    /// Outputs a formatted footer for the analysis result
    func outputFooter(for result: AnalysisResult)
}