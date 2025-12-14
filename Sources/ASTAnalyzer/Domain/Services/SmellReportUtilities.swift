//
//  SmellReportUtilities.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Utility functions for smell report generation and analysis
//

import Foundation

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