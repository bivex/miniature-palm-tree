//
//  DefectDetector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//

import Foundation
import SwiftSyntax

/// Protocol for detecting architectural defects in Swift code
public protocol DefectDetector {
    /// The type of defects this detector can identify
    var detectableDefects: [DefectType] { get }

    /// Detects defects in the given source file syntax tree
    /// - Parameters:
    ///   - sourceFile: The parsed Swift source file
    ///   - filePath: Path to the source file
    /// - Returns: Array of detected architectural defects
    func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect]
}

/// Base implementation providing common defect detection utilities
public class BaseDefectDetector: DefectDetector {
    public let detectableDefects: [DefectType]

    public init(detectableDefects: [DefectType]) {
        self.detectableDefects = detectableDefects
    }

    public func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        fatalError("Subclasses must implement detectDefects")
    }

    // MARK: - Utility Methods

    /// Counts methods in a member block
    func countMethods(in memberBlock: MemberBlockSyntax) -> Int {
        memberBlock.members.count { member in
            member.decl.is(FunctionDeclSyntax.self)
        }
    }

    /// Extracts line count from syntax node
    func lineCount(of node: some SyntaxProtocol) -> Int {
        node.description.components(separatedBy: "\n").count
    }

    /// Creates a location for a defect
    func createLocation(
        filePath: String,
        lineNumber: Int? = nil,
        columnNumber: Int? = nil,
        context: String? = nil
    ) -> Location {
        Location(
            filePath: filePath,
            lineNumber: lineNumber,
            columnNumber: columnNumber,
            context: context
        )
    }
}