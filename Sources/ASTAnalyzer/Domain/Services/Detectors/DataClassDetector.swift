//
//  DataClassDetector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Data Class detector based on Z notation specifications
//

import Foundation
import SwiftSyntax

/**
 Data Class Detector based on Z notation:
 ```
 DataClassDetector
 ├─ isDataClass : Class → 𝔹
 ├─ dataClassScore : Class → ℝ
 └─ ∀ c : Class •
     let publicGetters == #{a : c.attributes | a.accessLevel ∈ {public, open} ∧ a.hasGetter}
         publicSetters == #{a : c.attributes | a.accessLevel ∈ {public, open} ∧ a.hasSetter}
         complexMethods == #{m : c.methods | m.cyclomaticComplexity > 2 ∧ m.name ∉ {"init", "deinit"}}
     in
       isDataClass(c) ⇔ NOF(c) > 5 ∧
                        (publicGetters + publicSetters) / (2 × NOF(c)) > 0.7 ∧
                        complexMethods < 3 ∧
                        LCOM5(c) > 0.8
 ```
 */
public final class DataClassDetector: BaseDefectDetector {

    private let thresholds: Thresholds

    public init(thresholds: Thresholds = .academic) {
        self.thresholds = thresholds
        super.init(detectableDefects: [.dataClass])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        // Analyze classes
        let classVisitor = DataClassVisitor(thresholds: thresholds)
        classVisitor.walk(sourceFile)

        for (className, dataClassInfo) in classVisitor.dataClasses {
            let defect = dataClassInfo.createDefect(name: className, type: "class", filePath: filePath) { fp, ctx in
                self.createLocation(filePath: fp, context: ctx)
            }
            defects.append(defect)
        }

        // Analyze structs
        let structVisitor = DataStructVisitor(thresholds: thresholds)
        structVisitor.walk(sourceFile)

        for (structName, dataClassInfo) in structVisitor.dataStructs {
            let defect = dataClassInfo.createDefect(name: structName, type: "struct", filePath: filePath) { fp, ctx in
                self.createLocation(filePath: fp, context: ctx)
            }
            defects.append(defect)
        }

        return defects
    }
}

// MARK: - Data Class Analysis Info

private struct DataClassInfo {
    let nof: Int
    let accessorRatio: Double
    let lcom5: Double
    let score: Double
    let severity: Severity

    init(nof: Int, accessorRatio: Double, lcom5: Double) {
        self.nof = nof
        self.accessorRatio = accessorRatio
        self.lcom5 = lcom5

        // Calculate data class score based on Z notation formula
        let accessorComponent = accessorRatio
        let methodComponent = min(1.0, Double(3) / 5.0) // complexMethods < 3, inverted
        let cohesionComponent = lcom5

        self.score = accessorComponent * methodComponent * cohesionComponent

        // Determine severity
        if score >= 0.8 {
            self.severity = .high
        } else if score >= 0.6 {
            self.severity = .medium
        } else {
            self.severity = .low
        }
    }

    /// Creates an architectural defect for this data class/struct
    func createDefect(name: String, type: String, filePath: String, createLocation: (String, String) -> Location) -> ArchitecturalDefect {
        return ArchitecturalDefect(
            type: .dataClass,
            severity: severity,
            message: "\(type.capitalized) '\(name)' is a Data Class (NOF: \(nof), accessors: \(accessorRatio), LCOM5: \(String(format: "%.2f", lcom5)))",
            location: createLocation(filePath, "\(type) \(name)"),
            suggestion: "Move behavior into this \(type) or make fields private and add proper encapsulation methods"
        )
    }
}

// MARK: - Private Visitors

private class DataClassVisitor: SyntaxVisitor {
    let thresholds: Thresholds
    var dataClasses: [(String, DataClassInfo)] = []

    init(thresholds: Thresholds) {
        self.thresholds = thresholds
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let analyzer = DataClassAnalyzer(classDecl: node)
        if let dataClassInfo = analyzer.analyze() {
            dataClasses.append((node.name.text, dataClassInfo))
        }
        return .visitChildren
    }
}

private class DataStructVisitor: SyntaxVisitor {
    let thresholds: Thresholds
    var dataStructs: [(String, DataClassInfo)] = []

    init(thresholds: Thresholds) {
        self.thresholds = thresholds
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let analyzer = DataStructAnalyzer(structDecl: node)
        if let dataClassInfo = analyzer.analyze() {
            dataStructs.append((node.name.text, dataClassInfo))
        }
        return .visitChildren
    }
}

// MARK: - Metrics Structure

private struct ClassMetrics {
    let nof: Int
    let accessorRatio: Double
    let complexMethods: Int
    let lcom5: Double

    /// Determines if these metrics indicate a data class and returns the info if so
    func asDataClassInfo() -> DataClassInfo? {
        // Check Data Class conditions based on Z notation
        let isDataClass = nof > 5 &&
                         accessorRatio > 0.7 &&
                         complexMethods < 3 &&
                         lcom5 > 0.8

        return isDataClass ? DataClassInfo(
            nof: nof,
            accessorRatio: accessorRatio,
            lcom5: lcom5
        ) : nil
    }

    /// Determines if these metrics indicate a data struct and returns the info if so
    func asDataStructInfo() -> DataClassInfo? {
        // Structs are more commonly data classes, so we use slightly different thresholds
        let isDataClass = nof > 3 &&
                         accessorRatio > 0.8 &&
                         complexMethods < 2 &&
                         lcom5 > 0.7

        return isDataClass ? DataClassInfo(
            nof: nof,
            accessorRatio: accessorRatio,
            lcom5: lcom5
        ) : nil
    }
}

// MARK: - Analysis Helpers

private class DataClassAnalyzer {
    let classDecl: ClassDeclSyntax

    init(classDecl: ClassDeclSyntax) {
        self.classDecl = classDecl
    }

    func analyze() -> DataClassInfo? {
        let metrics = extractMetrics()
        return metrics.asDataClassInfo()
    }

    private func extractMetrics() -> ClassMetrics {
        var fields: [FieldInfo] = []
        var methods: [MethodInfo] = []

        // Extract fields and methods
        for member in classDecl.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in varDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        let fieldInfo = FieldInfo(name: identifier.identifier.text, varDecl: varDecl)
                        fields.append(fieldInfo)
                    }
                }
            }

            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                let methodInfo = MethodInfo(funcDecl: funcDecl)
                methods.append(methodInfo)
            }
        }

        let nof = fields.count

        // Calculate accessor ratio
        let publicGetters = fields.filter { $0.hasGetter && $0.isPublic }.count
        let publicSetters = fields.filter { $0.hasSetter && $0.isPublic }.count
        let accessorRatio = nof > 0 ? Double(publicGetters + publicSetters) / Double(2 * nof) : 0.0

        // Count complex methods
        let complexMethods = methods.filter { method in
            method.complexity > 2 && !["init", "deinit"].contains(method.name)
        }.count

        // Calculate LCOM5 (simplified)
        let lcom5 = calculateLCOM5(fields: fields, methods: methods)

        return ClassMetrics(nof: nof, accessorRatio: accessorRatio, complexMethods: complexMethods, lcom5: lcom5)
    }

    private func calculateLCOM5(fields: [FieldInfo], methods: [MethodInfo]) -> Double {
        let m = Double(methods.count)
        let a = Double(fields.count)

        guard a > 0 && m > 1 else { return 0.0 }

        // Simplified: assume each method accesses some fields
        let sumAccess = methods.reduce(0.0) { total, method in
            // Estimate: assume method accesses 1-3 fields on average
            total + min(3.0, Double(fields.count) * 0.5)
        }

        let lcom5 = (m - sumAccess / a) / (m - 1)
        return max(0.0, min(1.0, lcom5))
    }
}

private class DataStructAnalyzer {
    let structDecl: StructDeclSyntax

    init(structDecl: StructDeclSyntax) {
        self.structDecl = structDecl
    }

    func analyze() -> DataClassInfo? {
        let metrics = extractMetrics()
        return metrics.asDataStructInfo()
    }

    private func extractMetrics() -> ClassMetrics {
        var fields: [FieldInfo] = []
        var methods: [MethodInfo] = []

        // Extract fields and methods
        for member in structDecl.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in varDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        let fieldInfo = FieldInfo(name: identifier.identifier.text, varDecl: varDecl)
                        fields.append(fieldInfo)
                    }
                }
            }

            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                let methodInfo = MethodInfo(funcDecl: funcDecl)
                methods.append(methodInfo)
            }
        }

        let nof = fields.count

        // Calculate accessor ratio (structs often have public access by default)
        let publicGetters = fields.filter { $0.hasGetter && $0.isPublic }.count
        let publicSetters = fields.filter { $0.hasSetter && $0.isPublic }.count
        let accessorRatio = nof > 0 ? Double(publicGetters + publicSetters) / Double(2 * nof) : 0.0

        // Count complex methods
        let complexMethods = methods.filter { method in
            method.complexity > 2 && !["init", "deinit"].contains(method.name)
        }.count

        // Calculate LCOM5
        let lcom5 = calculateLCOM5(fields: fields, methods: methods)

        return ClassMetrics(nof: nof, accessorRatio: accessorRatio, complexMethods: complexMethods, lcom5: lcom5)
    }

    private func calculateLCOM5(fields: [FieldInfo], methods: [MethodInfo]) -> Double {
        let m = Double(methods.count)
        let a = Double(fields.count)

        guard a > 0 && m > 1 else { return 0.0 }

        let sumAccess = methods.reduce(0.0) { total, method in
            total + min(3.0, Double(fields.count) * 0.5)
        }

        let lcom5 = (m - sumAccess / a) / (m - 1)
        return max(0.0, min(1.0, lcom5))
    }
}

// MARK: - Helper Structures

private struct FieldInfo {
    let name: String
    let isPublic: Bool
    let hasGetter: Bool
    let hasSetter: Bool

    init(name: String, varDecl: VariableDeclSyntax) {
        self.name = name

        // Check if public
        self.isPublic = varDecl.modifiers.contains { modifier in
            modifier.name.tokenKind == .keyword(.public) ||
            modifier.name.tokenKind == .keyword(.open)
        }

        // For stored properties, assume getters and setters based on modifiers
        let isPrivate = varDecl.modifiers.contains { modifier in
            modifier.name.tokenKind == .keyword(.private)
        }

        let isLet = varDecl.bindingSpecifier.tokenKind == .keyword(.let)

        self.hasGetter = !isPrivate
        self.hasSetter = !isPrivate && !isLet
    }
}

private struct MethodInfo {
    let name: String
    let complexity: Int

    init(funcDecl: FunctionDeclSyntax) {
        self.name = funcDecl.name.text

        // Simplified complexity calculation
        let loc = funcDecl.body?.statements.count ?? 0
        let params = funcDecl.signature.parameterClause.parameters.count
        self.complexity = max(1, loc / 5 + params)
    }
}