//
//  MarkdownFormatter.swift
//  ASTAnalyzer
//
//  Created on 2025-12-14.
//

import Foundation

/// Service for formatting analysis results into Markdown format
public final class MarkdownFormatter {

    public init() {}

    /// Formats a timestamp into a filesystem-safe string
    /// - Parameter date: The date to format
    /// - Returns: Formatted timestamp string
    public func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: date)
    }

    /// Formats a timestamp for display in reports (English locale)
    /// - Parameter date: The date to format
    /// - Returns: Formatted timestamp string
    public func formatDisplayTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateStyle = .full
        formatter.timeStyle = .full
        return formatter.string(from: date)
    }

    /// Sanitizes a filename for filesystem safety
    /// - Parameter filename: The filename to sanitize
    /// - Returns: Sanitized filename
    public func sanitizeFilename(_ filename: String) -> String {
        let invalidChars = CharacterSet(charactersIn: " \\/:*?\"<>|")
        return filename.components(separatedBy: invalidChars).joined(separator: "_")
    }

    /// Gets the description for a smell type
    /// - Parameter type: The defect type
    /// - Returns: Human-readable description
    public func getSmellTypeDescription(_ type: DefectType) -> String {
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