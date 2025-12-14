//
//  SmellInstance.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Smell instance structure based on Z notation specifications
//

import Foundation

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