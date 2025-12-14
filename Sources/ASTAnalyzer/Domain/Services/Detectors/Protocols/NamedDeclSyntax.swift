//
//  NamedDeclSyntax.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Protocol for Swift syntax nodes that have names
//

import SwiftSyntax

/// Protocol for syntax nodes that have names
protocol NamedDeclSyntax {
    var name: TokenSyntax { get }
}

extension ClassDeclSyntax: NamedDeclSyntax {}
extension StructDeclSyntax: NamedDeclSyntax {}
extension EnumDeclSyntax: NamedDeclSyntax {}
extension ProtocolDeclSyntax: NamedDeclSyntax {}
extension ActorDeclSyntax: NamedDeclSyntax {}