//
//  UnstructuredModuleDetector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//
//

import Foundation
import SwiftSyntax

/// Detects unstructured modules (Unstructured Module)
/// Based on DUM (Unstructured Module):
/// - Module structure violations or unexpected file/folder count > threshold
public final class UnstructuredModuleDetector: BaseDefectDetector {

    private let thresholds: Thresholds

    public init(thresholds: Thresholds = .academic) {
        self.thresholds = thresholds
        super.init(detectableDefects: [.unstructuredModule])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        let structureAnalyzer = FileStructureAnalyzer()
        structureAnalyzer.walk(sourceFile)

        let analysis = structureAnalyzer.analysis

        // Check for mixed architectural layers (MVC violation)
        if analysis.hasMixedLayers {
            let layers = analysis.layers.joined(separator: ", ")
            let defect = ArchitecturalDefect(
                type: .unstructuredModule,
                severity: .high,
                message: "File contains mixed architectural layers (\(layers)) - violates separation of concerns",
                location: createLocation(filePath: filePath),
                suggestion: "Separate concerns into different files/layers (e.g., Model, View, Controller)"
            )
            defects.append(defect)
        }

        // Check for too many different element types (unexpected elements)
        let unexpectedElements = countUnexpectedElements(analysis)
        if unexpectedElements > thresholds.moduleSmells.unstructuredModuleMaxElements {
            let defect = ArchitecturalDefect(
                type: .unstructuredModule,
                severity: .medium,
                message: "File contains \(unexpectedElements) different types of elements - consider splitting into focused modules",
                location: createLocation(filePath: filePath),
                suggestion: "Break down into smaller, focused files with single responsibilities"
            )
            defects.append(defect)
        }

        return defects
    }

    private func countUnexpectedElements(_ analysis: StructureAnalysis) -> Int {
        var count = 0

        // Count different categories of elements
        if analysis.hasClasses { count += 1 }
        if analysis.hasStructs { count += 1 }
        if analysis.hasEnums { count += 1 }
        if analysis.hasProtocols { count += 1 }
        if analysis.hasActors { count += 1 }
        if analysis.hasExtensions { count += 1 }
        if analysis.hasGlobalFunctions { count += 1 }
        if analysis.hasGlobalVariables { count += 1 }

        return count
    }
}
