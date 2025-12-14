//
//  AnalysisCoordinator.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//

import Foundation
import SwiftSyntax

/// Domain service responsible for coordinating architectural analysis
public final class AnalysisCoordinator {

    private let defectDetectors: [DefectDetector]

    public init(defectDetectors: [DefectDetector]) {
        self.defectDetectors = defectDetectors
    }

    /// Analyzes the given source file for architectural defects
    /// - Parameters:
    ///   - sourceFile: The parsed Swift source file
    ///   - filePath: Path to the source file
    /// - Returns: Analysis result containing all detected defects
    public func analyze(sourceFile: SourceFileSyntax, filePath: String) -> AnalysisResult {
        let startTime = Date()

        // Validate input
        let sourceFileEntity = SourceFile(filePath: filePath, content: sourceFile.description)
        try? sourceFileEntity.validate()

        // Run all detectors
        var allDefects: [ArchitecturalDefect] = []
        for detector in defectDetectors {
            let defects = detector.detectDefects(in: sourceFile, filePath: filePath)
            allDefects.append(contentsOf: defects)
        }

        // Remove duplicates (same defect detected by multiple detectors)
        let uniqueDefects = removeDuplicateDefects(allDefects)

        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)

        return AnalysisResult(
            sourceFile: sourceFileEntity,
            defects: uniqueDefects,
            analysisDuration: duration
        )
    }

    // MARK: - Private Methods

    private func removeDuplicateDefects(_ defects: [ArchitecturalDefect]) -> [ArchitecturalDefect] {
        var seen = Set<String>()
        return defects.filter { defect in
            let key = "\(defect.type.rawValue)|\(defect.location.filePath)|\(defect.location.context ?? "")"
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }
    }
}