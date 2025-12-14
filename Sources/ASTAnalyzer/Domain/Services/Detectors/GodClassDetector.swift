//
//  GodClassDetector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  God Class detector based on Z notation specifications
//

import Foundation
import SwiftSyntax

/**
 God Class Detector based on Z notation:
 ```
 GodClassDetector
 ├─ isGodClass : Class → 𝔹
 ├─ godClassSeverity : Class → ℝ
 └─ ∀ c : Class •
     isGodClass(c) ⇔ ATFD(c) > θ_ATFD_GodClass ∧
                     WMC(c) ≥ θ_WMC_GodClass ∧
                     TCC(c) < θ_TCC_GodClass
 ```
 */
public final class GodClassDetector: BaseDefectDetector {

    private let thresholds: Thresholds

    public init(thresholds: Thresholds = .academic) {
        self.thresholds = thresholds
        super.init(detectableDefects: [.godClass])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        let sourceText = sourceFile.description

        // Analyze classes
        let classVisitor = GodClassVisitor(thresholds: thresholds)
        classVisitor.walk(sourceFile)

        for (className, (godClassInfo, position)) in classVisitor.godClasses {
            let lineNumber = calculateLineNumber(from: position, in: sourceText)
            let defect = godClassInfo.createDefect(name: className, type: "class", filePath: filePath) { fp, ctx in
                self.createLocation(filePath: fp, lineNumber: lineNumber, context: ctx)
            }
            defects.append(defect)
        }

        // Analyze structs (can also be God Classes)
        let structVisitor = GodStructVisitor(thresholds: thresholds)
        structVisitor.walk(sourceFile)

        for (structName, (godClassInfo, position)) in structVisitor.godStructs {
            let lineNumber = calculateLineNumber(from: position, in: sourceText)
            let defect = godClassInfo.createDefect(name: structName, type: "struct", filePath: filePath) { fp, ctx in
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

// MARK: - God Class Analysis Info

private struct GodClassInfo {
    let atfd: Int
    let wmc: Int
    let tcc: Double
    let severity: Severity

    init(atfd: Int, wmc: Int, tcc: Double, thresholds: Thresholds) {
        self.atfd = atfd
        self.wmc = wmc
        self.tcc = tcc

        // Calculate severity based on Z notation formula
        let s1 = min(1.0, Double(atfd) / (2.0 * Double(thresholds.classSmells.godClassATFD)))
        let s2 = min(1.0, Double(wmc) / (2.0 * Double(thresholds.classSmells.godClassWMC)))
        let s3 = max(0.0, (thresholds.classSmells.godClassTCC - tcc) / thresholds.classSmells.godClassTCC)
        let severityScore = (s1 + s2 + s3) / 3.0

        if severityScore >= 0.8 {
            self.severity = .critical
        } else if severityScore >= 0.6 {
            self.severity = .high
        } else if severityScore >= 0.4 {
            self.severity = .medium
        } else {
            self.severity = .low
        }
    }

    /// Creates an architectural defect for this god class/struct
    func createDefect(name: String, type: String, filePath: String, createLocation: (String, String) -> Location) -> ArchitecturalDefect {
        return ArchitecturalDefect(
            type: .godClass,
            severity: severity,
            message: "\(type.capitalized) '\(name)' is a God Class (ATFD: \(atfd), WMC: \(wmc), TCC: \(String(format: "%.2f", tcc)))",
            location: createLocation(filePath, "\(type) \(name)"),
            suggestion: "Split this \(type) into smaller, more focused \(type == "class" ? "classes" : "structs") with single responsibilities"
        )
    }
}

// MARK: - Private Visitors

private class GodClassVisitor: SyntaxVisitor {
    let thresholds: Thresholds
    var godClasses: [(String, (GodClassInfo, AbsolutePosition))] = []

    init(thresholds: Thresholds) {
        self.thresholds = thresholds
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let analyzer = GodClassAnalyzer(classDecl: node, thresholds: thresholds)
        if let godClassInfo = analyzer.analyze() {
            let position = node.positionAfterSkippingLeadingTrivia
            godClasses.append((node.name.text, (godClassInfo, position)))
        }
        return .visitChildren
    }
}

private class GodStructVisitor: SyntaxVisitor {
    let thresholds: Thresholds
    var godStructs: [(String, (GodClassInfo, AbsolutePosition))] = []

    init(thresholds: Thresholds) {
        self.thresholds = thresholds
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let analyzer = GodStructAnalyzer(structDecl: node, thresholds: thresholds)
        if let godClassInfo = analyzer.analyze() {
            let position = node.positionAfterSkippingLeadingTrivia
            godStructs.append((node.name.text, (godClassInfo, position)))
        }
        return .visitChildren
    }
}

// MARK: - Analysis Helpers

private class GodClassAnalyzer {
    let classDecl: ClassDeclSyntax
    let thresholds: Thresholds

    init(classDecl: ClassDeclSyntax, thresholds: Thresholds) {
        self.classDecl = classDecl
        self.thresholds = thresholds
    }

    func analyze() -> GodClassInfo? {
        // Extract metrics from AST
        let metrics = extractMetrics()

        // Check God Class conditions
        let smells = thresholds.checkClassSmells(wmc: metrics.wmc, tcc: metrics.tcc, atfd: metrics.atfd, lcom5: 0, nof: 0, nom: 0, woa: 0, dit: 0)
        let isGodClass = smells["godClass"] ?? false

        return isGodClass ? GodClassInfo(
            atfd: metrics.atfd,
            wmc: metrics.wmc,
            tcc: metrics.tcc,
            thresholds: thresholds
        ) : nil
    }

    private func extractMetrics() -> (atfd: Int, wmc: Int, tcc: Double) {
        var methods: [MethodInfo] = []
        var attributes: [AttributeInfo] = []
        var foreignDataAccess = Set<String>()

        // Extract methods and their properties
        for member in classDecl.memberBlock.members {
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                let methodInfo = MethodInfo(funcDecl: funcDecl)
                methods.append(methodInfo)

                // Analyze foreign data access (simplified heuristic)
                if let body = funcDecl.body?.description {
                    // Look for external property access patterns
                    let externalPatterns = [
                        "UserDefaults\\.standard",
                        "NotificationCenter\\.default",
                        "UIApplication\\.shared",
                        "Bundle\\.main",
                        "ProcessInfo\\.processInfo"
                    ]

                    for pattern in externalPatterns {
                        if body.contains(pattern) {
                            foreignDataAccess.insert(pattern)
                        }
                    }
                }
            }

            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in varDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        attributes.append(AttributeInfo(name: identifier.identifier.text, varDecl: varDecl))
                    }
                }
            }
        }

        // Calculate WMC (simplified - using method count as proxy for complexity)
        let wmc = methods.reduce(0) { $0 + $1.complexity }

        // Calculate TCC (simplified cohesion metric)
        let tcc = calculateTCC(methods: methods, attributes: attributes)

        return (atfd: foreignDataAccess.count, wmc: wmc, tcc: tcc)
    }

    private func calculateTCC(methods: [MethodInfo], attributes: [AttributeInfo]) -> Double {
        guard methods.count > 1 else { return 1.0 }

        let visibleMethods = methods.filter { $0.isVisible }
        guard visibleMethods.count > 1 else { return 1.0 }

        let n = visibleMethods.count
        let maxPairs = n * (n - 1) / 2
        var connectedPairs = 0

        // Simplified: methods are connected if they reference common attributes
        for i in 0..<visibleMethods.count {
            for j in (i+1)..<visibleMethods.count {
                let method1 = visibleMethods[i]
                let method2 = visibleMethods[j]

                let commonAttributes = method1.accessedAttributes.intersection(method2.accessedAttributes)
                if !commonAttributes.isEmpty {
                    connectedPairs += 1
                }
            }
        }

        return Double(connectedPairs) / Double(maxPairs)
    }
}

private class GodStructAnalyzer {
    let structDecl: StructDeclSyntax
    let thresholds: Thresholds

    init(structDecl: StructDeclSyntax, thresholds: Thresholds) {
        self.structDecl = structDecl
        self.thresholds = thresholds
    }

    func analyze() -> GodClassInfo? {
        // Similar analysis for structs
        let metrics = extractMetrics()

        let smells = thresholds.checkClassSmells(wmc: metrics.wmc, tcc: metrics.tcc, atfd: metrics.atfd, lcom5: 0, nof: 0, nom: 0, woa: 0, dit: 0)
        let isGodClass = smells["godClass"] ?? false

        return isGodClass ? GodClassInfo(
            atfd: metrics.atfd,
            wmc: metrics.wmc,
            tcc: metrics.tcc,
            thresholds: thresholds
        ) : nil
    }

    private func extractMetrics() -> (atfd: Int, wmc: Int, tcc: Double) {
        // Similar to class analysis but for structs
        var methods: [MethodInfo] = []
        var attributes: [AttributeInfo] = []
        var foreignDataAccess = Set<String>()

        for member in structDecl.memberBlock.members {
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                let methodInfo = MethodInfo(funcDecl: funcDecl)
                methods.append(methodInfo)

                if let body = funcDecl.body?.description {
                    let externalPatterns = [
                        "UserDefaults\\.standard",
                        "NotificationCenter\\.default",
                        "UIApplication\\.shared"
                    ]

                    for pattern in externalPatterns {
                        if body.contains(pattern) {
                            foreignDataAccess.insert(pattern)
                        }
                    }
                }
            }

            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in varDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        attributes.append(AttributeInfo(name: identifier.identifier.text, varDecl: varDecl))
                    }
                }
            }
        }

        let wmc = methods.reduce(0) { $0 + $1.complexity }
        let tcc = calculateTCC(methods: methods, attributes: attributes)

        return (atfd: foreignDataAccess.count, wmc: wmc, tcc: tcc)
    }

    private func calculateTCC(methods: [MethodInfo], attributes: [AttributeInfo]) -> Double {
        guard methods.count > 1 else { return 1.0 }

        let visibleMethods = methods.filter { $0.isVisible }
        guard visibleMethods.count > 1 else { return 1.0 }

        let n = visibleMethods.count
        let maxPairs = n * (n - 1) / 2
        var connectedPairs = 0

        for i in 0..<visibleMethods.count {
            for j in (i+1)..<visibleMethods.count {
                let method1 = visibleMethods[i]
                let method2 = visibleMethods[j]

                let commonAttributes = method1.accessedAttributes.intersection(method2.accessedAttributes)
                if !commonAttributes.isEmpty {
                    connectedPairs += 1
                }
            }
        }

        return Double(connectedPairs) / Double(maxPairs)
    }
}

// MARK: - Helper Structures

private struct MethodInfo {
    let name: String
    let complexity: Int
    let isVisible: Bool
    let accessedAttributes: Set<String>

    init(funcDecl: FunctionDeclSyntax) {
        self.name = funcDecl.name.text

        // Simplified complexity calculation
        let loc = funcDecl.body?.statements.count ?? 0
        let params = funcDecl.signature.parameterClause.parameters.count
        self.complexity = max(1, loc / 10 + params)

        // Visibility check
        self.isVisible = funcDecl.modifiers.contains { modifier in
            modifier.name.tokenKind == .keyword(.public) ||
            modifier.name.tokenKind == .keyword(.open) ||
            modifier.name.tokenKind == .keyword(.internal)
        }

        // Extract accessed attributes (simplified)
        var accessed = Set<String>()
        if let body = funcDecl.body?.description {
            // Look for self.property patterns
            let selfPropertyPattern = "self\\.([a-zA-Z_][a-zA-Z0-9_]*)"
            if let regex = try? NSRegularExpression(pattern: selfPropertyPattern, options: []) {
                let matches = regex.matches(in: body, options: [], range: NSRange(location: 0, length: body.count))
                for match in matches {
                    if let range = Range(match.range(at: 1), in: body) {
                        accessed.insert(String(body[range]))
                    }
                }
            }
        }
        self.accessedAttributes = accessed
    }
}

private struct AttributeInfo {
    let name: String
    let isVisible: Bool

    init(name: String, varDecl: VariableDeclSyntax) {
        self.name = name
        self.isVisible = varDecl.modifiers.contains { modifier in
            modifier.name.tokenKind == .keyword(.public) ||
            modifier.name.tokenKind == .keyword(.open) ||
            modifier.name.tokenKind == .keyword(.internal)
        }
    }
}