//
//  WeakenedModularityDetector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//
//

import Foundation
import SwiftSyntax

/// Detects weakened modularity (Weakened Modularity)
/// Based on DWM (Weakened Modularity):
/// - ModularityRatio = Cohesion/Coupling < threshold
public final class WeakenedModularityDetector: BaseDefectDetector {

    private let thresholds: Thresholds

    public init(thresholds: Thresholds = .academic) {
        self.thresholds = thresholds
        super.init(detectableDefects: [.weakenedModularity])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        // First pass: collect all types and their members
        let modularityAnalyzer = ModularityAnalyzer()
        modularityAnalyzer.walk(sourceFile)
        var analysis = modularityAnalyzer.analysis

        // Second pass: analyze dependencies by walking again
        let dependencyAnalyzer = DependencyAnalyzer(knownTypes: Set(analysis.types.keys))
        dependencyAnalyzer.walk(sourceFile)

        // Update analysis with dependencies
        for (typeName, deps) in dependencyAnalyzer.dependencies {
            analysis.types[typeName]!.dependencies = deps
        }

        // Calculate cohesion and coupling metrics
        let cohesion = calculateCohesion(analysis)
        let coupling = calculateCoupling(analysis)

        if coupling > 0 { // Avoid division by zero
            let modularityRatio = cohesion / coupling

            if modularityRatio < thresholds.structuralSmells.weakenedModularityRatio {
                let defect = ArchitecturalDefect(
                    type: .weakenedModularity,
                    severity: .medium,
                    message: "File has weakened modularity (cohesion/coupling ratio: \(String(format: "%.2f", modularityRatio))) - below threshold of \(thresholds.structuralSmells.weakenedModularityRatio)",
                    location: createLocation(filePath: filePath),
                    suggestion: "Improve cohesion by grouping related functionality or reduce coupling by introducing abstractions"
                )
                defects.append(defect)
            }
        }

        return defects
    }

    /// Calculates cohesion as the average similarity between types
    private func calculateCohesion(_ analysis: ModularityAnalysis) -> Double {
        guard analysis.types.count > 1 else { return 1.0 }

        var totalSimilarity = 0.0
        var pairCount = 0

        let typeNames = Array(analysis.types.keys)
        for i in 0..<typeNames.count {
            for j in (i+1)..<typeNames.count {
                let type1 = typeNames[i]
                let type2 = typeNames[j]

                let similarity = calculateTypeSimilarity(
                    analysis.types[type1]!,
                    analysis.types[type2]!
                )
                totalSimilarity += similarity
                pairCount += 1
            }
        }

        return pairCount > 0 ? totalSimilarity / Double(pairCount) : 1.0
    }

    /// Calculates coupling as the number of dependencies between types
    private func calculateCoupling(_ analysis: ModularityAnalysis) -> Double {
        var totalDependencies = 0

        for (_, typeInfo) in analysis.types {
            totalDependencies += typeInfo.dependencies.count
        }

        return Double(totalDependencies)
    }

    /// Calculates similarity between two types based on shared method/property names
    private func calculateTypeSimilarity(_ type1: TypeInfo, _ type2: TypeInfo) -> Double {
        let methods1 = Set(type1.methods)
        let methods2 = Set(type2.methods)
        let properties1 = Set(type1.properties)
        let properties2 = Set(type2.properties)

        let sharedMethods = methods1.intersection(methods2).count
        let sharedProperties = properties1.intersection(properties2).count

        let totalMethods = methods1.union(methods2).count
        let totalProperties = properties1.union(properties2).count

        let methodSimilarity = totalMethods > 0 ? Double(sharedMethods) / Double(totalMethods) : 0.0
        let propertySimilarity = totalProperties > 0 ? Double(sharedProperties) / Double(totalProperties) : 0.0

        // Weight methods and properties equally
        return (methodSimilarity + propertySimilarity) / 2.0
    }
}

// MARK: - Private Structures

private struct TypeInfo {
    var methods: [String] = []
    var properties: [String] = []
    var dependencies: Set<String> = []
}

private struct ModularityAnalysis {
    var types: [String: TypeInfo] = [:]
}

// MARK: - Private Visitors

private class DependencyAnalyzer: SyntaxVisitor {
    let knownTypes: Set<String>
    var dependencies: [String: Set<String>] = [:]
    var currentTypeContext: String?

    init(knownTypes: Set<String>) {
        self.knownTypes = knownTypes
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let typeName = node.name.text
        dependencies[typeName] = []
        currentTypeContext = typeName

        // Analyze property types for dependencies
        for member in node.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in varDecl.bindings {
                    if let typeAnnotation = binding.typeAnnotation {
                        let typeNameStr = typeAnnotation.type.description.trimmingCharacters(in: .whitespaces)
                        if knownTypes.contains(typeNameStr) && typeNameStr != typeName {
                            dependencies[typeName]!.insert(typeNameStr)
                        }
                    }
                }
            }
        }

        defer { currentTypeContext = nil }
        return .visitChildren
    }
}

private class ModularityAnalyzer: SyntaxVisitor {
    var analysis = ModularityAnalysis()

    init() {
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let typeName = node.name.text
        analysis.types[typeName] = TypeInfo()

        // Analyze members directly
        for member in node.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in varDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        analysis.types[typeName]!.properties.append(identifier.identifier.text)
                    }
                }
            } else if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                analysis.types[typeName]!.methods.append(funcDecl.name.text)
            } else if member.decl.is(InitializerDeclSyntax.self) {
                analysis.types[typeName]!.methods.append("init")
            }
        }

        return .visitChildren
    }
}