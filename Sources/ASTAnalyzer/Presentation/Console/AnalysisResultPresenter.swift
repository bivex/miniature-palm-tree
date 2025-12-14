//
//  AnalysisResultPresenter.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//

import Foundation

/// Presenter responsible for coordinating the presentation of analysis results
/// Delegates actual output operations to an OutputFormatter to separate concerns
public final class AnalysisResultPresenter {

    private let outputFormatter: OutputFormatter

    public init(outputFormatter: OutputFormatter = ConsoleOutputFormatter()) {
        self.outputFormatter = outputFormatter
    }

    /// Presents the analysis result in a formatted output
    /// - Parameter result: The analysis result to present
    public func present(result: AnalysisResult) {
        outputFormatter.outputHeader(for: result)
        outputFormatter.outputSummary(for: result)

        if result.hasIssues {
            outputFormatter.outputDefects(for: result)
        } else {
            outputFormatter.outputSuccessMessage()
        }

        outputFormatter.outputFooter(for: result)
    }
}