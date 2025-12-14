//
//  AppConfiguration.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//

import Foundation

/// Configuration for the AST Analyzer application
public struct AppConfiguration: Sendable {
    public let analysis: AnalysisConfiguration

    public init(
        analysis: AnalysisConfiguration = .default
    ) {
        self.analysis = analysis
    }

    /// Default configuration
    public static let `default` = AppConfiguration()
}

/// Analysis-specific configuration
public struct AnalysisConfiguration: Sendable {
    public let maxMethodsPerType: Int
    public let maxLinesPerFile: Int
    public let maxDeclarationsPerFile: Int
    public let analysisTimeout: TimeInterval

    public init(
        maxMethodsPerType: Int = 10,
        maxLinesPerFile: Int = 500,
        maxDeclarationsPerFile: Int = 20,
        analysisTimeout: TimeInterval = 30.0
    ) {
        self.maxMethodsPerType = maxMethodsPerType
        self.maxLinesPerFile = maxLinesPerFile
        self.maxDeclarationsPerFile = maxDeclarationsPerFile
        self.analysisTimeout = analysisTimeout
    }

    /// Default analysis configuration
    public static let `default` = AnalysisConfiguration()
}