//
//  DirectoryOutputFormatter.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Protocol for directory output formatting to separate presentation logic from side effects
//

import Foundation

/// Protocol for formatting and outputting directory analysis results
public protocol DirectoryOutputFormatter {
    /// Outputs a formatted header for directory analysis
    func outputDirectoryHeader(for result: DirectoryAnalysisResult)

    /// Outputs a formatted summary of directory analysis
    func outputDirectorySummary(for result: DirectoryAnalysisResult)

    /// Outputs information about failed files
    func outputFailedFiles(for result: DirectoryAnalysisResult)

    /// Outputs formatted defect information for directory
    func outputDirectoryDefects(for result: DirectoryAnalysisResult)

    /// Outputs a success message when no issues are found
    func outputSuccessMessage()

    /// Outputs a formatted footer for directory analysis
    func outputDirectoryFooter(for result: DirectoryAnalysisResult)

    /// Outputs detailed file analysis if needed
    func outputDetailedFileAnalysis(for result: DirectoryAnalysisResult, filePresenter: AnalysisResultPresenter)
}

/// Console implementation of DirectoryOutputFormatter that handles actual printing
public final class ConsoleDirectoryOutputFormatter: DirectoryOutputFormatter {

    public init() {}

    public func outputDirectoryHeader(for result: DirectoryAnalysisResult) {
        print("🔍 Directory Architectural Analysis Report")
        print("=" * 70)
        print("📁 Directory: \(result.directoryPath)")
        print("📊 Total Swift Files: \(result.totalFiles)")
        print("⏱️  Analysis Time: \(String(format: "%.2f", result.analysisDuration))s")
        print()
    }

    public func outputDirectorySummary(for result: DirectoryAnalysisResult) {
        print("📈 DIRECTORY SUMMARY:")
        print("-" * 40)

        print("✅ Successfully analyzed: \(result.totalFiles) files")

        if !result.failedFiles.isEmpty {
            print("❌ Failed to analyze: \(result.totalFailedFiles) files")
        }

        if result.hasIssues {
            let critical = result.criticalDefects
            let high = result.highPriorityDefects
            let total = result.totalDefects

            print("🚨 Critical Issues: \(critical)")
            print("⚠️  High Priority: \(high)")
            print("📊 Total Defects: \(total)")
            print("🎯 Average Maintainability Score: \(String(format: "%.1f", result.averageMaintainabilityScore))/100")

            if result.requiresRefactoring {
                print("🔴 STATUS: Requires immediate refactoring")
            } else if result.hasCriticalIssues {
                print("🟡 STATUS: Needs attention")
            } else {
                print("🟢 STATUS: Good, but could be improved")
            }
        } else {
            print("✅ No architectural issues detected")
            print("🎯 Average Maintainability Score: 100.0/100")
            print("🟢 STATUS: Excellent")
        }
        print()
    }

    public func outputFailedFiles(for result: DirectoryAnalysisResult) {
        print("❌ FAILED FILES:")
        print("-" * 30)
        for (filePath, error) in result.failedFiles {
            let fileName = URL(fileURLWithPath: filePath).lastPathComponent
            print("• \(fileName): \(error.localizedDescription)")
        }
        print()
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

        print("\(emoji) \(title) (\(defects.count)):")
        print(String(repeating: "-", count: title.count + 12))

        for defect in defects.prefix(maxItems) {
            let fileName = URL(fileURLWithPath: defect.location.filePath).lastPathComponent
            print("• \(fileName): \(defect.message)")

            if let line = defect.location.lineNumber {
                print("  📍 line \(line)\(defect.location.context.map { " (\($0))" } ?? "")")
            } else {
                print("  📍 \(defect.location.context ?? "general")")
            }
        }

        if defects.count > maxItems {
            print("... and \(defects.count - maxItems) \(overflowMessage)")
        }
        print()
    }

    public func outputSuccessMessage() {
        print("🎉 Congratulations!")
        print("Your codebase follows good architectural practices.")
        print()
    }

    public func outputDirectoryFooter(for result: DirectoryAnalysisResult) {
        print("=" * 70)
        print("Directory analysis completed at \(formatDate(result.analyzedAt))")
        print("Use individual file analysis for detailed reports on specific files!")
    }

    public func outputDetailedFileAnalysis(for result: DirectoryAnalysisResult, filePresenter: AnalysisResultPresenter) {
        // Optionally show detailed results for each file
        if result.hasIssues && result.totalFiles <= 10 {
            print("\n📄 DETAILED FILE ANALYSIS:")
            print("=" * 60)
            for fileResult in result.fileResults where fileResult.hasIssues {
                print()
                filePresenter.present(result: fileResult)
            }
        } else if result.totalFiles > 10 {
            print("\n💡 Tip: Use individual file analysis for detailed reports")
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

private extension String {
    static func *(lhs: String, rhs: Int) -> String {
        String(repeating: lhs, count: rhs)
    }
}