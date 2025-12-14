//
//  VisitorStateHandlers.swift
//  ASTAnalyzer
//
//  Created on 2025-12-15.
//  Abstractions for visitor state mutations to eliminate imperative operations
//

import Foundation
import SwiftSyntax

/// Protocol for handling structure analysis state mutations
public protocol StructureAnalysisHandler {
    func recordClassFound()
    func recordStructFound()
    func recordEnumFound()
    func recordProtocolFound()
    func recordActorFound()
    func recordExtensionFound()
    func recordGlobalFunctionFound()
    func recordGlobalVariableFound()
    func recordLayer(_ layer: String)

    var result: StructureAnalysis { get }
}

/// Protocol for handling feature envy detection state mutations
public protocol FeatureEnvyStateHandler {
    func recordClass(name: String, attributes: [String])
    func recordMethod(className: String, name: String, node: FunctionDeclSyntax)

    var methodsResult: [VisitorMethodInfo] { get }
    var classesResult: [ClassInfo] { get }
}

/// Protocol for handling dependency graph state mutations
public protocol DependencyGraphStateHandler {
    func recordClass(name: String, attributes: [String], methods: [String])
    func recordStruct(name: String, attributes: [String])
    func recordDependency(from: String, to: String)
    func recordAttributeAccess(inMethod: String, attribute: String, className: String)

    var classesResult: [String: ClassInfo] { get }
    var dependenciesResult: [(from: String, to: String)] { get }
    var attributeAccessResult: [String: [String: Int]] { get }
}

/// Protocol for handling message chain detection state mutations
public protocol MessageChainStateHandler {
    func recordMessageChain(_ chain: MessageChain)

    var chainsResult: [MessageChain] { get }
}

/// Default implementation of StructureAnalysisHandler
public final class DefaultStructureAnalysisHandler: StructureAnalysisHandler {
    private var analysis: StructureAnalysis

    public var result: StructureAnalysis { analysis }

    public init() {
        self.analysis = StructureAnalysis()
    }

    public func recordClassFound() {
        analysis.hasClasses = true
    }

    public func recordStructFound() {
        analysis.hasStructs = true
    }

    public func recordEnumFound() {
        analysis.hasEnums = true
    }

    public func recordProtocolFound() {
        analysis.hasProtocols = true
    }

    public func recordActorFound() {
        analysis.hasActors = true
    }

    public func recordExtensionFound() {
        analysis.hasExtensions = true
    }

    public func recordGlobalFunctionFound() {
        analysis.hasGlobalFunctions = true
        analysis.layers.insert("Utility")
    }

    public func recordGlobalVariableFound() {
        analysis.hasGlobalVariables = true
        analysis.layers.insert("Data")
    }

    public func recordLayer(_ layer: String) {
        analysis.layers.insert(layer)
    }
}

/// Default implementation of FeatureEnvyStateHandler
public final class DefaultFeatureEnvyStateHandler: FeatureEnvyStateHandler {
    private var methods: [VisitorMethodInfo] = []
    private var classes: [ClassInfo] = []

    public var methodsResult: [VisitorMethodInfo] { methods }
    public var classesResult: [ClassInfo] { classes }

    public func recordClass(name: String, attributes: [String]) {
        classes.append(ClassInfo(name: name, attributes: attributes))
    }

    public func recordMethod(className: String, name: String, node: FunctionDeclSyntax) {
        methods.append(VisitorMethodInfo(className: className, name: name, node: node))
    }
}

/// Default implementation of DependencyGraphStateHandler
public final class DefaultDependencyGraphStateHandler: DependencyGraphStateHandler {
    private var classes: [String: ClassInfo] = [:]
    private var dependencies: [(from: String, to: String)] = []
    private var attributeAccess: [String: [String: Int]] = [:]

    public var classesResult: [String: ClassInfo] { classes }
    public var dependenciesResult: [(from: String, to: String)] { dependencies }
    public var attributeAccessResult: [String: [String: Int]] { attributeAccess }

    public func recordClass(name: String, attributes: [String], methods: [String]) {
        classes[name] = ClassInfo(name: name, attributes: attributes, methods: methods)
    }

    public func recordStruct(name: String, attributes: [String]) {
        classes[name] = ClassInfo(name: name, attributes: attributes, methods: [])
    }

    public func recordDependency(from: String, to: String) {
        dependencies.append((from: from, to: to))
    }

    public func recordAttributeAccess(inMethod: String, attribute: String, className: String) {
        if attributeAccess[inMethod] == nil {
            attributeAccess[inMethod] = [:]
        }
        attributeAccess[inMethod]![className] = (attributeAccess[inMethod]![className] ?? 0) + 1
    }
}

/// Default implementation of MessageChainStateHandler
public final class DefaultMessageChainStateHandler: MessageChainStateHandler {
    private var chains: [MessageChain] = []

    public var chainsResult: [MessageChain] { chains }

    public func recordMessageChain(_ chain: MessageChain) {
        chains.append(chain)
    }
}