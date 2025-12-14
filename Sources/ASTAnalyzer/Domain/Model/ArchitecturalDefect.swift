//
//  ArchitecturalDefect.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//

import Foundation

/// Represents an architectural defect detected in Swift code
public struct ArchitecturalDefect: Equatable, Hashable {
    public let id: UUID
    public let type: DefectType
    public let severity: Severity
    public let message: String
    public let location: Location
    public let suggestion: String
    public let detectedAt: Date

    public init(
        type: DefectType,
        severity: Severity,
        message: String,
        location: Location,
        suggestion: String
    ) {
        self.id = UUID()
        self.type = type
        self.severity = severity
        self.message = message
        self.location = location
        self.suggestion = suggestion
        self.detectedAt = Date()
    }

    // MARK: - Business Rules

    /// Determines if this defect requires immediate attention
    public var requiresImmediateAction: Bool {
        severity == .critical
    }

    /// Determines if this defect affects system maintainability
    public var affectsMaintainability: Bool {
        [.multifacetedAbstraction, .insufficientModularization, .denseStructure, .imperativeAbstraction, .brokenHierarchy].contains(type)
    }
}

/// Types of architectural defects that can be detected
public enum DefectType: String, CaseIterable, Codable {
    case godClass = "God Class"
    case massiveViewController = "Massive View Controller"
    case multifacetedAbstraction = "Multifaceted Abstraction"
    case unnecessaryAbstraction = "Unnecessary Abstraction"
    case imperativeAbstraction = "Imperative Abstraction"
    case missingAbstraction = "Missing Abstraction"
    case insufficientModularization = "Insufficient Modularization"
    case duplicateBlock = "Duplicate Block"
    case brokenHierarchy = "Broken Hierarchy"
    case unstructuredModule = "Unstructured Module"
    case denseStructure = "Dense Structure"
    case deficientEncapsulation = "Deficient Encapsulation"
    case weakenedModularity = "Weakened Modularity"
    case longMethod = "Long Method"
    case lazyClass = "Lazy Class"
    case dataClass = "Data Class"
    case messageChain = "Message Chain"
    case featureEnvy = "Feature Envy"
    case cyclicDependency = "Cyclic Dependency"
}

/// Severity levels for architectural defects
public enum Severity: String, CaseIterable, Comparable {
    case low
    case medium
    case high
    case critical

    public static func < (lhs: Severity, rhs: Severity) -> Bool {
        let order: [Severity] = [.low, .medium, .high, .critical]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

/// Represents the location where a defect was detected
public struct Location: Equatable, Hashable, Codable {
    public let filePath: String
    public let lineNumber: Int?
    public let columnNumber: Int?
    public let context: String?

    public init(
        filePath: String,
        lineNumber: Int? = nil,
        columnNumber: Int? = nil,
        context: String? = nil
    ) {
        self.filePath = filePath
        self.lineNumber = lineNumber
        self.columnNumber = columnNumber
        self.context = context
    }

    public var description: String {
        var components = [filePath]
        if let line = lineNumber {
            components.append("line \(line)")
            if let column = columnNumber {
                components.append("column \(column)")
            }
        }
        if let context = context {
            components.append("(\(context))")
        }
        return components.joined(separator: " ")
    }
}