//
//  ProjectSmellAnalyzer.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Project-level smell analyzer based on Z notation specifications
//

import Foundation
import SwiftSyntax
import SwiftParser

/**
 ProjectSmellAnalyzer based on Z notation:
 ```
 ProjectSmellAnalyzer
 ├─ project : SwiftProject
 ├─ SmellType ::= GodClass | MassiveVC | MultifacetedAbstraction | ...
 ├─ SmellInstance == SmellType × (Class ∪ Method) × ℝ
 ├─ detectedSmells : ℙ SmellInstance
 ├─ classSmells : Class → ℙ SmellInstance
 ├─ methodSmells : Method → ℙ SmellInstance
 ├─ projectHealthScore : ℝ
 └─ [aggregated analysis across entire project]
 ```
 */
public final class ProjectSmellAnalyzer {

    private let detectors: [DefectDetector]
    private let thresholds: Thresholds

    public init(thresholds: Thresholds = .academic) {
        self.thresholds = thresholds

        // Initialize all available detectors
        self.detectors = [
            GodClassDetector(thresholds: thresholds),
            MassiveViewControllerDetector(thresholds: thresholds),
            LongMethodDetector(thresholds: thresholds),
            LazyClassDetector(thresholds: thresholds),
            DataClassDetector(thresholds: thresholds),
            MultifacetedAbstractionDetector(thresholds: thresholds),
            DeficientEncapsulationDetector(thresholds: thresholds),
            MessageChainDetector(thresholds: thresholds),
            FeatureEnvyDetector(thresholds: thresholds),
            BrokenHierarchyDetector(),
            CyclicDependencyDetector(thresholds: thresholds)
        ]
    }

    /**
     AnalyzeProject operation based on Z notation:
     ```
     AnalyzeProject
     ΔProjectSmellAnalyzer
     sourceFiles? : ℙ SOURCE_CODE
     thresholdConfig? : Thresholds
     report! : SmellReport
     ```
     */
    public func analyze(
        sourceFiles: [SourceFile],
        startTime: Date = Date()
    ) async -> SmellReport {
        let analysisStart = Date()

        // Parse source files and collect defects
        let (allDefects, totalClasses, totalMethods) = await parseSourceFiles(sourceFiles)

        // Convert defects to smell instances and generate report
        return createAnalysisReport(
            defects: allDefects,
            totalClasses: totalClasses,
            totalMethods: totalMethods,
            sourceFiles: sourceFiles,
            analysisStart: analysisStart
        )
    }

    /// Parses source files and runs defect detection
    private func parseSourceFiles(_ sourceFiles: [SourceFile]) async -> ([ArchitecturalDefect], Int, Int) {
        var allDefects: [ArchitecturalDefect] = []
        var totalClasses = 0
        var totalMethods = 0
        var processedFiles = Set<String>()

        for sourceFile in sourceFiles {
            if processedFiles.contains(sourceFile.filePath) {
                print("WARNING: Duplicate file detected: \(sourceFile.filePath)")
                continue
            }
            processedFiles.insert(sourceFile.filePath)

            do {
                // Parse the source file
                let source = try String(contentsOfFile: sourceFile.filePath, encoding: .utf8)
                let sourceFileSyntax = Parser.parse(source: source)

                // Run all detectors on this file
                for detector in detectors {
                    let defects = detector.detectDefects(in: sourceFileSyntax, filePath: sourceFile.filePath)
                    allDefects.append(contentsOf: defects)
                }

                // Count classes and methods (simplified)
                let visitor = CodeMetricsVisitor()
                visitor.walk(sourceFileSyntax)
                totalClasses += visitor.classCount
                totalMethods += visitor.methodCount

            } catch {
                // Log parsing errors but continue with other files
                print("Warning: Failed to parse \(sourceFile.filePath): \(error)")
            }
        }

        return (allDefects, totalClasses, totalMethods)
    }

    /// Creates the final analysis report from collected data
    private func createAnalysisReport(
        defects: [ArchitecturalDefect],
        totalClasses: Int,
        totalMethods: Int,
        sourceFiles: [SourceFile],
        analysisStart: Date
    ) -> SmellReport {
        let smellInstances = convertToSmellInstances(defects)
        let healthScore = calculateProjectHealthScore(smellInstances, totalClasses, totalMethods)
        let recommendations = generateProjectRecommendations(smellInstances, healthScore)
        let smellsByType = groupSmellsByType(smellInstances)
        let smellsByClass = groupSmellsByClass(smellInstances)
        let criticalSmells = extractCriticalSmells(smellInstances)

        let metadata = generateAnalysisMetadata(
            analysisStart: analysisStart,
            filesAnalyzed: sourceFiles.count,
            classesAnalyzed: totalClasses,
            methodsAnalyzed: totalMethods
        )

        return SmellReport(
            totalSmells: smellInstances.count,
            smellsByType: smellsByType,
            smellsByClass: smellsByClass,
            criticalSmells: criticalSmells,
            healthScore: healthScore,
            recommendations: recommendations,
            metadata: metadata
        )
    }

    /// Calculates project health score
    private func calculateProjectHealthScore(_ smellInstances: [SmellInstance], _ totalClasses: Int, _ totalMethods: Int) -> Double {
        SmellReport.calculateHealthScore(
            smells: smellInstances,
            totalClasses: totalClasses,
            totalMethods: totalMethods
        )
    }

    /// Generates project recommendations
    private func generateProjectRecommendations(_ smellInstances: [SmellInstance], _ healthScore: Double) -> [String] {
        SmellReport.generateRecommendations(
            for: smellInstances,
            healthScore: healthScore
        )
    }

    /// Groups smells by type
    private func groupSmellsByType(_ smellInstances: [SmellInstance]) -> [DefectType: Int] {
        Dictionary(grouping: smellInstances) { $0.type }
            .mapValues { $0.count }
    }

    /// Groups smells by class
    private func groupSmellsByClass(_ smellInstances: [SmellInstance]) -> [String: [SmellInstance]] {
        Dictionary(grouping: smellInstances) { smell in
            switch smell.element {
            case .class(let name): return name
            case .method(let className, _): return className
            case .file: return "Global"
            }
        }
    }

    /// Extracts critical smells that require immediate action
    private func extractCriticalSmells(_ smellInstances: [SmellInstance]) -> [SmellInstance] {
        smellInstances.filter { $0.requiresImmediateAction }
    }

    /// Generates analysis metadata
    private func generateAnalysisMetadata(
        analysisStart: Date,
        filesAnalyzed: Int,
        classesAnalyzed: Int,
        methodsAnalyzed: Int
    ) -> AnalysisMetadata {
        AnalysisMetadata(
            timestamp: analysisStart,
            duration: Date().timeIntervalSince(analysisStart),
            filesAnalyzed: filesAnalyzed,
            classesAnalyzed: classesAnalyzed,
            methodsAnalyzed: methodsAnalyzed,
            thresholds: thresholds
        )
    }

    private func convertToSmellInstances(_ defects: [ArchitecturalDefect]) -> [SmellInstance] {
        var seen = Set<String>()
        var result = [SmellInstance]()

        for defect in defects {
            // Create a unique key for this defect
            let key = "\(defect.type.rawValue)|\(defect.location.filePath)|\(defect.location.context ?? "")|\(defect.message)|\(defect.location.lineNumber ?? 0)|\(defect.location.columnNumber ?? 0)"
            if seen.contains(key) {
                print("WARNING: Duplicate defect detected and filtered: \(key)")
                continue
            }
            seen.insert(key)

            // Determine the code element
            let element: CodeElement
            if let context = defect.location.context {
                if context.hasPrefix("class ") {
                    let className = String(context.dropFirst(6)) // Remove "class " prefix
                    element = .class(name: className)
                } else if context.hasPrefix("struct ") {
                    let structName = String(context.dropFirst(7)) // Remove "struct " prefix
                    element = .class(name: structName)
                } else if context.contains(".") {
                    // Method context like "ClassName.methodName"
                    let components = context.split(separator: ".", maxSplits: 1)
                    if components.count == 2 {
                        element = .method(className: String(components[0]), methodName: String(components[1]))
                    } else {
                        element = .file(path: defect.location.filePath)
                    }
                } else {
                    element = .file(path: defect.location.filePath)
                }
            } else {
                element = .file(path: defect.location.filePath)
            }

            // Convert severity to double
            let severityDouble: Double
            switch defect.severity {
            case .low: severityDouble = 0.2
            case .medium: severityDouble = 0.5
            case .high: severityDouble = 0.7
            case .critical: severityDouble = 0.9
            }

            let smellInstance = SmellInstance(
                type: defect.type,
                element: element,
                severity: severityDouble,
                location: defect.location,
                message: defect.message,
                suggestion: defect.suggestion
            )
            result.append(smellInstance)
        }

        return result
    }
}

// MARK: - Helper Visitor for Code Metrics

private class CodeMetricsVisitor: SyntaxVisitor {
    var classCount = 0
    var methodCount = 0

    init() {
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        classCount += 1
        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        classCount += 1 // Count structs as classes for simplicity
        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        methodCount += 1
        return .visitChildren
    }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        methodCount += 1
        return .visitChildren
    }
}