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
/// - Average dependency graph degree > threshold
public final class DenseStructureDetector: BaseDefectDetector {

    private let thresholds: Thresholds

    public init(thresholds: Thresholds = .academic) {
        self.thresholds = thresholds
        super.init(detectableDefects: [.denseStructure])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        let dependencyAnalyzer = DependencyAnalyzer()
        dependencyAnalyzer.walk(sourceFile)

        let analysis = dependencyAnalyzer.analysis

        // Calculate average degree (connections per type)
        let avgDegree = analysis.calculateAverageDegree()

        if avgDegree > thresholds.structuralSmells.denseStructureDegree {
            let defect = ArchitecturalDefect(
                type: .denseStructure,
                severity: .high,
                message: "File has dense dependency structure (average degree: \(String(format: "%.2f", avgDegree))) - exceeds threshold of \(thresholds.structuralSmells.denseStructureDegree)",
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
        // Count all dependencies, but only if target type is a known type in our analysis
        // We add all types first, then dependencies
        dependencies[sourceType, default: []].insert(targetType)
    }

    func calculateAverageDegree() -> Double {
        guard !types.isEmpty else { return 0.0 }

        var totalConnections = 0
        for (sourceType, deps) in dependencies {
            if types.contains(sourceType) { // Only count connections from known types
                for dep in deps {
                    if types.contains(dep) { // Only count connections to known types
                        totalConnections += 1
                    }
                }
            }
        }

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
                let inheritedTypeDescription = inheritedType.type.description
                let inheritedTypeName = inheritedTypeDescription.trimmingCharacters(in: .whitespaces)
                analysis.addDependency(from: typeName, to: inheritedTypeName)
            }
        }

        // Analyze member properties
        for member in node.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in varDecl.bindings {
                    if let typeAnnotation = binding.typeAnnotation {
                        let dependencyTypeName = extractTypeName(from: typeAnnotation.type)
                        analysis.addDependency(from: typeName, to: dependencyTypeName)
                    }
                }
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
                let inheritedTypeDescription = inheritedType.type.description
                let inheritedTypeName = inheritedTypeDescription.trimmingCharacters(in: .whitespaces)
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
        // Properties are now handled in ClassDeclSyntax visitor
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
        let typeDescription = type.description
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

        return typeDescription.trimmingCharacters(in: .whitespaces)
    }
}