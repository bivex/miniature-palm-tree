//
//  SourceFile.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//

import Foundation

/// Represents a Swift source file being analyzed
public struct SourceFile: Equatable, Hashable {
    public let id: UUID
    public let filePath: String
    public let content: String
    public let analyzedAt: Date

    public init(filePath: String, content: String) {
        self.id = UUID()
        self.filePath = filePath
        self.content = content
        self.analyzedAt = Date()
    }

    // MARK: - Computed Properties

    public var fileName: String {
        URL(fileURLWithPath: filePath).lastPathComponent
    }

    public var fileExtension: String {
        URL(fileURLWithPath: filePath).pathExtension
    }

    public var lineCount: Int {
        content.components(separatedBy: .newlines).count
    }

    public var isSwiftFile: Bool {
        fileExtension.lowercased() == "swift"
    }

    // MARK: - Business Rules

    /// Validates that this is a valid Swift source file
    public func validate() throws {
        guard isSwiftFile else {
            throw AnalysisError.invalidFileType(filePath: filePath)
        }

        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AnalysisError.emptyFile(filePath: filePath)
        }
    }
}