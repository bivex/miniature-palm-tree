//
//  MemberBlockContainable.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Protocol for Swift syntax nodes that contain member blocks
//

import SwiftSyntax

/// Protocol for syntax nodes that have member blocks and declaration names
protocol MemberBlockContainable {
    var memberBlock: MemberBlockSyntax { get }
    var declName: String { get }
}

extension ClassDeclSyntax: MemberBlockContainable {
    var declName: String { name.text }
}

extension StructDeclSyntax: MemberBlockContainable {
    var declName: String { name.text }
}