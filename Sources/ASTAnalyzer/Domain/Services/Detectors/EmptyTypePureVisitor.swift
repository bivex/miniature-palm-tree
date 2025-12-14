//
//  EmptyTypePureVisitor.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Pure AST visitor for empty type detection that delegates data collection
//

import SwiftSyntax

/// Pure AST visitor for empty type detection that delegates imperative operations to collectors
public final class EmptyTypePureVisitor: SyntaxVisitor {

    private let dataCollector: DefaultEmptyTypeDataCollector

    public init(dataCollector: DefaultEmptyTypeDataCollector) {
        self.dataCollector = dataCollector
        super.init(viewMode: .sourceAccurate)
    }

    public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        if let emptyType = dataCollector.collectClass(node) {
            dataCollector.addEmptyType(emptyType)
        }
        return .visitChildren
    }

    public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        if let emptyType = dataCollector.collectStruct(node) {
            dataCollector.addEmptyType(emptyType)
        }
        return .visitChildren
    }

    public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        if let emptyType = dataCollector.collectEnum(node) {
            dataCollector.addEmptyType(emptyType)
        }
        return .visitChildren
    }

    public override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        if let emptyType = dataCollector.collectActor(node) {
            dataCollector.addEmptyType(emptyType)
        }
        return .visitChildren
    }

    public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        if let emptyType = dataCollector.collectProtocol(node) {
            dataCollector.addEmptyType(emptyType)
        }
        return .visitChildren
    }
}