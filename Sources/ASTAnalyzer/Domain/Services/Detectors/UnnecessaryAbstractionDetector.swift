//
//  UnnecessaryAbstractionDetector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//
//

import Foundation
import SwiftSyntax

/// Detects unnecessary abstractions (empty classes/structs) (Unnecessary Abstraction)
/// Based on DUA (Unnecessary Abstraction):
/// - Abstraction body size = 0 (empty)
public final class UnnecessaryAbstractionDetector: BaseDefectDetector {

    public init() {
        super.init(detectableDefects: [.unnecessaryAbstraction])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        // Analyze classes
        let dataCollector = DefaultEmptyTypeDataCollector()
        let visitor = EmptyTypePureVisitor(dataCollector: dataCollector)
        visitor.walk(sourceFile)

        for emptyType in dataCollector.getCollectedData() {
            let defect = ArchitecturalDefect(
                type: .unnecessaryAbstraction,
                severity: .medium,
                message: "\(emptyType.typeName) '\(emptyType.name)' has no implementation - consider removing or implementing",
                location: createLocation(filePath: filePath, context: "\(emptyType.typeName.lowercased()) \(emptyType.name)"),
                suggestion: "Either remove the empty \(emptyType.typeName.lowercased()) or add implementation"
            )
            defects.append(defect)
        }

        return defects
    }
}
