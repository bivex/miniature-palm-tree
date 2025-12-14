//
//  MassiveViewControllerDetector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Massive View Controller detector based on Z notation specifications
//

import Foundation
import SwiftSyntax

/**
 Massive View Controller Detector based on Z notation:
 ```
 MassiveViewControllerDetector
 ├─ isMassiveVC : Class → 𝔹
 ├─ vcComplexityScore : Class → ℝ
 └─ ∀ c : Class •
     isMassiveVC(c) ⇔ c.isViewController ∧
                     (LOC(c) > θ_LOC_GodClass ∨
                      NOM(c) > θ_NOM_MassiveVC ∨
                      NOA(c) > θ_NOA_MassiveVC ∨
                      WMC(c) > θ_WMC_GodClass)

     vcComplexityScore(c) = (LOC(c) / θ_LOC_GodClass) × 0.3 +
                           (NOM(c) / θ_NOM_MassiveVC) × 0.25 +
                           (NOA(c) / θ_NOA_MassiveVC) × 0.2 +
                           (WMC(c) / θ_WMC_GodClass) × 0.25
 ```
 */
public final class MassiveViewControllerDetector: BaseDefectDetector {

    private let thresholds: Thresholds

    public init(thresholds: Thresholds = .academic) {
        self.thresholds = thresholds
        super.init(detectableDefects: [.massiveViewController])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        let sourceText = sourceFile.description

        // Analyze classes
        let classVisitor = MassiveVCVisitor(thresholds: thresholds)
        classVisitor.walk(sourceFile)

        for (className, (massiveVCInfo, position)) in classVisitor.massiveVCs {
            let lineNumber = calculateLineNumber(from: position, in: sourceText)
            let defect = massiveVCInfo.createDefect(name: className, filePath: filePath) { fp, ctx in
                self.createLocation(filePath: fp, lineNumber: lineNumber, context: ctx)
            }
            defects.append(defect)
        }

        // Analyze structs (can also be View Controllers)
        let structVisitor = MassiveVCStructVisitor(thresholds: thresholds)
        structVisitor.walk(sourceFile)

        for (structName, (massiveVCInfo, position)) in structVisitor.massiveVCStructs {
            let lineNumber = calculateLineNumber(from: position, in: sourceText)
            let defect = massiveVCInfo.createDefect(name: structName, filePath: filePath) { fp, ctx in
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

// MARK: - Massive VC Analysis Info

private struct MassiveVCInfo {
    let loc: Int
    let nom: Int
    let noa: Int
    let wmc: Int
    let complexityScore: Double
    let severity: Severity

    init(loc: Int, nom: Int, noa: Int, wmc: Int, thresholds: Thresholds) {
        self.loc = loc
        self.nom = nom
        self.noa = noa
        self.wmc = wmc

        // Calculate complexity score based on Z notation formula
        let locScore = Double(loc) / Double(thresholds.classSmells.godClassLOC)
        let nomScore = Double(nom) / Double(thresholds.classSmells.massiveVCNOM)
        let noaScore = Double(noa) / Double(thresholds.classSmells.massiveVCNOA)
        let wmcScore = Double(wmc) / Double(thresholds.classSmells.godClassWMC)

        self.complexityScore = (locScore * 0.3) + (nomScore * 0.25) + (noaScore * 0.2) + (wmcScore * 0.25)

        // Determine severity based on complexity score
        if complexityScore >= 1.5 {
            self.severity = .critical
        } else if complexityScore >= 1.2 {
            self.severity = .high
        } else if complexityScore >= 1.0 {
            self.severity = .medium
        } else {
            self.severity = .low
        }
    }

    /// Creates an architectural defect for this massive view controller
    func createDefect(name: String, filePath: String, createLocation: (String, String) -> Location) -> ArchitecturalDefect {
        return ArchitecturalDefect(
            type: .massiveViewController,
            severity: severity,
            message: "View Controller '\(name)' is a Massive View Controller (LOC: \(loc), NOM: \(nom), NOA: \(noa), WMC: \(wmc), complexity: \(String(format: "%.2f", complexityScore)))",
            location: createLocation(filePath, "class \(name)"),
            suggestion: "Split this view controller into smaller components or use MVVM/MVP architecture to separate concerns"
        )
    }
}

// MARK: - Private Visitors

private class MassiveVCVisitor: SyntaxVisitor {
    let thresholds: Thresholds
    var massiveVCs: [(String, (MassiveVCInfo, AbsolutePosition))] = []

    init(thresholds: Thresholds) {
        self.thresholds = thresholds
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        // Check if this class is a View Controller
        if isViewController(node) {
            let analyzer = MassiveVCAnalyzer(classDecl: node, thresholds: thresholds)
            if let massiveVCInfo = analyzer.analyze() {
                let position = node.positionAfterSkippingLeadingTrivia
                massiveVCs.append((node.name.text, (massiveVCInfo, position)))
            }
        }
        return .visitChildren
    }

    private func isViewController(_ classDecl: ClassDeclSyntax) -> Bool {
        let className = classDecl.name.text

        // Check if class name contains ViewController
        if className.contains("ViewController") {
            return true
        }

        // Check inheritance from UIViewController or NSViewController
        if let inheritanceClause = classDecl.inheritanceClause {
            for inheritedType in inheritanceClause.inheritedTypes {
                let typeName = inheritedType.type.description
                if typeName == "UIViewController" || typeName == "NSViewController" ||
                   typeName.contains("UIViewController") || typeName.contains("NSViewController") {
                    return true
                }
            }
        }

        // Check for @objc attribute with ViewController in name
        for attribute in classDecl.attributes {
            if let attributeSyntax = attribute.as(AttributeSyntax.self),
               attributeSyntax.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "objc" {
                return className.contains("ViewController")
            }
        }

        return false
    }
}

private class MassiveVCStructVisitor: SyntaxVisitor {
    let thresholds: Thresholds
    var massiveVCStructs: [(String, (MassiveVCInfo, AbsolutePosition))] = []

    init(thresholds: Thresholds) {
        self.thresholds = thresholds
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        // Structs are rarely View Controllers, but check just in case
        if isViewController(node) {
            let analyzer = MassiveVCStructAnalyzer(structDecl: node, thresholds: thresholds)
            if let massiveVCInfo = analyzer.analyze() {
                let position = node.positionAfterSkippingLeadingTrivia
                massiveVCStructs.append((node.name.text, (massiveVCInfo, position)))
            }
        }
        return .visitChildren
    }

    private func isViewController(_ structDecl: StructDeclSyntax) -> Bool {
        let structName = structDecl.name.text
        return structName.contains("ViewController")
    }
}

// MARK: - Analysis Helpers

private class MassiveVCAnalyzer {
    let classDecl: ClassDeclSyntax
    let thresholds: Thresholds

    init(classDecl: ClassDeclSyntax, thresholds: Thresholds) {
        self.classDecl = classDecl
        self.thresholds = thresholds
    }

    func analyze() -> MassiveVCInfo? {
        let metrics = extractMetrics()

        // Check Massive View Controller conditions based on Z notation
        let isMassiveVC = metrics.loc > thresholds.classSmells.godClassLOC ||
                         metrics.nom > thresholds.classSmells.massiveVCNOM ||
                         metrics.noa > thresholds.classSmells.massiveVCNOA ||
                         metrics.wmc > thresholds.classSmells.godClassWMC

        return isMassiveVC ? MassiveVCInfo(
            loc: metrics.loc,
            nom: metrics.nom,
            noa: metrics.noa,
            wmc: metrics.wmc,
            thresholds: thresholds
        ) : nil
    }

    private func extractMetrics() -> (loc: Int, nom: Int, noa: Int, wmc: Int) {
        var methods: [MethodInfo] = []
        var attributes: [AttributeInfo] = []

        // Extract methods and attributes
        for member in classDecl.memberBlock.members {
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                let methodInfo = MethodInfo(funcDecl: funcDecl)
                methods.append(methodInfo)
            }

            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in varDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        attributes.append(AttributeInfo(name: identifier.identifier.text, varDecl: varDecl))
                    }
                }
            }
        }

        // Calculate metrics
        let loc = classDecl.description.components(separatedBy: "\n").count
        let nom = methods.count
        let noa = attributes.filter { !$0.isComputed }.count
        let wmc = methods.reduce(0) { $0 + $1.complexity }

        return (loc: loc, nom: nom, noa: noa, wmc: wmc)
    }
}

private class MassiveVCStructAnalyzer {
    let structDecl: StructDeclSyntax
    let thresholds: Thresholds

    init(structDecl: StructDeclSyntax, thresholds: Thresholds) {
        self.structDecl = structDecl
        self.thresholds = thresholds
    }

    func analyze() -> MassiveVCInfo? {
        let metrics = extractMetrics()

        let isMassiveVC = metrics.loc > thresholds.classSmells.godClassLOC ||
                         metrics.nom > thresholds.classSmells.massiveVCNOM ||
                         metrics.noa > thresholds.classSmells.massiveVCNOA ||
                         metrics.wmc > thresholds.classSmells.godClassWMC

        return isMassiveVC ? MassiveVCInfo(
            loc: metrics.loc,
            nom: metrics.nom,
            noa: metrics.noa,
            wmc: metrics.wmc,
            thresholds: thresholds
        ) : nil
    }

    private func extractMetrics() -> (loc: Int, nom: Int, noa: Int, wmc: Int) {
        var methods: [MethodInfo] = []
        var attributes: [AttributeInfo] = []

        for member in structDecl.memberBlock.members {
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                let methodInfo = MethodInfo(funcDecl: funcDecl)
                methods.append(methodInfo)
            }

            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in varDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        attributes.append(AttributeInfo(name: identifier.identifier.text, varDecl: varDecl))
                    }
                }
            }
        }

        let loc = structDecl.description.components(separatedBy: "\n").count
        let nom = methods.count
        let noa = attributes.filter { !$0.isComputed }.count
        let wmc = methods.reduce(0) { $0 + $1.complexity }

        return (loc: loc, nom: nom, noa: noa, wmc: wmc)
    }
}

// MARK: - Helper Structures

private struct MethodInfo {
    let complexity: Int

    init(funcDecl: FunctionDeclSyntax) {
        // Simplified complexity calculation
        let loc = funcDecl.body?.statements.count ?? 0
        let params = funcDecl.signature.parameterClause.parameters.count
        self.complexity = max(1, loc / 10 + params)
    }
}

private struct AttributeInfo {
    let name: String
    let isComputed: Bool

    init(name: String, varDecl: VariableDeclSyntax) {
        self.name = name
        // Check if this is a computed property - if any binding has an accessor block
        let hasAccessorBlock = varDecl.bindings.contains { binding in
            binding.accessorBlock != nil
        }
        self.isComputed = hasAccessorBlock
    }
}
