//
//  EmptyTypeDataCollector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Data collector for empty type detection
//

import SwiftSyntax

/// Protocol for collecting empty type data during AST traversal
public protocol EmptyTypeDataCollector {
    associatedtype CollectedData

    /// Collect data from a class declaration
    func collectClass(_ node: ClassDeclSyntax) -> CollectedData?

    /// Collect data from a struct declaration
    func collectStruct(_ node: StructDeclSyntax) -> CollectedData?

    /// Collect data from an enum declaration
    func collectEnum(_ node: EnumDeclSyntax) -> CollectedData?

    /// Collect data from an actor declaration
    func collectActor(_ node: ActorDeclSyntax) -> CollectedData?

    /// Collect data from a protocol declaration
    func collectProtocol(_ node: ProtocolDeclSyntax) -> CollectedData?

    /// Get all collected data
    func getCollectedData() -> [CollectedData]
}

/// Implementation of EmptyTypeDataCollector
public final class DefaultEmptyTypeDataCollector: EmptyTypeDataCollector {
    public typealias CollectedData = EmptyTypeInfo

    private var emptyTypes: [EmptyTypeInfo] = []

    public init() {}

    public func collectClass(_ node: ClassDeclSyntax) -> EmptyTypeInfo? {
        return isEmpty(node.memberBlock) ? EmptyTypeInfo(typeName: "Class", name: node.name.text) : nil
    }

    public func collectStruct(_ node: StructDeclSyntax) -> EmptyTypeInfo? {
        return isEmpty(node.memberBlock) ? EmptyTypeInfo(typeName: "Struct", name: node.name.text) : nil
    }

    public func collectEnum(_ node: EnumDeclSyntax) -> EmptyTypeInfo? {
        return isEmpty(node.memberBlock) ? EmptyTypeInfo(typeName: "Enum", name: node.name.text) : nil
    }

    public func collectActor(_ node: ActorDeclSyntax) -> EmptyTypeInfo? {
        return isEmpty(node.memberBlock) ? EmptyTypeInfo(typeName: "Actor", name: node.name.text) : nil
    }

    public func collectProtocol(_ node: ProtocolDeclSyntax) -> EmptyTypeInfo? {
        return isEmpty(node.memberBlock) ? EmptyTypeInfo(typeName: "Protocol", name: node.name.text) : nil
    }

    public func getCollectedData() -> [EmptyTypeInfo] {
        return emptyTypes
    }

    /// Add a collected empty type to the collection
    public func addEmptyType(_ emptyType: EmptyTypeInfo) {
        emptyTypes.append(emptyType)
    }

    private func isEmpty(_ memberBlock: MemberBlockSyntax) -> Bool {
        // Check if member block has no members or only contains empty declarations
        return memberBlock.members.isEmpty
    }
}

/// Information about an empty type
public struct EmptyTypeInfo {
    public let typeName: String // "Class", "Struct", "Enum", etc.
    public let name: String
}