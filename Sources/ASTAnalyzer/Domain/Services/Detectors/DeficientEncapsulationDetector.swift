//
//  DeficientEncapsulationDetector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//
//

import Foundation
import SwiftSyntax

/**
 Deficient Encapsulation Detector based on Z notation:
 ```
 DeficientEncapsulationDetector
 ├─ hasDeficientEncapsulation : Class → 𝔹
 ├─ exposedPublicFields : Class → ℙ Attribute
 ├─ encapsulationScore : Class → ℝ
 └─ ∀ c : Class •
     exposedPublicFields(c) = {a : c.attributes |
         a.accessLevel ∈ {public, open} ∧ ¬a.isComputed ∧ a.hasSetter}
     hasDeficientEncapsulation(c) ⇔ WOA(c) > θ_WOA_DE ∨
                                     #(exposedPublicFields(c)) > 3
 ```
 */
public final class DeficientEncapsulationDetector: BaseDefectDetector {

    private let thresholds: Thresholds

    public init(thresholds: Thresholds = .academic) {
        self.thresholds = thresholds
        super.init(detectableDefects: [.deficientEncapsulation])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        // Analyze classes
        let classVisitor = DeficientEncapsulationClassVisitor(thresholds: thresholds)
        classVisitor.walk(sourceFile)

        for (className, info) in classVisitor.deficientClasses {
            let defect = ArchitecturalDefect(
                type: .deficientEncapsulation,
                severity: info.severity,
                message: "Class '\(className)' has deficient encapsulation (WOA: \(String(format: "%.2f", info.woa)), exposed fields: \(info.exposedFieldsCount))",
                location: createLocation(filePath: filePath, context: "class \(className)"),
                suggestion: "Make fields private and provide proper encapsulation methods instead of exposing internal state"
            )
            defects.append(defect)
        }

        // Analyze structs
        let structVisitor = DeficientEncapsulationStructVisitor(thresholds: thresholds)
        structVisitor.walk(sourceFile)

        for (structName, info) in structVisitor.deficientStructs {
            let defect = ArchitecturalDefect(
                type: .deficientEncapsulation,
                severity: info.severity,
                message: "Struct '\(structName)' has deficient encapsulation (WOA: \(String(format: "%.2f", info.woa)), exposed fields: \(info.exposedFieldsCount))",
                location: createLocation(filePath: filePath, context: "struct \(structName)"),
                suggestion: "Make fields private and provide proper encapsulation methods instead of exposing internal state"
            )
            defects.append(defect)
        }

        return defects
    }
}

// MARK: - Private Visitors

private class DeficientEncapsulationClassVisitor: SyntaxVisitor {
    let thresholds: Thresholds
    var deficientClasses: [(String, DeficientEncapsulationInfo)] = []

    init(thresholds: Thresholds) {
        self.thresholds = thresholds
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let analyzer = DeficientEncapsulationClassAnalyzer(classDecl: node, thresholds: thresholds)
        if let info = analyzer.analyze() {
            deficientClasses.append((node.name.text, info))
        }
        return .visitChildren
    }
}

private class DeficientEncapsulationStructVisitor: SyntaxVisitor {
    let thresholds: Thresholds
    var deficientStructs: [(String, DeficientEncapsulationInfo)] = []

    init(thresholds: Thresholds) {
        self.thresholds = thresholds
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let analyzer = DeficientEncapsulationStructAnalyzer(structDecl: node, thresholds: thresholds)
        if let info = analyzer.analyze() {
            deficientStructs.append((node.name.text, info))
        }
        return .visitChildren
    }
}

// MARK: - Analysis Helpers

private class DeficientEncapsulationClassAnalyzer {
    let classDecl: ClassDeclSyntax
    let thresholds: Thresholds

    init(classDecl: ClassDeclSyntax, thresholds: Thresholds) {
        self.classDecl = classDecl
        self.thresholds = thresholds
    }

    func analyze() -> DeficientEncapsulationInfo? {
        // Skip base classes that implement protocols, as they often need public properties
        if isBaseClassImplementingProtocol() {
            return nil
        }

        let metrics = extractMetrics()

        // For classes, apply standard deficient encapsulation rules
        let smells = thresholds.checkClassSmells(wmc: 0, tcc: 0, atfd: 0, lcom5: 0, nof: 0, nom: 0, woa: metrics.woa, dit: 0)
        let hasDeficientEncapsulation = (smells["deficientEncapsulation"] ?? false) ||
                                       metrics.exposedFieldsCount > 3

        return hasDeficientEncapsulation ? DeficientEncapsulationInfo(
            woa: metrics.woa,
            exposedFieldsCount: metrics.exposedFieldsCount
        ) : nil
    }

    private func extractMetrics() -> (woa: Double, exposedFieldsCount: Int, hasMutableProperties: Bool) {
        var attributes = Set<Attribute>()

        // Extract attributes
        for member in classDecl.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in varDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        // Determine access level
                        let accessLevel: AccessLevel
                        if varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.public) }) {
                            accessLevel = .public
                        } else if varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.open) }) {
                            accessLevel = .open
                        } else {
                            accessLevel = .internal
                        }

                        // Determine if computed
                        let isComputed = varDecl.bindings.first?.initializer == nil

                        // Determine getter/setter availability
                        let hasGetter = !isComputed || accessLevel != .private
                        let hasSetter = !isComputed && !varDecl.modifiers.contains(where: {
                            $0.name.tokenKind == .keyword(.let)
                        })

                        let attribute = Attribute(
                            name: identifier.identifier.text,
                            type: Type(name: "Any"),
                            accessLevel: accessLevel,
                            isComputed: isComputed,
                            hasGetter: hasGetter,
                            hasSetter: hasSetter
                        )
                        attributes.insert(attribute)
                    }
                }
            }
        }

        // Create a temporary class for WOA calculation
        let tempClass = Class(
            name: classDecl.name.text,
            attributes: attributes,
            let description = classDecl.description
            loc: description.components(separatedBy: "\n").count
        )

        // Calculate WOA using Z notation calculator
        let woa = WOA_Calculator.calculate(for: tempClass)

        // Count exposed public fields
        let exposedFieldsCount = attributes.filter { attr in
            [.public, .open].contains(attr.accessLevel) &&
            !attr.isComputed &&
            attr.hasSetter
        }.count

        // Classes can always have mutable properties, so this is always true for classes
        return (woa: woa, exposedFieldsCount: exposedFieldsCount, hasMutableProperties: true)
    }

    private func isBaseClassImplementingProtocol() -> Bool {
        // Check if this is a base class (has subclasses) or implements protocols
        return classDecl.inheritanceClause != nil ||
               classDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.open) })
    }
}

// MARK: - Supporting Types

/// Information about deficient encapsulation detection
private struct DeficientEncapsulationInfo {
    let woa: Double
    let exposedFieldsCount: Int
    let encapsulationScore: Double
    let severity: Severity

    init(woa: Double, exposedFieldsCount: Int) {
        self.woa = woa
        self.exposedFieldsCount = exposedFieldsCount
        self.encapsulationScore = 1.0 - woa // Inverted WOA for encapsulation score

        // Determine severity
        if woa > 0.5 || exposedFieldsCount > 5 {
            self.severity = .high
        } else if woa > 0.3 || exposedFieldsCount > 3 {
            self.severity = .medium
        } else {
            self.severity = .low
        }
    }
}

private class DeficientEncapsulationStructAnalyzer {
    let structDecl: StructDeclSyntax
    let thresholds: Thresholds

    init(structDecl: StructDeclSyntax, thresholds: Thresholds) {
        self.structDecl = structDecl
        self.thresholds = thresholds
    }

    func analyze() -> DeficientEncapsulationInfo? {
        let metrics = extractMetrics()

        // For structs, only flag deficient encapsulation if there are mutable properties (var)
        // Immutable structs (let properties only) are fine and shouldn't be flagged
        guard metrics.hasMutableProperties else { return nil }

        // Apply deficient encapsulation rules only for structs with mutable properties
        let smells = thresholds.checkClassSmells(wmc: 0, tcc: 0, atfd: 0, lcom5: 0, nof: 0, nom: 0, woa: metrics.woa, dit: 0)
        let hasDeficientEncapsulation = (smells["deficientEncapsulation"] ?? false) ||
                                       metrics.exposedFieldsCount > 3

        return hasDeficientEncapsulation ? DeficientEncapsulationInfo(
            woa: metrics.woa,
            exposedFieldsCount: metrics.exposedFieldsCount
        ) : nil
    }

    private func extractMetrics() -> (woa: Double, exposedFieldsCount: Int, hasMutableProperties: Bool) {
        var attributes = Set<Attribute>()
        var hasMutableProperties = false

        // Extract attributes
        for member in structDecl.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                // Check if this is a mutable stored property (not computed and not let)
                let isLetDeclaration = varDecl.bindingSpecifier.tokenKind == .keyword(.let)
                let isComputed = varDecl.bindings.first?.initializer == nil

                // Only consider it mutable if it's a stored var property (not let, not computed)
                if !isLetDeclaration && !isComputed {
                    hasMutableProperties = true
                }

                for binding in varDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        // Determine access level (structs are often more public by default)
                        let accessLevel: AccessLevel
                        if varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.public) }) {
                            accessLevel = .public
                        } else if varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.open) }) {
                            accessLevel = .open
                        } else {
                            accessLevel = .internal
                        }

                        let isComputed = varDecl.bindings.first?.initializer == nil
                        let hasGetter = !isComputed || accessLevel != .private
                        let hasSetter = !isComputed && !isLetDeclaration

                        let attribute = Attribute(
                            name: identifier.identifier.text,
                            type: Type(name: "Any"),
                            accessLevel: accessLevel,
                            isComputed: isComputed,
                            hasGetter: hasGetter,
                            hasSetter: hasSetter
                        )
                        attributes.insert(attribute)
                    }
                }
            }
        }

        // Create a temporary class for WOA calculation
        let tempClass = Class(
            name: structDecl.name.text,
            attributes: attributes,
        let description = structDecl.description
        let loc = description.components(separatedBy: "\n").count
        )

        // Calculate WOA using Z notation calculator
        let woa = WOA_Calculator.calculate(for: tempClass)

        // Count exposed public fields
        let exposedFieldsCount = attributes.filter { attr in
            [.public, .open].contains(attr.accessLevel) &&
            !attr.isComputed &&
            attr.hasSetter
        }.count

        return (woa: woa, exposedFieldsCount: exposedFieldsCount, hasMutableProperties: hasMutableProperties)
    }
}