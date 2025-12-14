//
//  DetectorModels.swift
//  ASTAnalyzer
//
//  Created on 2025-12-15.
//  Shared model definitions for detector components
//

import Foundation
import SwiftSyntax

/// Information about a method in a class for visitor state handling
public struct VisitorMethodInfo {
    public let className: String
    public let name: String
    public let node: FunctionDeclSyntax

    public init(className: String, name: String, node: FunctionDeclSyntax) {
        self.className = className
        self.name = name
        self.node = node
    }
}

/// Information about a class
public struct ClassInfo {
    public let name: String
    public let attributes: [String]
    public let methods: [String]

    public init(name: String, attributes: [String], methods: [String] = []) {
        self.name = name
        self.attributes = attributes
        self.methods = methods
    }
}

/// Information about a message chain
public struct MessageChain {
    public let calls: [String]
    public let length: Int

    public init(calls: [String]) {
        self.calls = calls
        self.length = calls.count
    }
}