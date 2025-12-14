//
//  DuplicateBlockDetector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//
//

import Foundation
import SwiftSyntax

/// Detects duplicate code blocks (Duplicate Block)
/// Based on DDB (Duplicate Block):
/// - Code clone > threshold tokens found
public final class DuplicateBlockDetector: BaseDefectDetector {

    private let thresholds: Thresholds

    public init(thresholds: Thresholds = .academic) {
        self.thresholds = thresholds
        super.init(detectableDefects: [.duplicateBlock])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        let codeBlocks = extractCodeBlocks(from: sourceFile)
        let duplicates = findDuplicateBlocks(codeBlocks)

        for duplicate in duplicates {
            let defect = ArchitecturalDefect(
                type: .duplicateBlock,
                severity: .medium,
                message: "Duplicate code block found (\(duplicate.tokenCount) tokens) - consider extracting to a common function",
                location: createLocation(filePath: filePath),
                suggestion: "Extract duplicate code into a shared function or use a common abstraction"
            )
            defects.append(defect)
        }

        return defects
    }

    private func extractCodeBlocks(from sourceFile: SourceFileSyntax) -> [CodeBlock] {
        let dataCollector = CodeBlockDataCollector()
        let visitor = CodeBlockVisitor(dataCollector: dataCollector)
        visitor.walk(sourceFile)
        return dataCollector.getCollectedData()
    }

    public static func createCodeBlockFromSyntax(body: some SyntaxProtocol, type: BlockType, name: String, minTokens: Int) -> CodeBlock? {
        let content = body.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let tokenCount = estimateTokenCount(content)
        if tokenCount > minTokens {
            return CodeBlock(
                content: content,
                tokenCount: tokenCount,
                type: type,
                name: name
            )
        }
        return nil
    }


    private static func estimateTokenCount(_ content: String) -> Int {
        // Simple token estimation: split by whitespace and punctuation
        let components = content.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
        return components.filter { !$0.isEmpty }.count
    }

    private func findDuplicateBlocks(_ blocks: [CodeBlock]) -> [DuplicateInfo] {
        var duplicates: [DuplicateInfo] = []
        var seenBlocks = Set<String>()

        for block in blocks {
            let normalizedContent = block.normalizedContent()

            if seenBlocks.contains(normalizedContent) && block.isSignificant(minTokenThreshold: thresholds.moduleSmells.duplicateBlockTokens) {
                // Found duplicate
                duplicates.append(createDuplicateInfo(from: block))
            } else {
                seenBlocks.insert(normalizedContent)
            }
        }

        return duplicates
    }

    private func createDuplicateInfo(from block: CodeBlock) -> DuplicateInfo {
        DuplicateInfo(
            content: block.content,
            tokenCount: block.tokenCount,
            blockType: block.type,
            blockName: block.name
        )
    }

}

// MARK: - Structures

public struct CodeBlock {
    let content: String
    let tokenCount: Int
    let type: BlockType
    let name: String

    func normalizedContent() -> String {
        // Normalize by removing extra whitespace and empty lines
        let lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return lines.joined(separator: "\n")
    }

    func isSignificant(minTokenThreshold: Int) -> Bool {
        return tokenCount > minTokenThreshold
    }
}

public enum BlockType {
    case function
    case initializer
    case controlFlow
}

private struct DuplicateInfo {
    let content: String
    let tokenCount: Int
    let blockType: BlockType
    let blockName: String
}