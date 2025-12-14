//
//  InsufficientModularizationDetector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//

import Foundation
import SwiftSyntax

/// Detects files that are too large or contain too many declarations (Insufficient Modularization)
/// Based on DIM (Insufficient Modularization):
/// - File contains > 1 class/struct/enum/actor/protocol
/// - LOC > 40
/// - Max nesting depth > 3
public final class InsufficientModularizationDetector: BaseDefectDetector {

    // Constants based on  et al. thresholds
    private let maxLineCount = 40
    private let maxNestingDepth = 3

    public init() {
        super.init(detectableDefects: [.insufficientModularization])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        // DIM condition 1: File contains > 1 class/struct/enum/actor/protocol
        let typeDeclarationCount = countTypeDeclarations(in: sourceFile)
        if typeDeclarationCount > 1 {
            let defect = ArchitecturalDefect(
                type: .insufficientModularization,
                severity: .high,
                message: "File contains \(typeDeclarationCount) type declarations - should contain at most 1",
                location: createLocation(filePath: filePath),
                suggestion: "Split type declarations into separate files"
            )
            defects.append(defect)
        }

        // DIM condition 2: LOC > 40
        let lineCount = lineCount(of: sourceFile)
        if lineCount > maxLineCount {
            let defect = ArchitecturalDefect(
                type: .insufficientModularization,
                severity: .high,
                message: "File contains \(lineCount) lines - exceeds maximum of \(maxLineCount)",
                location: createLocation(filePath: filePath),
                suggestion: "Split into multiple files with related functionality"
            )
            defects.append(defect)
        }

        // DIM condition 3: Max nesting depth > 3
        let maxDepth = calculateMaxNestingDepth(in: sourceFile)
        if maxDepth > maxNestingDepth {
            let defect = ArchitecturalDefect(
                type: .insufficientModularization,
                severity: .medium,
                message: "Maximum nesting depth is \(maxDepth) - exceeds maximum of \(maxNestingDepth)",
                location: createLocation(filePath: filePath),
                suggestion: "Reduce nesting depth by extracting nested code into separate functions or types"
            )
            defects.append(defect)
        }

        return defects
    }

    /// Counts type declarations (class, struct, enum, actor, protocol) in the source file
    private func countTypeDeclarations(in sourceFile: SourceFileSyntax) -> Int {
        class TypeDeclarationVisitor: SyntaxVisitor {
            var typeCount = 0

            init() {
                super.init(viewMode: .sourceAccurate)
            }

            override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
                typeCount += 1
                return .visitChildren
            }

            override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
                typeCount += 1
                return .visitChildren
            }

            override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
                typeCount += 1
                return .visitChildren
            }

            override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
                typeCount += 1
                return .visitChildren
            }

            override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
                typeCount += 1
                return .visitChildren
            }
        }

        let visitor = TypeDeclarationVisitor()
        visitor.walk(sourceFile)
        return visitor.typeCount
    }

    /// Calculates the maximum nesting depth in the source file
    private func calculateMaxNestingDepth(in sourceFile: SourceFileSyntax) -> Int {
        class NestingDepthVisitor: SyntaxVisitor {
            var currentDepth = 0
            var maxDepth = 0

            init() {
                super.init(viewMode: .sourceAccurate)
            }

            override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
                currentDepth += 1
                maxDepth = max(maxDepth, currentDepth)
                defer { currentDepth -= 1 }
                return .visitChildren
            }

            override func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind {
                currentDepth += 1
                maxDepth = max(maxDepth, currentDepth)
                defer { currentDepth -= 1 }
                return .visitChildren
            }

            override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
                currentDepth += 1
                maxDepth = max(maxDepth, currentDepth)
                defer { currentDepth -= 1 }
                return .visitChildren
            }

            override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
                currentDepth += 1
                maxDepth = max(maxDepth, currentDepth)
                defer { currentDepth -= 1 }
                return .visitChildren
            }

            override func visit(_ node: RepeatStmtSyntax) -> SyntaxVisitorContinueKind {
                currentDepth += 1
                maxDepth = max(maxDepth, currentDepth)
                defer { currentDepth -= 1 }
                return .visitChildren
            }

            override func visit(_ node: SwitchExprSyntax) -> SyntaxVisitorContinueKind {
                currentDepth += 1
                maxDepth = max(maxDepth, currentDepth)
                defer { currentDepth -= 1 }
                return .visitChildren
            }

            override func visit(_ node: DoStmtSyntax) -> SyntaxVisitorContinueKind {
                currentDepth += 1
                maxDepth = max(maxDepth, currentDepth)
                defer { currentDepth -= 1 }
                return .visitChildren
            }
        }

        let visitor = NestingDepthVisitor()
        visitor.walk(sourceFile)
        return visitor.maxDepth
    }
}