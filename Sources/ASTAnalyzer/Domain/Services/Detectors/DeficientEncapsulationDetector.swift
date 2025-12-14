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
        let attributes = extractAttributes(from: classDecl)
        let tempClass = createTempClass(from: classDecl, with: attributes)
        let woa = calculateWOA(for: tempClass)
        let exposedFieldsCount = countExposedFields(in: attributes)

        // Classes can always have mutable properties, so this is always true for classes
        return (woa: woa, exposedFieldsCount: exposedFieldsCount, hasMutableProperties: true)
    }

    private func extractAttributes(from classDecl: ClassDeclSyntax) -> Set<Attribute> {
        var attributes = Set<Attribute>()

        for member in classDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }

            for binding in varDecl.bindings {
                guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }

                let accessLevel = determineAccessLevel(for: varDecl)
                let isComputed = varDecl.bindings.first?.initializer == nil
                let (hasGetter, hasSetter) = determineGetterSetterAvailability(for: varDecl, isComputed: isComputed)

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

        return attributes
    }

    private func determineAccessLevel(for varDecl: VariableDeclSyntax) -> AccessLevel {
        if varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.public) }) {
            return .public
        } else if varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.open) }) {
            return .open
        } else {
            return .internal
        }
    }

    private func determineGetterSetterAvailability(for varDecl: VariableDeclSyntax, isComputed: Bool) -> (hasGetter: Bool, hasSetter: Bool) {
        let hasGetter = !isComputed || determineAccessLevel(for: varDecl) != .private
        let hasSetter = !isComputed && !varDecl.modifiers.contains(where: {
            $0.name.tokenKind == .keyword(.let)
        })
        return (hasGetter, hasSetter)
    }

    private func createTempClass(from classDecl: ClassDeclSyntax, with attributes: Set<Attribute>) -> Class {
        Class(
            name: classDecl.name.text,
            attributes: attributes,
            loc: { let description = classDecl.description; return description.components(separatedBy: "\n").count }()
        )
    }

    private func calculateWOA(for tempClass: Class) -> Double {
        WOA_Calculator.calculate(for: tempClass)
    }

    private func countExposedFields(in attributes: Set<Attribute>) -> Int {
        attributes.filter { attr in
            [.public, .open].contains(attr.accessLevel) &&
            !attr.isComputed &&
            attr.hasSetter
        }.count
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
        let attributes = extractAttributes(from: structDecl)
        let hasMutableProperties = checkForMutableProperties(in: attributes)
        let tempClass = createTempClass(from: structDecl, with: attributes)
        let woa = calculateWOA(for: tempClass)
        let exposedFieldsCount = countExposedFields(in: attributes)

        return (woa: woa, exposedFieldsCount: exposedFieldsCount, hasMutableProperties: hasMutableProperties)
    }

    private func extractAttributes(from structDecl: StructDeclSyntax) -> Set<Attribute> {
        var attributes = Set<Attribute>()

        for member in structDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }

            for binding in varDecl.bindings {
                guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }

                let accessLevel = determineAccessLevel(for: varDecl)
                let isComputed = varDecl.bindings.first?.initializer == nil
                let isLetDeclaration = varDecl.bindingSpecifier.tokenKind == .keyword(.let)
                let (hasGetter, hasSetter) = determineGetterSetterAvailability(for: varDecl, isComputed: isComputed, isLetDeclaration: isLetDeclaration)

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

        return attributes
    }

    private func checkForMutableProperties(in attributes: Set<Attribute>) -> Bool {
        attributes.contains { !$0.isComputed && $0.hasSetter }
    }

    private func determineAccessLevel(for varDecl: VariableDeclSyntax) -> AccessLevel {
        if varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.public) }) {
            return .public
        } else if varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.open) }) {
            return .open
        } else {
            return .internal
        }
    }

    private func determineGetterSetterAvailability(for varDecl: VariableDeclSyntax, isComputed: Bool, isLetDeclaration: Bool) -> (hasGetter: Bool, hasSetter: Bool) {
        let hasGetter = !isComputed || determineAccessLevel(for: varDecl) != .private
        let hasSetter = !isComputed && !isLetDeclaration
        return (hasGetter, hasSetter)
    }

    private func createTempClass(from structDecl: StructDeclSyntax, with attributes: Set<Attribute>) -> Class {
        Class(
            name: structDecl.name.text,
            attributes: attributes,
            loc: { let description = structDecl.description; return description.components(separatedBy: "\n").count }()
        )
    }

    private func calculateWOA(for tempClass: Class) -> Double {
        WOA_Calculator.calculate(for: tempClass)
    }

    private func countExposedFields(in attributes: Set<Attribute>) -> Int {
        attributes.filter { attr in
            [.public, .open].contains(attr.accessLevel) &&
            !attr.isComputed &&
            attr.hasSetter
        }.count
    }
}