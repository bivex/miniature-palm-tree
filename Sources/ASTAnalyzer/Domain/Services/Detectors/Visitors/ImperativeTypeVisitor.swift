//
//  ImperativeTypeVisitor.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Visitor for detecting imperative abstractions in Swift code
//

import Foundation
import SwiftSyntax

/// Visitor that analyzes Swift code for imperative abstraction issues
final class ImperativeTypeVisitor: SyntaxVisitor {
    let maxExecCount: Int
    let execRatioThreshold: Double
    var imperativeTypes: [ImperativeTypeInfo] = []

    init(maxExecCount: Int, execRatioThreshold: Double) {
        self.maxExecCount = maxExecCount
        self.execRatioThreshold = execRatioThreshold
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        analyzeImperativeAbstraction(node, typeName: "Class")
        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        analyzeImperativeAbstraction(node, typeName: "Struct")
        return .visitChildren
    }

    private func analyzeImperativeAbstraction(_ node: some DeclSyntaxProtocol & MemberBlockContainable, typeName: String) {
        let analysis = analyzeMembers(node.memberBlock)

        if analysis.execCount > maxExecCount && analysis.execRatio > execRatioThreshold {
            imperativeTypes.append(ImperativeTypeInfo(
                typeName: typeName,
                name: node.declName,
                execCount: analysis.execCount,
                totalElements: analysis.totalElements,
                execRatio: analysis.execRatio
            ))
        }
    }

    private func analyzeMembers(_ memberBlock: MemberBlockSyntax) -> (execCount: Int, totalElements: Int, execRatio: Double) {
        var execCount = 0
        var totalElements = 0

        for member in memberBlock.members {
            totalElements += 1

            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                if isImperativeFunction(funcDecl) {
                    execCount += 1
                }
            } else if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                // Variable declarations can be imperative if they have side effects in initializers
                if hasSideEffectInitializer(varDecl) {
                    execCount += 1
                }
            }
        }

        let execRatio = totalElements > 0 ? Double(execCount) / Double(totalElements) : 0.0
        return (execCount, totalElements, execRatio)
    }

    private func isImperativeFunction(_ funcDecl: FunctionDeclSyntax) -> Bool {
        guard let body = funcDecl.body else { return false }

        let bodyText = body.description

        // Check for common imperative patterns
        let imperativePatterns = [
            "print(",           // Output operations
            "fatalError(",      // Error handling that terminates
            "exit(",            // Program termination
            "abort(",           // Program termination
            "Process.",         // System process operations
            "FileManager.",     // File system operations
            "URLSession.",      // Network operations
            "UserDefaults.",    // Persistence operations
            "NotificationCenter.", // Event system operations
            ".write(",          // Write operations
            ".save(",           // Save operations
            ".delete(",         // Delete operations
            ".remove(",         // Remove operations
            ".append(",         // Modification operations
            ".insert(",         // Modification operations
            ".update(",         // Update operations
            "DispatchQueue.",   // Async operations
            "Timer.",           // Timer operations
            "RunLoop."          // Run loop operations
        ]

        return imperativePatterns.contains { bodyText.contains($0) }
    }

    private func hasSideEffectInitializer(_ varDecl: VariableDeclSyntax) -> Bool {
        for binding in varDecl.bindings {
            if let initializer = binding.initializer {
                let initText = initializer.value.description
                // Check if initializer calls functions or has side effects
                return initText.contains("(") && initText.contains(")") // Function calls in initializer
            }
        }
        return false
    }
}