//
//  DirectoryAnalysisResultPresenter.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//

import Foundation

/// Presenter responsible for formatting directory analysis results for console output
public final class DirectoryAnalysisResultPresenter {

    private let filePresenter: AnalysisResultPresenter

    public init(filePresenter: AnalysisResultPresenter = AnalysisResultPresenter()) {
        self.filePresenter = filePresenter
    }

    /// Presents the directory analysis result in a formatted console output
    /// - Parameter result: The directory analysis result to present
    public func present(result: DirectoryAnalysisResult) {
        printDirectoryHeader(for: result)
        printDirectorySummary(for: result)

        if !result.failedFiles.isEmpty {
            printFailedFiles(for: result)
        }

        if result.hasIssues {
            printDirectoryDefects(for: result)
        } else {
            printSuccessMessage()
        }

        printDirectoryFooter(for: result)

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

    // MARK: - Private Methods

    private func printDirectoryHeader(for result: DirectoryAnalysisResult) {
        print("🔍 Directory Architectural Analysis Report")
        print("=" * 70)
        print("📁 Directory: \(result.directoryPath)")
        print("📊 Total Swift Files: \(result.totalFiles)")
        print("⏱️  Analysis Time: \(String(format: "%.2f", result.analysisDuration))s")
        print()
    }

    private func printDirectorySummary(for result: DirectoryAnalysisResult) {
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

    private func printFailedFiles(for result: DirectoryAnalysisResult) {
        print("❌ FAILED FILES:")
        print("-" * 30)
        for (filePath, error) in result.failedFiles {
            let fileName = URL(fileURLWithPath: filePath).lastPathComponent
            print("• \(fileName): \(error.localizedDescription)")
        }
        print()
    }

    private func printDirectoryDefects(for result: DirectoryAnalysisResult) {
        let defectsBySeverity = result.defectsBySeverity

        // Print defects for each severity level
        printDefectsBySeverity(defectsBySeverity[.critical],
                              title: "CRITICAL ISSUES",
                              emoji: "🚨",
                              maxItems: 5,
                              overflowMessage: "more critical issues")

        printDefectsBySeverity(defectsBySeverity[.high],
                              title: "HIGH PRIORITY",
                              emoji: "⚠️",
                              maxItems: 5,
                              overflowMessage: "more high priority issues")

        printDefectsBySeverity(defectsBySeverity[.medium],
                              title: "MEDIUM PRIORITY",
                              emoji: "📊",
                              maxItems: 3,
                              overflowMessage: "more medium priority issues")

        printDefectsBySeverity(defectsBySeverity[.low],
                              title: "LOW PRIORITY",
                              emoji: "ℹ️",
                              maxItems: 3,
                              overflowMessage: "more low priority issues")
    }

    private func printDefectsBySeverity(_ defects: [ArchitecturalDefect]?,
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

    private func printSuccessMessage() {
        print("🎉 Congratulations!")
        print("Your codebase follows good architectural practices.")
        print()
    }

    private func printDirectoryFooter(for result: DirectoryAnalysisResult) {
        print("=" * 70)
        print("Directory analysis completed at \(formatDate(result.analyzedAt))")
        print("Use individual file analysis for detailed reports on specific files!")
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