//
//  SyntaxParser.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//

import Foundation
import SwiftSyntax

/// Port for parsing Swift source code into AST
public protocol SyntaxParser {
    /// Parses Swift source code into a syntax tree
    /// - Parameters:
    ///   - source: The Swift source code as a string
    ///   - filePath: Path to the source file (for error reporting)
    /// - Returns: Parsed source file syntax tree
    /// - Throws: Parsing errors
    func parse(source: String, filePath: String) async throws -> SourceFileSyntax
}