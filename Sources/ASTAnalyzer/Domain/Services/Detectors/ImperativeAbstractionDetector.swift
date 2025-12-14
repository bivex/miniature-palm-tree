//
//  ImperativeAbstractionDetector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//
//

import Foundation
import SwiftSyntax

/// Detects abstractions with too many imperative operations (Imperative Abstraction)
/// Based on DIA (Imperative Abstraction):
/// - execCount > threshold AND execRatio > threshold (where exec = imperative/side-effect operations)
public final class ImperativeAbstractionDetector: BaseDefectDetector {

    private let thresholds: Thresholds

    public init(thresholds: Thresholds = .academic) {
        self.thresholds = thresholds
        super.init(detectableDefects: [.imperativeAbstraction])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        // Analyze classes
        let classVisitor = ImperativeTypeVisitor(maxExecCount: thresholds.moduleSmells.imperativeAbstractionMaxExecCount, execRatioThreshold: thresholds.moduleSmells.imperativeAbstractionExecRatio)
        classVisitor.walk(sourceFile)

        for imperativeType in classVisitor.imperativeTypes {
            let defect = ArchitecturalDefect(
                type: .imperativeAbstraction,
                severity: .high,
                message: "\(imperativeType.typeName) '\(imperativeType.name)' has \(imperativeType.execCount) imperative operations (\(String(format: "%.1f", imperativeType.execRatio * 100))% of all elements) - consider extracting side effects",
                location: createLocation(filePath: filePath, context: "\(imperativeType.typeName.lowercased()) \(imperativeType.name)"),
                suggestion: "Extract imperative operations into separate methods or classes to improve testability and maintainability"
            )
            defects.append(defect)
        }

        return defects
    }
}
