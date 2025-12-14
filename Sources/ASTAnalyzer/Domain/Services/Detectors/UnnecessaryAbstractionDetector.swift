//
//  UnnecessaryAbstractionDetector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//
//

import Foundation
import SwiftSyntax

/// Detects unnecessary abstractions (empty classes/structs) (Unnecessary Abstraction)
/// Based on DUA (Unnecessary Abstraction):
/// - Abstraction body size = 0 (empty)
public final class UnnecessaryAbstractionDetector: BaseDefectDetector {

    public init() {
        super.init(detectableDefects: [.unnecessaryAbstraction])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        // Analyze classes
        let classVisitor = EmptyTypeVisitor()
        classVisitor.walk(sourceFile)

        for emptyType in classVisitor.emptyTypes {
            let defect = ArchitecturalDefect(
                type: .unnecessaryAbstraction,
                severity: .medium,
                message: "\(emptyType.typeName) '\(emptyType.name)' has no implementation - consider removing or implementing",
                location: createLocation(filePath: filePath, context: "\(emptyType.typeName.lowercased()) \(emptyType.name)"),
                suggestion: "Either remove the empty \(emptyType.typeName.lowercased()) or add implementation"
            )
            defects.append(defect)
        }

        return defects
    }
}

// MARK: - Private Structures

private struct EmptyTypeInfo {
    let typeName: String // "Class", "Struct", "Enum", etc.
    let name: String
}

// MARK: - Private Visitors

private class EmptyTypeVisitor: SyntaxVisitor {
    var emptyTypes: [EmptyTypeInfo] = []

    init() {
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        if isEmpty(node.memberBlock) {
            emptyTypes.append(EmptyTypeInfo(typeName: "Class", name: node.name.text))
        }
        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        if isEmpty(node.memberBlock) {
            emptyTypes.append(EmptyTypeInfo(typeName: "Struct", name: node.name.text))
        }
        return .visitChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        if isEmpty(node.memberBlock) {
            emptyTypes.append(EmptyTypeInfo(typeName: "Enum", name: node.name.text))
        }
        return .visitChildren
    }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        if isEmpty(node.memberBlock) {
            emptyTypes.append(EmptyTypeInfo(typeName: "Actor", name: node.name.text))
        }
        return .visitChildren
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        if isEmpty(node.memberBlock) {
            emptyTypes.append(EmptyTypeInfo(typeName: "Protocol", name: node.name.text))
        }
        return .visitChildren
    }

    private func isEmpty(_ memberBlock: MemberBlockSyntax) -> Bool {
        // Check if member block has no members or only contains empty declarations
        return memberBlock.members.isEmpty
    }
}