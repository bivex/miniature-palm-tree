//
//  UnstructuredModuleDetector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//
//

import Foundation
import SwiftSyntax

/// Detects unstructured modules (Unstructured Module)
/// Based on DUM (Unstructured Module):
/// - Module structure violations or unexpected file/folder count > threshold
public final class UnstructuredModuleDetector: BaseDefectDetector {

    private let thresholds: Thresholds

    public init(thresholds: Thresholds = .academic) {
        self.thresholds = thresholds
        super.init(detectableDefects: [.unstructuredModule])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        let structureAnalyzer = FileStructureAnalyzer()
        structureAnalyzer.walk(sourceFile)

        let analysis = structureAnalyzer.analysis

        // Check for mixed architectural layers (MVC violation)
        if analysis.hasMixedLayers {
            let layers = analysis.layers.joined(separator: ", ")
            let defect = ArchitecturalDefect(
                type: .unstructuredModule,
                severity: .high,
                message: "File contains mixed architectural layers (\(layers)) - violates separation of concerns",
                location: createLocation(filePath: filePath),
                suggestion: "Separate concerns into different files/layers (e.g., Model, View, Controller)"
            )
            defects.append(defect)
        }

        // Check for too many different element types (unexpected elements)
        let unexpectedElements = countUnexpectedElements(analysis)
        if unexpectedElements > thresholds.moduleSmells.unstructuredModuleMaxElements {
            let defect = ArchitecturalDefect(
                type: .unstructuredModule,
                severity: .medium,
                message: "File contains \(unexpectedElements) different types of elements - consider splitting into focused modules",
                location: createLocation(filePath: filePath),
                suggestion: "Break down into smaller, focused files with single responsibilities"
            )
            defects.append(defect)
        }

        return defects
    }

    private func countUnexpectedElements(_ analysis: StructureAnalysis) -> Int {
        var count = 0

        // Count different categories of elements
        if analysis.hasClasses { count += 1 }
        if analysis.hasStructs { count += 1 }
        if analysis.hasEnums { count += 1 }
        if analysis.hasProtocols { count += 1 }
        if analysis.hasActors { count += 1 }
        if analysis.hasExtensions { count += 1 }
        if analysis.hasGlobalFunctions { count += 1 }
        if analysis.hasGlobalVariables { count += 1 }

        return count
    }
}

// MARK: - Private Structures

private struct StructureAnalysis {
    var hasClasses = false
    var hasStructs = false
    var hasEnums = false
    var hasProtocols = false
    var hasActors = false
    var hasExtensions = false
    var hasGlobalFunctions = false
    var hasGlobalVariables = false

    var layers: Set<String> = []

    var hasMixedLayers: Bool {
        return layers.count > 2 // More than 2 layers indicate mixing
    }
}

// MARK: - Private Visitors

private class FileStructureAnalyzer: SyntaxVisitor {
    var analysis = StructureAnalysis()

    init() {
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        analysis.hasClasses = true
        analysis.layers.insert(inferLayer(from: node))
        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        analysis.hasStructs = true
        analysis.layers.insert(inferLayer(from: node))
        return .visitChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        analysis.hasEnums = true
        analysis.layers.insert(inferLayer(from: node))
        return .visitChildren
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        analysis.hasProtocols = true
        analysis.layers.insert(inferLayer(from: node))
        return .visitChildren
    }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        analysis.hasActors = true
        analysis.layers.insert(inferLayer(from: node))
        return .visitChildren
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        analysis.hasExtensions = true
        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        // Check if it's a global function (not inside a type)
        if !isInsideTypeDeclaration(node) {
            analysis.hasGlobalFunctions = true
            analysis.layers.insert("Utility")
        }
        return .visitChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        // Check if it's a global variable
        if !isInsideTypeDeclaration(node) {
            analysis.hasGlobalVariables = true
            analysis.layers.insert("Data")
        }
        return .visitChildren
    }

    private func inferLayer(from node: some DeclSyntaxProtocol & NamedDeclSyntax) -> String {
        let name = node.name.text.lowercased()

        if isViewLayer(name) { return "View" }
        if isBusinessLayer(name) { return "Business" }
        if isModelLayer(name) { return "Model" }
        if isNetworkLayer(name) { return "Network" }

        return "General"
    }

    private func isViewLayer(_ name: String) -> Bool {
        let viewKeywords = ["view", "controller", "ui", "display", "screen", "cell"]
        return viewKeywords.contains { name.contains($0) }
    }

    private func isBusinessLayer(_ name: String) -> Bool {
        let businessKeywords = ["service", "manager", "handler", "processor", "coordinator"]
        return businessKeywords.contains { name.contains($0) }
    }

    private func isModelLayer(_ name: String) -> Bool {
        let modelKeywords = ["model", "entity", "dto", "repository", "data"]
        return modelKeywords.contains { name.contains($0) }
    }

    private func isNetworkLayer(_ name: String) -> Bool {
        let networkKeywords = ["api", "network", "http", "client", "request"]
        return networkKeywords.contains { name.contains($0) }
    }

    private func isInsideTypeDeclaration(_ decl: some SyntaxProtocol) -> Bool {
        var current: Syntax? = decl.parent

        while let parent = current {
            if parent.is(ClassDeclSyntax.self) ||
               parent.is(StructDeclSyntax.self) ||
               parent.is(EnumDeclSyntax.self) ||
               parent.is(ActorDeclSyntax.self) ||
               parent.is(ProtocolDeclSyntax.self) {
                return true
            }
            current = parent.parent
        }

        return false
    }
}

// MARK: - Helper Protocol

private protocol NamedDeclSyntax {
    var name: TokenSyntax { get }
}

extension ClassDeclSyntax: NamedDeclSyntax {}
extension StructDeclSyntax: NamedDeclSyntax {}
extension EnumDeclSyntax: NamedDeclSyntax {}
extension ProtocolDeclSyntax: NamedDeclSyntax {}
extension ActorDeclSyntax: NamedDeclSyntax {}