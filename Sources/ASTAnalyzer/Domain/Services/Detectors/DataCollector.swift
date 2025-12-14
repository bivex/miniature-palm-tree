//
//  DataCollector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Protocol for collecting data during AST traversal to separate imperative operations
//

import SwiftSyntax

/// Protocol for collecting data during AST traversal
public protocol DataCollector {
    associatedtype CollectedData

    /// Collect data from a function declaration
    func collectFunction(_ node: FunctionDeclSyntax) -> CollectedData?

    /// Collect data from an initializer declaration
    func collectInitializer(_ node: InitializerDeclSyntax) -> CollectedData?

    /// Collect data from a for statement
    func collectForStatement(_ node: ForStmtSyntax) -> CollectedData?

    /// Collect data from a while statement
    func collectWhileStatement(_ node: WhileStmtSyntax) -> CollectedData?

    /// Get all collected data
    func getCollectedData() -> [CollectedData]
}

/// Implementation of DataCollector for code blocks
public final class CodeBlockDataCollector: DataCollector {
    public typealias CollectedData = CodeBlock

    private var blocks: [CodeBlock] = []

    public init() {}

    public func collectFunction(_ node: FunctionDeclSyntax) -> CodeBlock? {
        guard let body = node.body else { return nil }
        return DuplicateBlockDetector.createCodeBlockFromSyntax(
            body: body,
            type: .function,
            name: node.name.text,
            minTokens: 10
        )
    }

    public func collectInitializer(_ node: InitializerDeclSyntax) -> CodeBlock? {
        guard let body = node.body else { return nil }
        return DuplicateBlockDetector.createCodeBlockFromSyntax(
            body: body,
            type: .initializer,
            name: "init",
            minTokens: 10
        )
    }

    public func collectForStatement(_ node: ForStmtSyntax) -> CodeBlock? {
        DuplicateBlockDetector.createCodeBlockFromSyntax(
            body: node.body,
            type: .controlFlow,
            name: "for-loop",
            minTokens: 20
        )
    }

    public func collectWhileStatement(_ node: WhileStmtSyntax) -> CodeBlock? {
        DuplicateBlockDetector.createCodeBlockFromSyntax(
            body: node.body,
            type: .controlFlow,
            name: "while-loop",
            minTokens: 20
        )
    }

    public func getCollectedData() -> [CodeBlock] {
        return blocks
    }

    /// Add a collected code block to the collection
    public func addBlock(_ block: CodeBlock) {
        blocks.append(block)
    }
}