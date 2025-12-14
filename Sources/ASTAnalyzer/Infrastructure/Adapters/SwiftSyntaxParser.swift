//
//  SwiftSyntaxParser.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//

import Foundation
import SwiftSyntax
import SwiftParser

/// Adapter for parsing Swift code using SwiftSyntax
public final class SwiftSyntaxParser: SyntaxParser {

    public init() {}

    public func parse(source: String, filePath: String) async throws -> SourceFileSyntax {
        // Parser.parse(source:) does not throw in current SwiftSyntax version
        // If parsing fails, it may return an incomplete tree, but we can't detect this easily
        // For now, we'll just return the parsed tree and let downstream code handle any issues
        return Parser.parse(source: source)
    }
}