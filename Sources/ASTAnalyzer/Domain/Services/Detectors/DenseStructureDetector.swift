//
//  DenseStructureDetector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//
//

import Foundation
import SwiftSyntax

/// Detects dense dependency structures (Dense Structure)
/// Based on DDS (Dense Structure):
/// - Average dependency graph degree > 0.5
public final class DenseStructureDetector: BaseDefectDetector {

    // Constants based on  et al. thresholds
    private let denseAvgDegreeThreshold = 0.5

    public init() {
        super.init(detectableDefects: [.denseStructure])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        let dependencyAnalyzer = DependencyAnalyzer()
        dependencyAnalyzer.walk(sourceFile)

        let analysis = dependencyAnalyzer.analysis

        // Calculate average degree (connections per type)
        let avgDegree = analysis.calculateAverageDegree()

        if avgDegree > denseAvgDegreeThreshold {
            let defect = ArchitecturalDefect(
                type: .denseStructure,
                severity: .high,
                message: "File has dense dependency structure (average degree: \(String(format: "%.2f"))) - exceeds threshold of \(denseAvgDegreeThreshold)",
                location: createLocation(filePath: filePath),
                suggestion: "Reduce coupling by introducing interfaces, breaking circular dependencies, or using dependency injection"
            )
            defects.append(defect)
        }

        return defects
    }
}

// MARK: - Private Structures

private struct DependencyAnalysis {
    var types: Set<String> = []
    var dependencies: [String: Set<String>] = [:] // type -> types it depends on

    mutating func addType(_ name: String) {
        types.insert(name)
        if dependencies[name] == nil {
            dependencies[name] = []
        }
    }

    mutating func addDependency(from sourceType: String, to targetType: String) {
        if types.contains(targetType) { // Only count internal dependencies
            dependencies[sourceType, default: []].insert(targetType)
        }
    }

    func calculateAverageDegree() -> Double {
        guard !types.isEmpty else { return 0.0 }

        let totalConnections = dependencies.values.reduce(0) { $0 + $1.count }
        return Double(totalConnections) / Double(types.count)
    }
}

// MARK: - Private Visitors

private class DependencyAnalyzer: SyntaxVisitor {
    var analysis = DependencyAnalysis()
    var currentTypeContext: String?

    init() {
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let typeName = node.name.text
        analysis.addType(typeName)
        currentTypeContext = typeName

        // Analyze inheritance dependencies
        if let inheritanceClause = node.inheritanceClause {
            for inheritedType in inheritanceClause.inheritedTypes {
                let inheritedTypeName = inheritedType.type.description.trimmingCharacters(in: .whitespaces)
                analysis.addDependency(from: typeName, to: inheritedTypeName)
            }
        }

        defer { currentTypeContext = nil }
        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let typeName = node.name.text
        analysis.addType(typeName)
        currentTypeContext = typeName
        defer { currentTypeContext = nil }
        return .visitChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        let typeName = node.name.text
        analysis.addType(typeName)
        currentTypeContext = typeName
        defer { currentTypeContext = nil }
        return .visitChildren
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        let typeName = node.name.text
        analysis.addType(typeName)
        currentTypeContext = typeName

        // Analyze protocol inheritance
        if let inheritanceClause = node.inheritanceClause {
            for inheritedType in inheritanceClause.inheritedTypes {
                let inheritedTypeName = inheritedType.type.description.trimmingCharacters(in: .whitespaces)
                analysis.addDependency(from: typeName, to: inheritedTypeName)
            }
        }

        defer { currentTypeContext = nil }
        return .visitChildren
    }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        let typeName = node.name.text
        analysis.addType(typeName)
        currentTypeContext = typeName
        defer { currentTypeContext = nil }
        return .visitChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        if let currentType = currentTypeContext {
            // Analyze property types
            for binding in node.bindings {
                if let typeAnnotation = binding.typeAnnotation {
                    let typeName = extractTypeName(from: typeAnnotation.type)
                    analysis.addDependency(from: currentType, to: typeName)
                }
            }
        }
        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        if let currentType = currentTypeContext {
            // Analyze parameter types and return type
            for parameter in node.signature.parameterClause.parameters {
                let typeName = extractTypeName(from: parameter.type)
                analysis.addDependency(from: currentType, to: typeName)
            }

            if let returnType = node.signature.returnClause?.type {
                let typeName = extractTypeName(from: returnType)
                analysis.addDependency(from: currentType, to: typeName)
            }
        }
        return .visitChildren
    }

    private func extractTypeName(from type: TypeSyntax) -> String {
        // Simple type name extraction - this could be improved
        let typeDescription = type.description.trimmingCharacters(in: .whitespaces)

        // Remove generic parameters for simplicity
        if let bracketIndex = typeDescription.firstIndex(of: "<") {
            return String(typeDescription[..<bracketIndex])
        }

        // Remove array/dictionary syntax
        if typeDescription.hasSuffix("]") {
            if let startIndex = typeDescription.firstIndex(of: "[") {
                return String(typeDescription[..<startIndex])
            }
        }

        return typeDescription
    }
}