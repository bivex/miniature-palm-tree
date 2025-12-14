//
//  MessageChainDetector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Detects Message Chain code smell based on Z notation specification
//

import Foundation
import SwiftSyntax

/// Detects Message Chain smell
/// Based on Z notation:
/// ```
/// MessageChainDetector
/// ├─ MessageChain ::= seq MethodCall
/// ├─ MethodCall == Method × Class
/// ├─ messageChains : Method → ℙ MessageChain
/// ├─ maxChainLength : Method → ℕ
/// ├─ hasMessageChain : Method → 𝔹
/// └─ ∀ m : Method • hasMessageChain(m) ⇔ maxChainLength(m) > θ_ChainLength
/// ```
public final class MessageChainDetector: BaseDefectDetector {

    private let thresholds: Thresholds

    public init(thresholds: Thresholds = .academic) {
        self.thresholds = thresholds
        super.init(detectableDefects: [.messageChain])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        let sourceText = sourceFile.description
        let visitor = MessageChainVisitor()
        visitor.walk(sourceFile)

        // Analyze each method for message chains
        for method in visitor.methods {
            let chains = detectMessageChains(in: method.node)

            if !chains.isEmpty {
                let maxChainLength = chains.map { $0.length }.max() ?? 0
                if maxChainLength >= thresholds.structuralSmells.messageChainLength {
                    let lineNumber = calculateLineNumber(from: method.node.position, in: sourceText)
                    let defect = ArchitecturalDefect(
                        type: .messageChain,
                        severity: calculateSeverity(for: maxChainLength),
                        message: "Method '\(method.name)' contains message chain of length \(maxChainLength) (threshold: \(thresholds.structuralSmells.messageChainLength))",
                        location: createLocation(
                            filePath: filePath,
                            lineNumber: lineNumber,
                            context: "\(method.className).\(method.name)"
                        ),
                        suggestion: "Consider breaking the message chain by introducing intermediate variables or using method extraction"
                    )
                    defects.append(defect)
                }
            }
        }

        return defects
    }

    /// Detects message chains in a method's AST
    private func detectMessageChains(in methodNode: FunctionDeclSyntax) -> [MessageChain] {
        guard let body = methodNode.body else { return [] }

        let visitor = ChainDetectionVisitor()
        visitor.walk(body)
        return visitor.chains
    }

    /// Calculates severity based on chain length
    private func calculateSeverity(for chainLength: Int) -> Severity {
        let threshold = thresholds.structuralSmells.messageChainLength
        let excess = chainLength - threshold

        switch excess {
        case 1: return .low
        case 2: return .medium
        case 3: return .high
        default: return .critical
        }
    }

    /// Calculates line number from absolute position in source text
    private func calculateLineNumber(from position: AbsolutePosition, in sourceText: String) -> Int {
        let prefix = sourceText.prefix(position.utf8Offset)
        return prefix.components(separatedBy: "\n").count
    }
}

// MARK: - Private Structures

private struct MethodInfo {
    let className: String
    let name: String
    let node: FunctionDeclSyntax
}

// MARK: - Private Visitors

private class MessageChainVisitor: SyntaxVisitor {
    var methods: [MethodInfo] = []

    init() {
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        // Find the containing class/struct
        var currentNode: Syntax = node._syntaxNode
        var className = "Global"

        while let parent = currentNode.parent {
            if let classDecl = parent.as(ClassDeclSyntax.self) {
                className = classDecl.name.text
                break
            } else if let structDecl = parent.as(StructDeclSyntax.self) {
                className = structDecl.name.text
                break
            }
            currentNode = parent
        }

        let methodName = node.name.text
        methods.append(MethodInfo(className: className, name: methodName, node: node))

        return .skipChildren
    }
}

private class ChainDetectionVisitor: SyntaxVisitor {
    private let stateHandler: MessageChainStateHandler

    var chains: [MessageChain] { stateHandler.chainsResult }

    init(stateHandler: MessageChainStateHandler = DefaultMessageChainStateHandler()) {
        self.stateHandler = stateHandler
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        let chain = extractChain(from: node)
        if chain.length >= 2 {
            stateHandler.recordMessageChain(chain)
        }
        return .visitChildren
    }

    override func visit(_ node: OptionalChainingExprSyntax) -> SyntaxVisitorContinueKind {
        // For optional chaining, we can analyze the expression inside
        let chain = extractChainFromOptionalChaining(node)
        if chain.length >= 2 {
            stateHandler.recordMessageChain(chain)
        }
        return .visitChildren
    }

    private func extractChainFromOptionalChaining(_ node: OptionalChainingExprSyntax) -> MessageChain {
        // Parse the description to extract the chain
        let description = node.description
        // Remove question marks and split by dots
        let cleanDescription = description.replacingOccurrences(of: "?", with: "")
        let parts = cleanDescription.split(separator: ".")
        let calls = parts.map { String($0) }

        return MessageChain(calls: calls)
    }

    private func extractChain(from node: MemberAccessExprSyntax) -> MessageChain {
        var calls: [String] = []

        // Start by extracting from the base (which may be optional chaining)
        if let base = node.base {
            if let optionalChaining = base.as(OptionalChainingExprSyntax.self) {
                let baseChain = extractChainFromOptionalChaining(optionalChaining)
                calls.append(contentsOf: baseChain.calls)
            } else if let baseMemberAccess = base.as(MemberAccessExprSyntax.self) {
                let baseChain = extractChain(from: baseMemberAccess)
                calls.append(contentsOf: baseChain.calls)
            }
        }

        // Add the final member access
        calls.append(node.declName.baseName.text)

        return MessageChain(calls: calls)
    }
}