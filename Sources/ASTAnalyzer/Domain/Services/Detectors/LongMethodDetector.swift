//
//  LongMethodDetector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Long Method detector based on Z notation specifications
//

import Foundation
import SwiftSyntax
import SwiftParser

/**
 Long Method Detector based on Z notation:
 ```
 LongMethodDetector
 ├─ isLongMethod : Method → 𝔹
 ├─ methodComplexity : Method → ℝ
 └─ ∀ m : Method •
     isLongMethod(m) ⇔ m.loc > θ_LOC_LongMethod ∨
                       NOI(m) > θ_NOI_LongMethod ∨
                       m.cyclomaticComplexity > θ_CC_LongMethod
 ```
 */
public final class LongMethodDetector: BaseDefectDetector {

    private let thresholds: Thresholds

    public init(thresholds: Thresholds = .academic) {
        self.thresholds = thresholds
        super.init(detectableDefects: [.longMethod])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        let sourceText = sourceFile.description
        let methodVisitor = LongMethodVisitor(thresholds: thresholds, filePath: filePath, sourceText: sourceText)
        methodVisitor.walk(sourceFile)

        for violation in methodVisitor.longMethodViolations {
            let defect = ArchitecturalDefect(
                type: .longMethod,
                severity: violation.severity,
                message: "Method '\(violation.methodName)' is too long (\(violation.loc) lines, complexity: \(violation.complexity), instructions: \(violation.instructionCount))",
                location: createLocation(filePath: filePath, lineNumber: violation.lineNumber, context: "method \(violation.methodName)"),
                suggestion: "Break this method into smaller, more focused methods with single responsibilities"
            )
            defects.append(defect)
        }

        return defects
    }
}

// MARK: - Long Method Violation Info

private struct LongMethodViolation {
    let methodName: String
    let lineNumber: Int?
    let loc: Int
    let complexity: Int
    let instructionCount: Int
    let severity: Severity

    init(methodName: String, lineNumber: Int?, loc: Int, complexity: Int, instructionCount: Int, thresholds: Thresholds) {
        self.methodName = methodName
        self.lineNumber = lineNumber
        self.loc = loc
        self.complexity = complexity
        self.instructionCount = instructionCount

        // Calculate severity based on Z notation formula
        let locScore = Double(loc) / Double(thresholds.methodSmells.longMethodLOC)
        let complexityScore = Double(complexity) / Double(thresholds.methodSmells.longMethodCC)
        let instructionScore = Double(instructionCount) / Double(thresholds.methodSmells.longMethodNOI)

        let maxScore = max(locScore, complexityScore, instructionScore)

        if maxScore >= 2.0 {
            self.severity = .critical
        } else if maxScore >= 1.5 {
            self.severity = .high
        } else if maxScore >= 1.2 {
            self.severity = .medium
        } else {
            self.severity = .low
        }
    }
}

// MARK: - Private Visitor

private class LongMethodVisitor: SyntaxVisitor {
    let thresholds: Thresholds
    var longMethodViolations: [LongMethodViolation] = []
    var currentFile: String
    let sourceText: String

    init(thresholds: Thresholds, filePath: String, sourceText: String) {
        self.thresholds = thresholds
        self.currentFile = filePath
        self.sourceText = sourceText
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        analyzeMethod(node)
        return .visitChildren
    }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        analyzeInitializer(node)
        return .visitChildren
    }

    private func analyzeMethod(_ funcDecl: FunctionDeclSyntax) {
        let methodInfo = MethodAnalyzer.analyze(funcDecl)
        let position = funcDecl.positionAfterSkippingLeadingTrivia
        let lineNumber = calculateLineNumber(from: position, in: sourceText)

        if let violation = methodInfo.createViolation(
            methodName: funcDecl.name.text,
            lineNumber: lineNumber,
            thresholds: thresholds
        ) {
            longMethodViolations.append(violation)
        }
    }

    private func analyzeInitializer(_ initDecl: InitializerDeclSyntax) {
        let methodInfo = InitializerAnalyzer.analyze(initDecl)
        let position = initDecl.positionAfterSkippingLeadingTrivia
        let lineNumber = calculateLineNumber(from: position, in: sourceText)

        if let violation = methodInfo.createViolation(
            methodName: "init",
            lineNumber: lineNumber,
            thresholds: thresholds
        ) {
            longMethodViolations.append(violation)
        }
    }

    /// Calculate line number from absolute position in source text
    private func calculateLineNumber(from position: AbsolutePosition, in sourceText: String) -> Int {
        let prefix = sourceText.prefix(position.utf8Offset)
        return prefix.components(separatedBy: "\n").count
    }
}

// MARK: - Method Analyzers

private struct MethodInfo {
    let loc: Int
    let complexity: Int
    let instructionCount: Int

    /// Determines if this method is considered "long" based on the given thresholds
    func isLongMethod(using thresholds: Thresholds) -> Bool {
        let smells = thresholds.checkMethodSmells(loc: loc, complexity: complexity, noi: instructionCount)
        return smells["longMethod"] ?? false
    }

    /// Creates a LongMethodViolation for this method if it is long
    func createViolation(methodName: String, lineNumber: Int?, thresholds: Thresholds) -> LongMethodViolation? {
        guard isLongMethod(using: thresholds) else { return nil }

        return LongMethodViolation(
            methodName: methodName,
            lineNumber: lineNumber,
            loc: loc,
            complexity: complexity,
            instructionCount: instructionCount,
            thresholds: thresholds
        )
    }
}

private class MethodAnalyzer {
    static func analyze(_ funcDecl: FunctionDeclSyntax) -> MethodInfo {
        // Calculate LOC
        let description = funcDecl.description
        let loc = description.components(separatedBy: "\n").count

        // Calculate cyclomatic complexity (simplified)
        let complexity = calculateCyclomaticComplexity(funcDecl)

        // Count instructions (statements)
        let instructionCount = funcDecl.body?.statements.count ?? 0

        return MethodInfo(loc: loc, complexity: complexity, instructionCount: instructionCount)
    }

    private static func calculateCyclomaticComplexity(_ funcDecl: FunctionDeclSyntax) -> Int {
        guard let body = funcDecl.body else { return 1 }

        var complexity = 1 // Base complexity

        // Visit all statements to count decision points
        let visitor = ComplexityVisitor()
        visitor.walk(body)
        complexity += visitor.decisionPoints

        return complexity
    }
}

private class InitializerAnalyzer {
    static func analyze(_ initDecl: InitializerDeclSyntax) -> MethodInfo {
        let description = initDecl.description
        let loc = description.components(separatedBy: "\n").count

        let complexity = calculateCyclomaticComplexity(initDecl)

        let instructionCount = initDecl.body?.statements.count ?? 0

        return MethodInfo(loc: loc, complexity: complexity, instructionCount: instructionCount)
    }

    private static func calculateCyclomaticComplexity(_ initDecl: InitializerDeclSyntax) -> Int {
        var complexity = 1 // Base complexity

        if let body = initDecl.body {
            let visitor = ComplexityVisitor()
            visitor.walk(body)
            complexity += visitor.decisionPoints
        }

        return complexity
    }
}

// MARK: - Complexity Visitor

private class ComplexityVisitor: SyntaxVisitor {
    var decisionPoints = 0

    init() {
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind {
        decisionPoints += 1
        return .visitChildren
    }

    override func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
        decisionPoints += 1
        return .visitChildren
    }

    override func visit(_ node: SwitchExprSyntax) -> SyntaxVisitorContinueKind {
        decisionPoints += 1 // Simplified - each switch adds at least 1 decision point
        return .visitChildren
    }

    override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        decisionPoints += 1
        return .visitChildren
    }

    override func visit(_ node: RepeatStmtSyntax) -> SyntaxVisitorContinueKind {
        decisionPoints += 1
        return .visitChildren
    }

    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        decisionPoints += 1
        return .visitChildren
    }

    override func visit(_ node: DoStmtSyntax) -> SyntaxVisitorContinueKind {
        decisionPoints += 1
        return .visitChildren
    }

    // Binary operators that create branches
    override func visit(_ node: BinaryOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        let operatorToken = node.operator.tokenKind
        switch operatorToken {
        case .binaryOperator("&&"), .binaryOperator("||"):
            decisionPoints += 1
        default:
            break
        }
        return .visitChildren
    }

    // Ternary operator
    override func visit(_ node: TernaryExprSyntax) -> SyntaxVisitorContinueKind {
        decisionPoints += 1
        return .visitChildren
    }
}