//
//  BrokenHierarchyDetector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//
//

import Foundation
import SwiftSyntax

/// Detects broken inheritance hierarchies (Broken Hierarchy)
/// Based on DBH (Broken Hierarchy):
/// - Inherited class defined in different module
public final class BrokenHierarchyDetector: BaseDefectDetector {

    public init() {
        super.init(detectableDefects: [.brokenHierarchy])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        let hierarchyVisitor = InheritanceHierarchyVisitor()
        hierarchyVisitor.walk(sourceFile)

        // Check for classes inheriting from external types
        for inheritance in hierarchyVisitor.inheritances {
            if isExternalInheritance(inheritance.inheritedType) {
                let defect = ArchitecturalDefect(
                    type: .brokenHierarchy,
                    severity: .high,
                    message: "Class '\(inheritance.className)' inherits from external type '\(inheritance.inheritedType)' - consider composition over inheritance",
                    location: createLocation(filePath: filePath, context: "class \(inheritance.className)"),
                    suggestion: "Use composition instead of inheritance for external dependencies, or ensure base class is in the same module"
                )
                defects.append(defect)
            }
        }

        // Check for protocol inheritance across modules (if detectable)
        for protocolInheritance in hierarchyVisitor.protocolInheritances {
            if isCrossModuleProtocolInheritance(protocolInheritance) {
                let defect = ArchitecturalDefect(
                    type: .brokenHierarchy,
                    severity: .medium,
                    message: "Protocol '\(protocolInheritance.protocolName)' inherits from protocols in different contexts",
                    location: createLocation(filePath: filePath, context: "protocol \(protocolInheritance.protocolName)"),
                    suggestion: "Consider keeping related protocols in the same module or use composition"
                )
                defects.append(defect)
            }
        }

        return defects
    }

    /// Determines if inheritance is from an external type (not defined in this file)
    private func isExternalInheritance(_ typeName: String) -> Bool {
        // Common external types that indicate broken hierarchy
        let externalTypePrefixes = [
            "UI", "NS", "CF", "CG", "CA", // Apple frameworks
            "Foundation.", "UIKit.", "SwiftUI.", // Swift frameworks
            "ObservableObject", "Identifiable", // SwiftUI protocols
            "NSObject", "NSError" // Foundation types
        ]

        // Check if type name starts with external prefixes
        for prefix in externalTypePrefixes {
            if typeName.hasPrefix(prefix) || typeName.contains(".\(prefix)") {
                return true
            }
        }

        // Check for generic external types
        if typeName.contains("UIViewController") ||
           typeName.contains("UITableView") ||
           typeName.contains("UICollectionView") ||
           typeName.contains("NSManagedObject") {
            return true
        }

        return false
    }

    /// Checks if protocol inheritance crosses module boundaries
    private func isCrossModuleProtocolInheritance(_ inheritance: ProtocolInheritance) -> Bool {
        // For now, flag protocols that inherit from multiple protocols
        // as potentially problematic if they mix different domains
        if inheritance.inheritedProtocols.count > 2 {
            return true
        }

        // Check if protocols come from different domains
        let domains = inheritance.inheritedProtocols.map { inferDomain($0) }
        let uniqueDomains = Set(domains)
        return uniqueDomains.count > 1
    }

    private func inferDomain(_ protocolName: String) -> String {
        let lowerName = protocolName.lowercased()

        if lowerName.contains("ui") || lowerName.contains("view") || lowerName.contains("display") {
            return "UI"
        } else if lowerName.contains("data") || lowerName.contains("model") || lowerName.contains("entity") {
            return "Data"
        } else if lowerName.contains("service") || lowerName.contains("manager") || lowerName.contains("handler") {
            return "Service"
        } else if lowerName.contains("delegate") || lowerName.contains("observer") {
            return "Observer"
        }

        return "General"
    }
}

// MARK: - Private Structures

private struct ClassInheritance {
    let className: String
    let inheritedType: String
}

private struct ProtocolInheritance {
    let protocolName: String
    let inheritedProtocols: [String]
}

// MARK: - Private Visitors

private class InheritanceHierarchyVisitor: SyntaxVisitor {
    var inheritances: [ClassInheritance] = []
    var protocolInheritances: [ProtocolInheritance] = []

    init() {
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        if let inheritanceClause = node.inheritanceClause {
            for inheritedType in inheritanceClause.inheritedTypes {
                let typeName = inheritedType.type.description.trimmingCharacters(in: .whitespaces)
                inheritances.append(ClassInheritance(
                    className: node.name.text,
                    inheritedType: typeName
                ))
            }
        }
        return .visitChildren
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        if let inheritanceClause = node.inheritanceClause {
            let inheritedProtocols = inheritanceClause.inheritedTypes.map {
                $0.type.description.trimmingCharacters(in: .whitespaces)
            }
            if !inheritedProtocols.isEmpty {
                protocolInheritances.append(ProtocolInheritance(
                    protocolName: node.name.text,
                    inheritedProtocols: inheritedProtocols
                ))
            }
        }
        return .visitChildren
    }
}