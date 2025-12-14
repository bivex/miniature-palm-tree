//
//  AnalysisResult.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//

import Foundation

/// Root aggregate representing the complete result of an architectural analysis
public struct AnalysisResult {
    public let id: UUID
    public let sourceFile: SourceFile
    public let defects: [ArchitecturalDefect]
    public let analyzedAt: Date
    public let analysisDuration: TimeInterval

    public init(
        sourceFile: SourceFile,
        defects: [ArchitecturalDefect],
        analysisDuration: TimeInterval
    ) {
        self.id = UUID()
        self.sourceFile = sourceFile
        self.defects = defects.sorted { $0.severity > $1.severity } // Sort by severity descending
        self.analyzedAt = Date()
        self.analysisDuration = analysisDuration
    }

    // MARK: - Computed Properties

    public var totalDefects: Int {
        defects.count
    }

    public var criticalDefects: [ArchitecturalDefect] {
        defects.filter { $0.severity == .critical }
    }

    public var highPriorityDefects: [ArchitecturalDefect] {
        defects.filter { $0.severity == .high }
    }

    public var defectsBySeverity: [Severity: [ArchitecturalDefect]] {
        Dictionary(grouping: defects) { $0.severity }
    }

    public var defectsByType: [DefectType: [ArchitecturalDefect]] {
        Dictionary(grouping: defects) { $0.type }
    }

    public var maintainabilityScore: Double {
        // Simple scoring algorithm: lower defect count = higher score
        let baseScore = 100.0
        let defectPenalty = Double(totalDefects) * 5.0
        let severityMultiplier = defects.reduce(0.0) { total, defect in
            switch defect.severity {
            case .low: return total + 1.0
            case .medium: return total + 2.0
            case .high: return total + 3.0
            case .critical: return total + 5.0
            }
        }

        return max(0.0, baseScore - defectPenalty - severityMultiplier)
    }

    public var hasIssues: Bool {
        !defects.isEmpty
    }

    // MARK: - Business Rules

    /// Determines if the analysis found any critical issues
    public var hasCriticalIssues: Bool {
        !criticalDefects.isEmpty
    }

    /// Determines if the codebase needs immediate refactoring
    public var requiresRefactoring: Bool {
        maintainabilityScore < 50.0
    }

    // MARK: - Presentation Helpers

    /// Returns formatted header information for display
    public var headerDescription: String {
        """
        🔍 Architectural Analysis Report
        \(String(repeating: "=", count: 60))
        📄 File: \(sourceFile.fileName)
        📍 Path: \(sourceFile.filePath)
        📊 Lines: \(sourceFile.lineCount)
        ⏱️  Analysis Time: \(String(format: "%.2f", analysisDuration))s

        """
    }
}