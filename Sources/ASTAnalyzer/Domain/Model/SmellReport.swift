//
//  SmellReport.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Smell report structure based on Z notation specifications
//

import Foundation

/**
 SmellReport based on Z notation:
 ```
 SmellReport ::= ⟨
   totalSmells : ℕ,
   smellsByType : SmellType → ℕ,
   smellsByClass : Class → ℙ SmellInstance,
   criticalSmells : ℙ SmellInstance,
   healthScore : ℝ,
   recommendations : seq String
 ⟩
 ```
 */
public struct SmellReport: Codable {
    /// Total number of architectural defects detected
    public let totalSmells: Int

    /// Count of smells grouped by type
    public let smellsByType: [DefectType: Int]

    /// Smells grouped by class (if applicable)
    public let smellsByClass: [String: [SmellInstance]]

    /// Critical severity smells that require immediate attention
    public let criticalSmells: [SmellInstance]

    /// Overall project health score (0.0 = very unhealthy, 1.0 = very healthy)
    public let healthScore: Double

    /// Recommended actions to improve code quality
    public let recommendations: [String]

    /// Analysis metadata
    public let metadata: AnalysisMetadata

    public init(
        totalSmells: Int,
        smellsByType: [DefectType: Int],
        smellsByClass: [String: [SmellInstance]],
        criticalSmells: [SmellInstance],
        healthScore: Double,
        recommendations: [String],
        metadata: AnalysisMetadata
    ) {
        self.totalSmells = totalSmells
        self.smellsByType = smellsByType
        self.smellsByClass = smellsByClass
        self.criticalSmells = criticalSmells
        self.healthScore = healthScore
        self.recommendations = recommendations
        self.metadata = metadata
    }

    /// Creates an empty report for projects with no issues
    public static func empty(metadata: AnalysisMetadata) -> SmellReport {
        SmellReport(
            totalSmells: 0,
            smellsByType: [:],
            smellsByClass: [:],
            criticalSmells: [],
            healthScore: 1.0,
            recommendations: ["Your codebase appears to be well-structured with no architectural defects detected."],
            metadata: metadata
        )
    }

    /// Health score as a percentage string
    public var healthScorePercentage: String {
        String(format: "%.1f%%", healthScore * 100)
    }

    /// Health status description
    public var healthStatus: String {
        switch healthScore {
        case 0.8...1.0: return "Excellent"
        case 0.6..<0.8: return "Good"
        case 0.4..<0.6: return "Fair"
        case 0.2..<0.4: return "Poor"
        default: return "Critical"
        }
    }

    /// Whether the project needs immediate refactoring attention
    public var requiresRefactoring: Bool {
        healthScore < 0.5 || !criticalSmells.isEmpty
    }

    /// JSON representation for export
    public var jsonRepresentation: [String: Any] {
        [
            "summary": [
                "totalSmells": totalSmells,
                "healthScore": healthScore,
                "healthScorePercentage": healthScorePercentage,
                "healthStatus": healthStatus,
                "requiresRefactoring": requiresRefactoring,
                "criticalSmellsCount": criticalSmells.count
            ],
            "smellsByType": smellsByType.map { (type, count) in
                [
                    "type": type.rawValue,
                    "count": count,
                    "description": SmellReport.getSmellTypeDescription(type)
                ]
            },
            "recommendations": recommendations,
            "metadata": [
                "timestamp": metadata.timestamp.ISO8601Format(),
                "duration": metadata.duration,
                "durationDescription": metadata.durationDescription,
                "filesAnalyzed": metadata.filesAnalyzed,
                "classesAnalyzed": metadata.classesAnalyzed,
                "methodsAnalyzed": metadata.methodsAnalyzed,
                "version": metadata.version,
                "thresholds": [
                    "godClassLOC": metadata.thresholds.classSmells.godClassLOC,
                    "longMethodLOC": metadata.thresholds.methodSmells.longMethodLOC,
                    "lazyClassNOM": metadata.thresholds.classSmells.lazyClassNOM,
                    "lazyClassNOF": metadata.thresholds.classSmells.lazyClassNOF,
                    "deficientEncapsulationWOA": metadata.thresholds.classSmells.deficientEncapsulationWOA,
                    "multifacetedAbstractionLCOM": metadata.thresholds.classSmells.mfaLCOM
                ]
            ]
        ]
    }
}

// MARK: - Report Generation

extension SmellReport {
    /// Generates recommendations based on detected smells using utility functions
    public static func generateRecommendations(
        for smells: [SmellInstance],
        healthScore: Double
    ) -> [String] {
        SmellReportUtilities.generateRecommendations(for: smells, healthScore: healthScore)
    }

    /// Calculates health score based on detected smells using utility functions
    public static func calculateHealthScore(
        smells: [SmellInstance],
        totalClasses: Int,
        totalMethods: Int
    ) -> Double {
        SmellReportUtilities.calculateHealthScore(smells: smells, totalClasses: totalClasses, totalMethods: totalMethods)
    }

    /// Get description for a smell type using utility functions
    public static func getSmellTypeDescription(_ type: DefectType) -> String {
        SmellReportUtilities.getSmellTypeDescription(type)
    }
}