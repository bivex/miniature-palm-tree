//
//  CodeBlockVisitor.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Pure AST visitor that delegates data collection to separate collectors
//

import SwiftSyntax

/// Pure AST visitor for code block extraction that delegates imperative operations to collectors
public final class CodeBlockVisitor: SyntaxVisitor {

    private let dataCollector: CodeBlockDataCollector

    public init(dataCollector: CodeBlockDataCollector) {
        self.dataCollector = dataCollector
        super.init(viewMode: .sourceAccurate)
    }

    public override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        if let block = dataCollector.collectFunction(node) {
            dataCollector.addBlock(block)
        }
        return .visitChildren
    }

    public override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        if let block = dataCollector.collectInitializer(node) {
            dataCollector.addBlock(block)
        }
        return .visitChildren
    }

    public override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        if let block = dataCollector.collectForStatement(node) {
            dataCollector.addBlock(block)
        }
        return .visitChildren
    }

    public override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        if let block = dataCollector.collectWhileStatement(node) {
            dataCollector.addBlock(block)
        }
        return .visitChildren
    }
}