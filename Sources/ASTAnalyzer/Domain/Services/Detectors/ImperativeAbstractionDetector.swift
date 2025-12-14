//
//  ImperativeAbstractionDetector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//
//

import Foundation
import SwiftSyntax

/// Detects abstractions with too many imperative operations (Imperative Abstraction)
/// Based on DIA (Imperative Abstraction):
/// - execCount > 2 AND execRatio > 20% (where exec = imperative/side-effect operations)
public final class ImperativeAbstractionDetector: BaseDefectDetector {

    // Constants based on  et al. thresholds
    private let maxExecCount = 2
    private let execRatioThreshold = 0.20

    public init() {
        super.init(detectableDefects: [.imperativeAbstraction])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        // Analyze classes
        let classVisitor = ImperativeTypeVisitor(maxExecCount: maxExecCount, execRatioThreshold: execRatioThreshold)
        classVisitor.walk(sourceFile)

        for imperativeType in classVisitor.imperativeTypes {
            let defect = ArchitecturalDefect(
                type: .imperativeAbstraction,
                severity: .high,
                message: "\(imperativeType.typeName) '\(imperativeType.name)' has \(imperativeType.execCount) imperative operations (\(String(format: "%.1f", imperativeType.execRatio * 100))% of all elements) - consider extracting side effects",
                location: createLocation(filePath: filePath, context: "\(imperativeType.typeName.lowercased()) \(imperativeType.name)"),
                suggestion: "Extract imperative operations into separate methods or classes to improve testability and maintainability"
            )
            defects.append(defect)
        }

        return defects
    }
}

// MARK: - Private Structures

private struct ImperativeTypeInfo {
    let typeName: String // "Class", "Struct", etc.
    let name: String
    let execCount: Int
    let totalElements: Int
    let execRatio: Double
}

// MARK: - Private Visitors

private class ImperativeTypeVisitor: SyntaxVisitor {
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

// MARK: - Helper Protocol

private protocol MemberBlockContainable {
    var memberBlock: MemberBlockSyntax { get }
    var declName: String { get }
}

extension ClassDeclSyntax: MemberBlockContainable {
    var declName: String { name.text }
}

extension StructDeclSyntax: MemberBlockContainable {
    var declName: String { name.text }
}