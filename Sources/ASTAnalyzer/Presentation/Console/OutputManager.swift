//
//  OutputManager.swift
//  ASTAnalyzer
//
//  Created on 2025-12-14.
//

import Foundation

/// Service responsible for managing all output operations (console, exports)
public final class OutputManager {

    private let filePresenter: AnalysisResultPresenter
    private let directoryPresenter: DirectoryAnalysisResultPresenter
    private let jsonExporter: JSONExporter
    private let markdownExporter: MarkdownExporter

    public init(
        filePresenter: AnalysisResultPresenter,
        directoryPresenter: DirectoryAnalysisResultPresenter,
        jsonExporter: JSONExporter,
        markdownExporter: MarkdownExporter
    ) {
        self.filePresenter = filePresenter
        self.directoryPresenter = directoryPresenter
        self.jsonExporter = jsonExporter
        self.markdownExporter = markdownExporter
    }

    /// Presents analysis results to console
    /// - Parameters:
    ///   - report: Analysis report to present
    ///   - config: Analysis configuration
    public func presentResults(report: SmellReport, config: AnalysisConfig) {
        switch config.pathType {
        case .file(let filePath):
            presentFileResults(report: report, filePath: filePath)
        case .directory(let directoryPath):
            presentDirectoryResults(report: report, directoryPath: directoryPath)
        }
    }

    /// Exports analysis results to configured formats
    /// - Parameters:
    ///   - report: Analysis report to export
    ///   - config: Analysis configuration
    /// - Throws: Export errors
    public func exportResults(report: SmellReport, config: AnalysisConfig) throws {
        if config.enableJSONExport {
            try jsonExporter.export(report: report, to: config.jsonOutputDirectory ?? ".")
        }

        if config.enableMarkdownExport {
            try markdownExporter.export(report: report, to: config.markdownOutputDirectory ?? ".")
        }
    }

    // MARK: - Private Methods

    private func presentFileResults(report: SmellReport, filePath: String) {
        // Convert to old format for compatibility with existing presenters
        let defects = convertSmellInstancesToDefects(report)
        let sourceFile = SourceFile(filePath: filePath, content: "// Analyzed file")
        let analysisResult = AnalysisResult(
            sourceFile: sourceFile,
            defects: defects,
            analysisDuration: report.metadata.duration
        )
        filePresenter.present(result: analysisResult)
    }

    private func presentDirectoryResults(report: SmellReport, directoryPath: String) {
        // Convert to old format for compatibility
        let directoryResult = convertReportToDirectoryResult(report, directoryPath: directoryPath)
        directoryPresenter.present(result: directoryResult)
    }

    private func convertSmellInstancesToDefects(_ report: SmellReport) -> [ArchitecturalDefect] {
        report.smellsByType.flatMap { (type, _) in
            report.smellsByClass.flatMap { (_, instances) in
                instances.filter { $0.type == type }.map { instance in
                    ArchitecturalDefect(
                        type: instance.type,
                        severity: convertSeverity(instance.severity),
                        message: instance.message,
                        location: instance.location,
                        suggestion: instance.suggestion
                    )
                }
            }
        }
    }

    private func convertSeverity(_ severity: Double) -> Severity {
        if severity >= 0.8 {
            return .critical
        } else if severity >= 0.6 {
            return .high
        } else if severity >= 0.4 {
            return .medium
        } else {
            return .low
        }
    }

    private func convertReportToDirectoryResult(_ report: SmellReport, directoryPath: String) -> DirectoryAnalysisResult {
        // Group smells by file path for proper file-based analysis
        let smellsByFile = Dictionary(grouping: report.criticalSmells + report.smellsByClass.values.flatMap { $0 }) { smell in
            smell.location.filePath
        }

        let fileResults: [AnalysisResult] = smellsByFile.map { (filePath, instances) in
            let sourceFile = SourceFile(filePath: filePath, content: "// Analyzed file")
            let defects = instances.map { instance in
                ArchitecturalDefect(
                    type: instance.type,
                    severity: convertSeverity(instance.severity),
                    message: instance.message,
                    location: instance.location,
                    suggestion: instance.suggestion
                )
            }
            return AnalysisResult(
                sourceFile: sourceFile,
                defects: defects,
                analysisDuration: report.metadata.duration / Double(max(1, smellsByFile.count))
            )
        }

        return DirectoryAnalysisResult(
            directoryPath: directoryPath,
            fileResults: fileResults,
            failedFiles: [],
            analysisDuration: report.metadata.duration,
            analyzedAt: report.metadata.timestamp
        )
    }
}