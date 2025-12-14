//
//  FileStructureAnalyzer.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Visitor for analyzing file structure in Swift code
//

import Foundation
import SwiftSyntax

/// Visitor that analyzes Swift file structure for architectural issues
final class FileStructureAnalyzer: SyntaxVisitor {
    private let analysisHandler: StructureAnalysisHandler

    var analysis: StructureAnalysis { analysisHandler.result }

    init(analysisHandler: StructureAnalysisHandler = DefaultStructureAnalysisHandler()) {
        self.analysisHandler = analysisHandler
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        analysisHandler.recordClassFound()
        analysisHandler.recordLayer(inferLayer(from: node))
        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        analysisHandler.recordStructFound()
        analysisHandler.recordLayer(inferLayer(from: node))
        return .visitChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        analysisHandler.recordEnumFound()
        analysisHandler.recordLayer(inferLayer(from: node))
        return .visitChildren
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        analysisHandler.recordProtocolFound()
        analysisHandler.recordLayer(inferLayer(from: node))
        return .visitChildren
    }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        analysisHandler.recordActorFound()
        analysisHandler.recordLayer(inferLayer(from: node))
        return .visitChildren
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        analysisHandler.recordExtensionFound()
        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        // Check if it's a global function (not inside a type)
        if !isInsideTypeDeclaration(node) {
            analysisHandler.recordGlobalFunctionFound()
        }
        return .visitChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        // Check if it's a global variable
        if !isInsideTypeDeclaration(node) {
            analysisHandler.recordGlobalVariableFound()
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