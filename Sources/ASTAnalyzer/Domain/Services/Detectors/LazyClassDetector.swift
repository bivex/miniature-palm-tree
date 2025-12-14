//
//  LazyClassDetector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Lazy Class detector based on Z notation specifications
//

import Foundation
import SwiftSyntax

/**
 Lazy Class Detector based on Z notation:
 ```
 LazyClassDetector
 ├─ isLazyClass : Class → 𝔹
 ├─ classUtility : Class → ℝ
 └─ ∀ c : Class •
     isLazyClass(c) ⇔ (NOM(c) < θ_NOM_LazyClass ∧ NOF(c) < θ_NOF_LazyClass) ∨
                      (DIT(c) > 0 ∧ DIT(c) < θ_DIT_LazyClass ∧ NOM(c) < θ_NOM_LazyClass)
 ```
 */
public final class LazyClassDetector: BaseDefectDetector {

    private let thresholds: Thresholds

    public init(thresholds: Thresholds = .academic) {
        self.thresholds = thresholds
        super.init(detectableDefects: [.lazyClass])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        let sourceText = sourceFile.description

        // Analyze classes
        let classVisitor = LazyClassVisitor(thresholds: thresholds)
        classVisitor.walk(sourceFile)

        for (className, (lazyClassInfo, position)) in classVisitor.lazyClasses {
            let lineNumber = calculateLineNumber(from: position, in: sourceText)
            let defect = lazyClassInfo.createDefect(name: className, type: "class", filePath: filePath) { fp, ctx in
                self.createLocation(filePath: fp, lineNumber: lineNumber, context: ctx)
            }
            defects.append(defect)
        }

        // Analyze structs
        let structVisitor = LazyStructVisitor(thresholds: thresholds)
        structVisitor.walk(sourceFile)

        for (structName, (lazyClassInfo, position)) in structVisitor.lazyStructs {
            let lineNumber = calculateLineNumber(from: position, in: sourceText)
            let defect = lazyClassInfo.createDefect(name: structName, type: "struct", filePath: filePath) { fp, ctx in
                self.createLocation(filePath: fp, lineNumber: lineNumber, context: ctx)
            }
            defects.append(defect)
        }

        return defects
    }

    /// Calculate line number from absolute position in source text
    private func calculateLineNumber(from position: AbsolutePosition, in sourceText: String) -> Int {
        let prefix = sourceText.prefix(position.utf8Offset)
        return prefix.components(separatedBy: "\n").count
    }
}

// MARK: - Lazy Class Analysis Info

private struct LazyClassInfo {
    let nom: Int
    let nof: Int
    let dit: Int
    let utility: Double
    let severity: Severity

    init(nom: Int, nof: Int, dit: Int, thresholds: Thresholds) {
        self.nom = nom
        self.nof = nof
        self.dit = dit

        // Calculate utility score based on Z notation formula
        let nomScore = Double(nom) / Double(thresholds.classSmells.lazyClassNOM)
        let nofScore = Double(nof) / Double(thresholds.classSmells.lazyClassNOF)
        let wmcScore = 1.0 // Simplified, assume average complexity

        self.utility = (nomScore * 0.5) + (nofScore * 0.3) + (wmcScore * 0.2)

        // Determine severity (inverse of utility)
        let severityScore = 1.0 - utility

        if severityScore >= 0.8 {
            self.severity = .high
        } else if severityScore >= 0.6 {
            self.severity = .medium
        } else {
            self.severity = .low
        }
    }

    /// Creates an architectural defect for this lazy class/struct
    func createDefect(name: String, type: String, filePath: String, createLocation: (String, String) -> Location) -> ArchitecturalDefect {
        return ArchitecturalDefect(
            type: .lazyClass,
            severity: severity,
            message: "\(type.capitalized) '\(name)' is a Lazy Class (NOM: \(nom), NOF: \(nof), DIT: \(dit))",
            location: createLocation(filePath, "\(type) \(name)"),
            suggestion: "Consider removing this \(type) if it adds little value, or merge it with another \(type) if it has a single responsibility"
        )
    }
}

// MARK: - Private Visitors

private class LazyClassVisitor: SyntaxVisitor {
    let thresholds: Thresholds
    var lazyClasses: [(String, (LazyClassInfo, AbsolutePosition))] = []

    init(thresholds: Thresholds) {
        self.thresholds = thresholds
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let analyzer = LazyClassAnalyzer(classDecl: node, thresholds: thresholds)
        if let lazyClassInfo = analyzer.analyze() {
            let position = node.positionAfterSkippingLeadingTrivia
            lazyClasses.append((node.name.text, (lazyClassInfo, position)))
        }
        return .visitChildren
    }
}

private class LazyStructVisitor: SyntaxVisitor {
    let thresholds: Thresholds
    var lazyStructs: [(String, (LazyClassInfo, AbsolutePosition))] = []

    init(thresholds: Thresholds) {
        self.thresholds = thresholds
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let analyzer = LazyStructAnalyzer(structDecl: node, thresholds: thresholds)
        if let lazyClassInfo = analyzer.analyze() {
            let position = node.positionAfterSkippingLeadingTrivia
            lazyStructs.append((node.name.text, (lazyClassInfo, position)))
        }
        return .visitChildren
    }
}

// MARK: - Analysis Helpers

private class LazyClassAnalyzer {
    let classDecl: ClassDeclSyntax
    let thresholds: Thresholds

    init(classDecl: ClassDeclSyntax, thresholds: Thresholds) {
        self.classDecl = classDecl
        self.thresholds = thresholds
    }

    func analyze() -> LazyClassInfo? {
        // Skip visitor classes as they are legitimate design pattern implementations
        if inheritsFromSyntaxVisitor() {
            return nil
        }

        let metrics = extractMetrics()

        // Check Lazy Class conditions based on Z notation
        let smells = thresholds.checkClassSmells(wmc: 0, tcc: 0, atfd: 0, lcom5: 0, nof: metrics.nof, nom: metrics.nom, woa: 0, dit: metrics.dit)
        let isLazyClass = smells["lazyClass"] ?? false

        return isLazyClass ? LazyClassInfo(
            nom: metrics.nom,
            nof: metrics.nof,
            dit: metrics.dit,
            thresholds: thresholds
        ) : nil
    }

    private func extractMetrics() -> (nom: Int, nof: Int, dit: Int) {
        var methods = 0
        var fields = 0
        var inheritanceDepth = 0

        // Count methods
        for member in classDecl.memberBlock.members {
            if member.decl.is(FunctionDeclSyntax.self) || member.decl.is(InitializerDeclSyntax.self) {
                methods += 1
            }

            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                // Count stored properties (not computed)
                for binding in varDecl.bindings {
                    if binding.initializer != nil || varDecl.modifiers.contains(where: { $0.name.text == "let" }) {
                        fields += 1
                    }
                }
            }
        }

        // Calculate inheritance depth (simplified)
        if let inheritanceClause = classDecl.inheritanceClause {
            inheritanceDepth = inheritanceClause.inheritedTypes.count
        }

        return (nom: methods, nof: fields, dit: inheritanceDepth)
    }

    private func inheritsFromSyntaxVisitor() -> Bool {
        // Check if the class inherits from SyntaxVisitor
        guard let inheritanceClause = classDecl.inheritanceClause else {
            return false
        }

        for inheritedType in inheritanceClause.inheritedTypes {
            if let identifierType = inheritedType.type.as(IdentifierTypeSyntax.self) {
                if identifierType.name.text == "SyntaxVisitor" {
                    return true
                }
            }
        }
        return false
    }
}

private class LazyStructAnalyzer {
    let structDecl: StructDeclSyntax
    let thresholds: Thresholds

    init(structDecl: StructDeclSyntax, thresholds: Thresholds) {
        self.structDecl = structDecl
        self.thresholds = thresholds
    }

    func analyze() -> LazyClassInfo? {
        let metrics = extractMetrics()

        // For structs, be more lenient since they're often used as simple data containers
        // Only flag structs as lazy if they have some methods but very few fields
        // Data-only structs (common in Swift) should not be flagged
        let hasMethods = metrics.nom > 0
        let hasFewFields = metrics.nof < thresholds.classSmells.lazyClassNOF
        let isLazyClass = hasMethods && hasFewFields && metrics.nom < thresholds.classSmells.lazyClassNOM

        return isLazyClass ? LazyClassInfo(
            nom: metrics.nom,
            nof: metrics.nof,
            dit: 0, // Structs don't inherit
            thresholds: thresholds
        ) : nil
    }

    private func extractMetrics() -> (nom: Int, nof: Int, dit: Int) {
        var methods = 0
        var fields = 0

        // Count methods
        for member in structDecl.memberBlock.members {
            if member.decl.is(FunctionDeclSyntax.self) || member.decl.is(InitializerDeclSyntax.self) {
                methods += 1
            }

            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                // Count stored properties
                for binding in varDecl.bindings {
                    if binding.initializer != nil || varDecl.modifiers.contains(where: { $0.name.text == "let" }) {
                        fields += 1
                    }
                }
            }
        }

        return (nom: methods, nof: fields, dit: 0)
    }
}