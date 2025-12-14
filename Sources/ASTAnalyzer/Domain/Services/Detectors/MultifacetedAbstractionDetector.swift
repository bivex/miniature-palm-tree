//
//  MultifacetedAbstractionDetector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Updated to use Z notation LCOM5 calculation
//

import Foundation
import SwiftSyntax

/**
 Multifaceted Abstraction Detector based on Z notation:
 ```
 MultifacetedAbstractionDetector
 ├─ isMultifacetedAbstraction : Class → 𝔹
 ├─ cohesionScore : Class → ℝ
 └─ ∀ c : Class •
     isMultifacetedAbstraction(c) ⇔ LCOM5(c) > θ_LCOM_MFA ∧
                                     (WMC(c) ≥ θ_WMC_MFA ∨
                                      NOF(c) ≥ θ_NOF_MFA ∨
                                      NOM(c) ≥ θ_NOM_MFA)
 ```
 */
public final class MultifacetedAbstractionDetector: BaseDefectDetector {

    private let thresholds: Thresholds

    public init(thresholds: Thresholds = .academic) {
        self.thresholds = thresholds
        super.init(detectableDefects: [.multifacetedAbstraction])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        let sourceText = sourceFile.description

        // Analyze classes
        let classVisitor = MultifacetedClassVisitor(thresholds: thresholds)
        classVisitor.walk(sourceFile)

        for (className, (info, position)) in classVisitor.multifacetedClasses {
            let lineNumber = calculateLineNumber(from: position, in: sourceText)
            let defect = ArchitecturalDefect(
                type: .multifacetedAbstraction,
                severity: info.severity,
                message: "Class '\(className)' has multifaceted abstraction (LCOM5: \(String(format: "%.2f", info.lcom5)), WMC: \(info.wmc), NOF: \(info.nof), NOM: \(info.nom))",
                location: createLocation(filePath: filePath, lineNumber: lineNumber, context: "class \(className)"),
                suggestion: "Split into smaller classes, each handling a single responsibility"
            )
            defects.append(defect)
        }

        // Analyze structs
        let structVisitor = MultifacetedStructVisitor(thresholds: thresholds)
        structVisitor.walk(sourceFile)

        for (structName, (info, position)) in structVisitor.multifacetedStructs {
            let lineNumber = calculateLineNumber(from: position, in: sourceText)
            let defect = ArchitecturalDefect(
                type: .multifacetedAbstraction,
                severity: info.severity,
                message: "Struct '\(structName)' has multifaceted abstraction (LCOM5: \(String(format: "%.2f", info.lcom5)), WMC: \(info.wmc), NOF: \(info.nof), NOM: \(info.nom))",
                location: createLocation(filePath: filePath, lineNumber: lineNumber, context: "struct \(structName)"),
                suggestion: "Split into smaller structs, each handling a single concern"
            )
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

// MARK: - Multifaceted Abstraction Analysis

/// Information about multifaceted abstraction detection
private struct MultifacetedInfo {
    let lcom5: Double
    let wmc: Int
    let nof: Int
    let nom: Int
    let cohesionScore: Double
    let severity: Severity

    init(lcom5: Double, wmc: Int, nof: Int, nom: Int) {
        self.lcom5 = lcom5
        self.wmc = wmc
        self.nof = nof
        self.nom = nom
        self.cohesionScore = 1.0 - lcom5 // Inverted LCOM5 for cohesion score

        // Determine severity based on cohesion score
        if cohesionScore < 0.3 {
            self.severity = .critical
        } else if cohesionScore < 0.5 {
            self.severity = .high
        } else if cohesionScore < 0.7 {
            self.severity = .medium
        } else {
            self.severity = .low
        }
    }
}

// MARK: - Private Visitors

private class MultifacetedClassVisitor: SyntaxVisitor {
    let thresholds: Thresholds
    var multifacetedClasses: [(String, (MultifacetedInfo, AbsolutePosition))] = []
    var processedClasses: Set<String> = []

    init(thresholds: Thresholds) {
        self.thresholds = thresholds
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let className = node.name.text
        // Skip if already processed
        if processedClasses.contains(className) {
            return .visitChildren
        }

        let analyzer = MultifacetedClassAnalyzer(classDecl: node, thresholds: thresholds)
        if let info = analyzer.analyze() {
            let position = node.positionAfterSkippingLeadingTrivia
            multifacetedClasses.append((className, (info, position)))
            processedClasses.insert(className)
        }
        return .visitChildren
    }
}

private class MultifacetedStructVisitor: SyntaxVisitor {
    let thresholds: Thresholds
    var multifacetedStructs: [(String, (MultifacetedInfo, AbsolutePosition))] = []
    var processedStructs: Set<String> = []

    init(thresholds: Thresholds) {
        self.thresholds = thresholds
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let structName = node.name.text
        // Skip if already processed
        if processedStructs.contains(structName) {
            return .visitChildren
        }

        let analyzer = MultifacetedStructAnalyzer(structDecl: node, thresholds: thresholds)
        if let info = analyzer.analyze() {
            let position = node.positionAfterSkippingLeadingTrivia
            multifacetedStructs.append((structName, (info, position)))
            processedStructs.insert(structName)
        }
        return .visitChildren
    }
}

// MARK: - Analysis Helpers

private class MultifacetedClassAnalyzer {
    let classDecl: ClassDeclSyntax
    let thresholds: Thresholds

    init(classDecl: ClassDeclSyntax, thresholds: Thresholds) {
        self.classDecl = classDecl
        self.thresholds = thresholds
    }

    func analyze() -> MultifacetedInfo? {
        let metrics = extractMetrics()

        // Check Multifaceted Abstraction conditions based on Z notation
        let smells = thresholds.checkClassSmells(wmc: metrics.wmc, tcc: 0, atfd: 0, lcom5: metrics.lcom5, nof: metrics.nof, nom: metrics.nom, woa: 0, dit: 0)
        let isMultifaceted = smells["multifacetedAbstraction"] ?? false

        return isMultifaceted ? MultifacetedInfo(
            lcom5: metrics.lcom5,
            wmc: metrics.wmc,
            nof: metrics.nof,
            nom: metrics.nom
        ) : nil
    }

    private func extractMetrics() -> (lcom5: Double, wmc: Int, nof: Int, nom: Int) {
        var attributes = Set<Attribute>()
        var methods = Set<Method>()

        // Extract attributes and methods
        for member in classDecl.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in varDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        let attribute = Attribute(
                            name: identifier.identifier.text,
                            type: Type(name: "Any"), // Simplified
                            accessLevel: .internal,  // Simplified
                            isComputed: varDecl.bindings.first?.initializer == nil
                        )
                        attributes.insert(attribute)
                    }
                }
            }

            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                let methodDescription = funcDecl.description
                let method = Method(
                    name: funcDecl.name.text,
                    loc: methodDescription.components(separatedBy: "\n").count,
                    cyclomaticComplexity: 1, // Simplified
                    accessedAttributes: []    // Simplified
                )
                methods.insert(method)
            }
        }

        // Create a temporary class for metrics calculation
        let tempClass = Class(
            name: classDecl.name.text,
            methods: methods,
            attributes: attributes,
            loc: { let classDescription = classDecl.description; return classDescription.components(separatedBy: "\n").count }()
        )

        // Calculate metrics using Z notation calculators
        let lcom5 = LCOM_Calculator.calculateLCOM5(for: tempClass)
        let wmc = WMC_Calculator.calculate(for: tempClass)
        let nof = attributes.count
        let nom = methods.count

        return (lcom5: lcom5, wmc: wmc, nof: nof, nom: nom)
    }
}

private class MultifacetedStructAnalyzer {
    let structDecl: StructDeclSyntax
    let thresholds: Thresholds

    init(structDecl: StructDeclSyntax, thresholds: Thresholds) {
        self.structDecl = structDecl
        self.thresholds = thresholds
    }

    func analyze() -> MultifacetedInfo? {
        let metrics = extractMetrics()

        // Same conditions for structs
        let smells = thresholds.checkClassSmells(wmc: metrics.wmc, tcc: 0, atfd: 0, lcom5: metrics.lcom5, nof: metrics.nof, nom: metrics.nom, woa: 0, dit: 0)
        let isMultifaceted = smells["multifacetedAbstraction"] ?? false

        return isMultifaceted ? MultifacetedInfo(
            lcom5: metrics.lcom5,
            wmc: metrics.wmc,
            nof: metrics.nof,
            nom: metrics.nom
        ) : nil
    }

    private func extractMetrics() -> (lcom5: Double, wmc: Int, nof: Int, nom: Int) {
        var attributes = Set<Attribute>()
        var methods = Set<Method>()

        // Extract attributes and methods
        for member in structDecl.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in varDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        let attribute = Attribute(
                            name: identifier.identifier.text,
                            type: Type(name: "Any"),
                            accessLevel: .internal,
                            isComputed: varDecl.bindings.first?.initializer == nil
                        )
                        attributes.insert(attribute)
                    }
                }
            }

            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                let methodDescription = funcDecl.description
                let method = Method(
                    name: funcDecl.name.text,
                    loc: methodDescription.components(separatedBy: "\n").count,
                    cyclomaticComplexity: 1,
                    accessedAttributes: []
                )
                methods.insert(method)
            }
        }

        // Create a temporary class for metrics calculation
        let tempClass = Class(
            name: structDecl.name.text,
            methods: methods,
            attributes: attributes,
            loc: { let structDescription = structDecl.description; return structDescription.components(separatedBy: "\n").count }()
        )

        // Calculate metrics using Z notation calculators
        let lcom5 = LCOM_Calculator.calculateLCOM5(for: tempClass)
        let wmc = WMC_Calculator.calculate(for: tempClass)
        let nof = attributes.count
        let nom = methods.count

        return (lcom5: lcom5, wmc: wmc, nof: nof, nom: nom)
    }
}