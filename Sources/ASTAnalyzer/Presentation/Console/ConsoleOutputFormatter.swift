//
//  ConsoleOutputFormatter.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Console implementation of OutputFormatter that handles actual printing
//

import Foundation

/// Console implementation of OutputFormatter that handles actual printing
public final class ConsoleOutputFormatter: OutputFormatter {

    private let outputHandler: ConsoleOutputHandler

    public init(outputHandler: ConsoleOutputHandler = StandardConsoleOutputHandler()) {
        self.outputHandler = outputHandler
    }

    public func outputHeader(for result: AnalysisResult) {
        outputHandler.outputInline(result.headerDescription)
    }

    public func outputSummary(for result: AnalysisResult) {
        outputHandler.outputLine("📈 SUMMARY:")
        outputHandler.outputLine(String(repeating: "-", count: 30))

        if result.hasIssues {
            let critical = result.criticalDefects.count
            let high = result.highPriorityDefects.count
            let total = result.totalDefects

            outputHandler.outputLine("🚨 Critical Issues: \(critical)")
            outputHandler.outputLine("⚠️  High Priority: \(high)")
            outputHandler.outputLine("📊 Total Defects: \(total)")
            outputHandler.outputLine("🎯 Maintainability Score: \(String(format: "%.1f", result.maintainabilityScore))/100")

            if result.requiresRefactoring {
                outputHandler.outputLine("🔴 STATUS: Requires immediate refactoring")
            } else if result.hasCriticalIssues {
                outputHandler.outputLine("🟡 STATUS: Needs attention")
            } else {
                outputHandler.outputLine("🟢 STATUS: Good, but could be improved")
            }
        } else {
            outputHandler.outputLine("✅ No architectural issues detected")
            outputHandler.outputLine("🎯 Maintainability Score: 100.0/100")
            outputHandler.outputLine("🟢 STATUS: Excellent")
        }
        outputHandler.outputEmptyLine()
    }

    public func outputDefects(for result: AnalysisResult) {
        let defectsBySeverity = result.defectsBySeverity

        // Critical defects
        if let critical = defectsBySeverity[.critical], !critical.isEmpty {
            outputHandler.outputLine("🚨 CRITICAL ISSUES:")
            outputHandler.outputLine(String(repeating: "-", count: 40))
            for defect in critical {
                outputDefect(defect)
            }
            outputHandler.outputEmptyLine()
        }

        // High priority defects
        if let high = defectsBySeverity[.high], !high.isEmpty {
            outputHandler.outputLine("⚠️ HIGH PRIORITY:")
            outputHandler.outputLine(String(repeating: "-", count: 30))
            for defect in high {
                outputDefect(defect)
            }
            outputHandler.outputEmptyLine()
        }

        // Medium priority defects
        if let medium = defectsBySeverity[.medium], !medium.isEmpty {
            outputHandler.outputLine("📊 MEDIUM PRIORITY:")
            outputHandler.outputLine(String(repeating: "-", count: 30))
            for defect in medium {
                outputDefect(defect)
            }
            outputHandler.outputEmptyLine()
        }

        // Low priority defects
        if let low = defectsBySeverity[.low], !low.isEmpty {
            outputHandler.outputLine("ℹ️ LOW PRIORITY:")
            outputHandler.outputLine(String(repeating: "-", count: 25))
            for defect in low {
                outputDefect(defect)
            }
            outputHandler.outputEmptyLine()
        }
    }

    public func outputDefect(_ defect: ArchitecturalDefect) {
        outputHandler.outputLine("• \(defect.message)")
        outputHandler.outputLine("  💡 \(defect.suggestion)")
        outputHandler.outputEmptyLine()
    }

    public func outputSuccessMessage() {
        outputHandler.outputLine("🎉 Congratulations!")
        outputHandler.outputLine("Your code follows good architectural practices.")
        outputHandler.outputEmptyLine()
    }

    public func outputFooter(for result: AnalysisResult) {
        outputHandler.outputLine(String(repeating: "=", count: 60))
        outputHandler.outputLine("Analysis completed at \(formatDate(result.analyzedAt))")
        outputHandler.outputLine("Use this report to improve your code architecture!")
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}