//
//  MarkdownExporter.swift
//  ASTAnalyzer
//
//  Created on 2025-12-14.
//

import Foundation

/// Service for exporting analysis results to Markdown format organized by smell types
public final class MarkdownExporter {

    private let formatter: MarkdownFormatter
    private let fileWriter: MarkdownFileWriter
    private let summaryBuilder: SummaryMarkdownBuilder
    private let smellTypeBuilder: SmellTypeMarkdownBuilder

    public init(
        formatter: MarkdownFormatter = MarkdownFormatter(),
        fileWriter: MarkdownFileWriter = MarkdownFileWriter(),
        summaryBuilder: SummaryMarkdownBuilder? = nil,
        smellTypeBuilder: SmellTypeMarkdownBuilder? = nil
    ) {
        self.formatter = formatter
        self.fileWriter = fileWriter
        self.summaryBuilder = summaryBuilder ?? SummaryMarkdownBuilder(formatter: formatter)
        self.smellTypeBuilder = smellTypeBuilder ?? SmellTypeMarkdownBuilder(formatter: formatter)
    }

    /// Exports smell report to Markdown files organized by smell type
    /// - Parameters:
    ///   - report: The smell report to export
    ///   - outputDirectory: Base directory for Markdown export (defaults to current directory)
    /// - Throws: File system errors
    public func export(report: SmellReport, to outputDirectory: String = ".") throws {
        // Create timestamped subdirectory
        let timestamp = formatter.formatTimestamp(report.metadata.timestamp)
        let exportDirectory = "\(outputDirectory)/analysis_\(timestamp)"

        try fileWriter.createDirectoryIfNeeded(at: exportDirectory)

        // Group smells by type
        let smellsByType = Dictionary(grouping: report.smellsByClass.values.flatMap { $0 }) { $0.type }

        // Prepare files to write
        var filesToWrite = [String: String]()

        // Create smell type files
        for (smellType, instances) in smellsByType {
            let markdownContent = smellTypeBuilder.buildSmellTypeMarkdown(
                smellType: smellType,
                instances: instances,
                report: report
            )
            let filename = formatter.sanitizeFilename("\(smellType.rawValue).md")
            filesToWrite[filename] = markdownContent
        }

        // Create summary file
        let summaryContent = summaryBuilder.buildSummaryMarkdown(report: report)
        filesToWrite["README.md"] = summaryContent

        // Write all files
        try fileWriter.writeFiles(filesToWrite, to: exportDirectory)

        print("📝 Markdown export completed: \(exportDirectory)")
        print("📊 Exported \(smellsByType.count) smell types + summary")
    }
}