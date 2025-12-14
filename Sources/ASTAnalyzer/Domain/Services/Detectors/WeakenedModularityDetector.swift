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
/// - ModularityRatio = Cohesion/Coupling < 1
public final class WeakenedModularityDetector: BaseDefectDetector {

    // Constants based on  et al. thresholds
    private let modularityRatioThreshold = 1.0

    public init() {
        super.init(detectableDefects: [.weakenedModularity])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        let modularityAnalyzer = ModularityAnalyzer()
        modularityAnalyzer.walk(sourceFile)

        let analysis = modularityAnalyzer.analysis

        // Calculate cohesion and coupling metrics
        let cohesion = calculateCohesion(analysis)
        let coupling = calculateCoupling(analysis)

        if coupling > 0 { // Avoid division by zero
            let modularityRatio = cohesion / coupling

            if modularityRatio < modularityRatioThreshold {
                let defect = ArchitecturalDefect(
                    type: .weakenedModularity,
                    severity: .medium,
                    message: "File has weakened modularity (cohesion/coupling ratio: \(String(format: "%.2f"))) - below threshold of \(modularityRatioThreshold)",
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

private class ModularityAnalyzer: SyntaxVisitor {
    var analysis = ModularityAnalysis()
    var currentTypeContext: String?

    init() {
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let typeName = node.name.text
        analysis.types[typeName] = TypeInfo()
        currentTypeContext = typeName
        defer { currentTypeContext = nil }
        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let typeName = node.name.text
        analysis.types[typeName] = TypeInfo()
        currentTypeContext = typeName
        defer { currentTypeContext = nil }
        return .visitChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        let typeName = node.name.text
        analysis.types[typeName] = TypeInfo()
        currentTypeContext = typeName
        defer { currentTypeContext = nil }
        return .visitChildren
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        let typeName = node.name.text
        analysis.types[typeName] = TypeInfo()
        currentTypeContext = typeName
        defer { currentTypeContext = nil }
        return .visitChildren
    }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        let typeName = node.name.text
        analysis.types[typeName] = TypeInfo()
        currentTypeContext = typeName
        defer { currentTypeContext = nil }
        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        if let currentType = currentTypeContext {
            analysis.types[currentType]!.methods.append(node.name.text)
        }
        return .visitChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        if let currentType = currentTypeContext {
            for binding in node.bindings {
                if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                    analysis.types[currentType]!.properties.append(identifier.identifier.text)
                }
            }
        }
        return .visitChildren
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        if let currentType = currentTypeContext {
            let referencedName = node.baseName.text
            // If it's referencing another type in our analysis, count it as a dependency
            if analysis.types[referencedName] != nil && referencedName != currentType {
                analysis.types[currentType]!.dependencies.insert(referencedName)
            }
        }
        return .visitChildren
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        if let currentType = currentTypeContext {
            // Analyze member access to detect dependencies
            if let base = node.base?.as(DeclReferenceExprSyntax.self) {
                let baseName = base.baseName.text
                if analysis.types[baseName] != nil && baseName != currentType {
                    analysis.types[currentType]!.dependencies.insert(baseName)
                }
            }
        }
        return .visitChildren
    }
}