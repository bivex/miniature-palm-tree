//
//  AnalysisMetadata.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Analysis metadata structure for architectural defect reports
//

import Foundation

/// Analysis metadata
public struct AnalysisMetadata: Codable {
    /// When the analysis was performed
    public let timestamp: Date

    /// Analysis duration in seconds
    public let duration: TimeInterval

    /// Number of files analyzed
    public let filesAnalyzed: Int

    /// Number of classes analyzed
    public let classesAnalyzed: Int

    /// Number of methods analyzed
    public let methodsAnalyzed: Int

    /// Thresholds used for detection
    public let thresholds: Thresholds

    /// Tool version information
    public let version: String

    public init(
        timestamp: Date = Date(),
        duration: TimeInterval,
        filesAnalyzed: Int,
        classesAnalyzed: Int,
        methodsAnalyzed: Int,
        thresholds: Thresholds,
        version: String = "1.0.0"
    ) {
        self.timestamp = timestamp
        self.duration = duration
        self.filesAnalyzed = filesAnalyzed
        self.classesAnalyzed = classesAnalyzed
        self.methodsAnalyzed = methodsAnalyzed
        self.thresholds = thresholds
        self.version = version
    }

    /// Formatted duration string
    public var durationDescription: String {
        if duration < 1.0 {
            return String(format: "%.2f seconds", duration)
        } else if duration < 60.0 {
            return String(format: "%.1f seconds", duration)
        } else {
            let minutes = Int(duration / 60)
            let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
            return "\(minutes)m \(seconds)s"
        }
    }
}