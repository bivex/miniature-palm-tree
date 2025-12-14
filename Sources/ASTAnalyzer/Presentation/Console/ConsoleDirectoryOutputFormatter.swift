//
//  ConsoleDirectoryOutputFormatter.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Console implementation of DirectoryOutputFormatter that handles actual printing
//

import Foundation

/// Console implementation of DirectoryOutputFormatter that handles actual printing
public final class ConsoleDirectoryOutputFormatter: DirectoryOutputFormatter {

    private let outputHandler: ConsoleOutputHandler

    public init(outputHandler: ConsoleOutputHandler = StandardConsoleOutputHandler()) {
        self.outputHandler = outputHandler
    }

    public func outputDirectoryHeader(for result: DirectoryAnalysisResult) {
        outputHandler.outputLine("🔍 Directory Architectural Analysis Report")
        outputHandler.outputLine(String(repeating: "=", count: 70))
        outputHandler.outputLine("📁 Directory: \(result.directoryPath)")
        outputHandler.outputLine("📊 Total Swift Files: \(result.totalFiles)")
        outputHandler.outputLine("⏱️  Analysis Time: \(String(format: "%.2f", result.analysisDuration))s")
        outputHandler.outputEmptyLine()
    }

    public func outputDirectorySummary(for result: DirectoryAnalysisResult) {
        outputHandler.outputLine("📈 DIRECTORY SUMMARY:")
        outputHandler.outputLine(String(repeating: "-", count: 40))

        outputHandler.outputLine("✅ Successfully analyzed: \(result.totalFiles) files")

        if !result.failedFiles.isEmpty {
            outputHandler.outputLine("❌ Failed to analyze: \(result.totalFailedFiles) files")
        }

        if result.hasIssues {
            let critical = result.criticalDefects
            let high = result.highPriorityDefects
            let total = result.totalDefects

            outputHandler.outputLine("🚨 Critical Issues: \(critical)")
            outputHandler.outputLine("⚠️  High Priority: \(high)")
            outputHandler.outputLine("📊 Total Defects: \(total)")
            outputHandler.outputLine("🎯 Average Maintainability Score: \(String(format: "%.1f", result.averageMaintainabilityScore))/100")

            if result.requiresRefactoring {
                outputHandler.outputLine("🔴 STATUS: Requires immediate refactoring")
            } else if result.hasCriticalIssues {
                outputHandler.outputLine("🟡 STATUS: Needs attention")
            } else {
                outputHandler.outputLine("🟢 STATUS: Good, but could be improved")
            }
        } else {
            outputHandler.outputLine("✅ No architectural issues detected")
            outputHandler.outputLine("🎯 Average Maintainability Score: 100.0/100")
            outputHandler.outputLine("🟢 STATUS: Excellent")
        }
        outputHandler.outputEmptyLine()
    }

    public func outputFailedFiles(for result: DirectoryAnalysisResult) {
        outputHandler.outputLine("❌ FAILED FILES:")
        outputHandler.outputLine(String(repeating: "-", count: 30))
        for (filePath, error) in result.failedFiles {
            let fileName = URL(fileURLWithPath: filePath).lastPathComponent
            outputHandler.outputLine("• \(fileName): \(error.localizedDescription)")
        }
        outputHandler.outputEmptyLine()
    }

    public func outputDirectoryDefects(for result: DirectoryAnalysisResult) {
        let defectsBySeverity = result.defectsBySeverity

        // Print defects for each severity level
        outputDefectsBySeverity(defectsBySeverity[.critical],
                              title: "CRITICAL ISSUES",
                              emoji: "🚨",
                              maxItems: 5,
                              overflowMessage: "more critical issues")

        outputDefectsBySeverity(defectsBySeverity[.high],
                              title: "HIGH PRIORITY",
                              emoji: "⚠️",
                              maxItems: 5,
                              overflowMessage: "more high priority issues")

        outputDefectsBySeverity(defectsBySeverity[.medium],
                              title: "MEDIUM PRIORITY",
                              emoji: "📊",
                              maxItems: 3,
                              overflowMessage: "more medium priority issues")

        outputDefectsBySeverity(defectsBySeverity[.low],
                              title: "LOW PRIORITY",
                              emoji: "ℹ️",
                              maxItems: 3,
                              overflowMessage: "more low priority issues")
    }

    public func outputDefectsBySeverity(_ defects: [ArchitecturalDefect]?,
                                       title: String,
                                       emoji: String,
                                       maxItems: Int,
                                       overflowMessage: String) {
        guard let defects = defects, !defects.isEmpty else { return }

        outputHandler.outputLine("\(emoji) \(title) (\(defects.count)):")
        outputHandler.outputLine(String(repeating: "-", count: title.count + 12))

        for defect in defects.prefix(maxItems) {
            let fileName = URL(fileURLWithPath: defect.location.filePath).lastPathComponent
            outputHandler.outputLine("• \(fileName): \(defect.message)")

            if let line = defect.location.lineNumber {
                outputHandler.outputLine("  📍 line \(line)\(defect.location.context.map { " (\($0))" } ?? "")")
            } else {
                outputHandler.outputLine("  📍 \(defect.location.context ?? "general")")
            }
        }

        if defects.count > maxItems {
            outputHandler.outputLine("... and \(defects.count - maxItems) \(overflowMessage)")
        }
        outputHandler.outputEmptyLine()
    }

    public func outputSuccessMessage() {
        outputHandler.outputLine("🎉 Congratulations!")
        outputHandler.outputLine("Your codebase follows good architectural practices.")
        outputHandler.outputEmptyLine()
    }

    public func outputDirectoryFooter(for result: DirectoryAnalysisResult) {
        outputHandler.outputLine(String(repeating: "=", count: 70))
        outputHandler.outputLine("Directory analysis completed at \(formatDate(result.analyzedAt))")
        outputHandler.outputLine("Use individual file analysis for detailed reports on specific files!")
    }

    public func outputDetailedFileAnalysis(for result: DirectoryAnalysisResult, filePresenter: AnalysisResultPresenter) {
        // Optionally show detailed results for each file
        if result.hasIssues && result.totalFiles <= 10 {
            outputHandler.outputLine("\n📄 DETAILED FILE ANALYSIS:")
            outputHandler.outputLine(String(repeating: "=", count: 60))
            for fileResult in result.fileResults where fileResult.hasIssues {
                outputHandler.outputEmptyLine()
                filePresenter.present(result: fileResult)
            }
        } else if result.totalFiles > 10 {
            outputHandler.outputLine("\n💡 Tip: Use individual file analysis for detailed reports")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}