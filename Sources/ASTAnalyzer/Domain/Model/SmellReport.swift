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

/**
 SmellInstance based on Z notation:
 ```
 SmellInstance == SmellType × (Class ∪ Method) × ℝ
 -- (тип запаха, элемент, серьезность 0..1)
 ```
 */
public struct SmellInstance: Codable, Equatable {
    /// The type of architectural defect
    public let type: DefectType

    /// The element (class or method) where the smell was detected
    public let element: CodeElement

    /// Severity score (0.0 = low impact, 1.0 = high impact)
    public let severity: Double

    /// Location information
    public let location: Location

    /// Detailed message describing the issue
    public let message: String

    /// Suggested fix for the issue
    public let suggestion: String

    public init(
        type: DefectType,
        element: CodeElement,
        severity: Double,
        location: Location,
        message: String,
        suggestion: String
    ) {
        self.type = type
        self.element = element
        self.severity = severity
        self.location = location
        self.message = message
        self.suggestion = suggestion
    }

    /// Severity as a human-readable string
    public var severityDescription: String {
        switch severity {
        case 0.0..<0.3: return "Low"
        case 0.3..<0.6: return "Medium"
        case 0.6..<0.8: return "High"
        default: return "Critical"
        }
    }

    /// Whether this smell requires immediate attention
    public var requiresImmediateAction: Bool {
        severity >= 0.8
    }

    /// JSON representation for export
    public var jsonRepresentation: [String: Any] {
        [
            "element": element.displayName,
            "severity": severity,
            "severityDescription": severityDescription,
            "location": [
                "filePath": location.filePath,
                "lineNumber": location.lineNumber as Any,
                "columnNumber": location.columnNumber as Any,
                "context": location.context as Any
            ],
            "message": message,
            "suggestion": suggestion,
            "requiresImmediateAction": requiresImmediateAction
        ]
    }
}

/// Represents a code element that can contain smells
public enum CodeElement: Codable, Equatable {
    case `class`(name: String)
    case method(className: String, methodName: String)
    case file(path: String)

    public var name: String {
        switch self {
        case .class(let name): return name
        case .method(_, let methodName): return methodName
        case .file(let path): return path
        }
    }

    public var displayName: String {
        switch self {
        case .class(let name): return "class \(name)"
        case .method(let className, let methodName): return "\(className).\(methodName)"
        case .file(let path): return path
        }
    }
}

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

/// Utility functions for smell report generation and analysis
public struct SmellReportUtilities {

    /// Generates recommendations based on detected smells
    public static func generateRecommendations(
        for smells: [SmellInstance],
        healthScore: Double
    ) -> [String] {
        var recommendations = [String]()

        if healthScore < 0.5 {
            recommendations.append("Overall code health is poor. Consider a comprehensive refactoring effort.")
        }

        // Group smells by type for targeted recommendations
        let smellsByType = Dictionary(grouping: smells) { $0.type }

        if let godClassCount = smellsByType[.godClass]?.count, godClassCount > 0 {
            recommendations.append("Found \(godClassCount) God Class(es). Break down large classes into smaller, focused components.")
        }

        if let longMethodCount = smellsByType[.longMethod]?.count, longMethodCount > 0 {
            recommendations.append("Found \(longMethodCount) Long Method(s). Extract methods into smaller, single-responsibility functions.")
        }

        if let multifacetedCount = smellsByType[.multifacetedAbstraction]?.count, multifacetedCount > 0 {
            recommendations.append("Found \(multifacetedCount) Multifaceted Abstraction(s). Split classes with multiple responsibilities.")
        }

        if let deficientEncapsulationCount = smellsByType[.deficientEncapsulation]?.count, deficientEncapsulationCount > 0 {
            recommendations.append("Found \(deficientEncapsulationCount) Deficient Encapsulation case(s). Improve data hiding and encapsulation.")
        }

        if let lazyClassCount = smellsByType[.lazyClass]?.count, lazyClassCount > 0 {
            recommendations.append("Found \(lazyClassCount) Lazy Class(es). Remove unnecessary classes or merge them with related classes.")
        }

        if let dataClassCount = smellsByType[.dataClass]?.count, dataClassCount > 0 {
            recommendations.append("Found \(dataClassCount) Data Class(es). Add behavior to data-only classes or make them immutable value types.")
        }

        if recommendations.isEmpty && healthScore >= 0.8 {
            recommendations.append("Codebase appears well-structured. Continue following clean architecture principles.")
        }

        return recommendations
    }

    /// Calculates health score based on detected smells
    public static func calculateHealthScore(
        smells: [SmellInstance],
        totalClasses: Int,
        totalMethods: Int
    ) -> Double {
        if smells.isEmpty {
            return 1.0
        }

        // Base health score
        var healthScore = 1.0

        // Penalty for each smell based on severity
        for smell in smells {
            let penalty = smell.severity * 0.05 // 5% penalty per smell point
            healthScore -= penalty
        }

        // Additional penalty for smell density
        let smellDensity = Double(smells.count) / Double(max(1, totalClasses + totalMethods))
        healthScore -= smellDensity * 0.3

        // Ensure health score stays within bounds
        return max(0.0, min(1.0, healthScore))
    }

    /// Get description for a smell type
    public static func getSmellTypeDescription(_ type: DefectType) -> String {
        switch type {
        case .godClass:
            return "A class that knows too much or does too much"
        case .massiveViewController:
            return "A view controller that has grown too large and complex"
        case .multifacetedAbstraction:
            return "An abstraction that has multiple responsibilities"
        case .unnecessaryAbstraction:
            return "An abstraction that doesn't add value or hide complexity"
        case .imperativeAbstraction:
            return "An abstraction that exposes implementation details"
        case .missingAbstraction:
            return "Missing abstraction where one would simplify the code"
        case .insufficientModularization:
            return "Code that should be split into separate modules"
        case .duplicateBlock:
            return "Duplicated code blocks"
        case .brokenHierarchy:
            return "Inheritance hierarchy that violates Liskov Substitution Principle"
        case .unstructuredModule:
            return "A module without clear structure"
        case .denseStructure:
            return "Overly complex code structure"
        case .deficientEncapsulation:
            return "Poor encapsulation of data and behavior"
        case .weakenedModularity:
            return "Module boundaries that are not well-defined"
        case .longMethod:
            return "A method that is too long"
        case .lazyClass:
            return "A class that does too little to justify its existence"
        case .dataClass:
            return "A class that only holds data without behavior"
        case .messageChain:
            return "A chain of method calls to access nested objects"
        case .featureEnvy:
            return "A method that uses more features of another class than its own"
        case .cyclicDependency:
            return "Circular dependencies between modules or classes"
        }
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