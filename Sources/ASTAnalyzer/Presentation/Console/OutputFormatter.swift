//
//  OutputFormatter.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Protocol for output formatting to separate presentation logic from side effects
//

import Foundation

/// Protocol for formatting and outputting analysis results
public protocol OutputFormatter {
    /// Outputs a formatted header for the analysis result
    func outputHeader(for result: AnalysisResult)

    /// Outputs a formatted summary of the analysis result
    func outputSummary(for result: AnalysisResult)

    /// Outputs formatted defect information
    func outputDefects(for result: AnalysisResult)

    /// Outputs a success message when no issues are found
    func outputSuccessMessage()

    /// Outputs a formatted footer for the analysis result
    func outputFooter(for result: AnalysisResult)
}

/// Console implementation of OutputFormatter that handles actual printing
public final class ConsoleOutputFormatter: OutputFormatter {

    public init() {}

    public func outputHeader(for result: AnalysisResult) {
        print(result.headerDescription, terminator: "")
    }

    public func outputSummary(for result: AnalysisResult) {
        print("📈 SUMMARY:")
        print("-" * 30)

        if result.hasIssues {
            let critical = result.criticalDefects.count
            let high = result.highPriorityDefects.count
            let total = result.totalDefects

            print("🚨 Critical Issues: \(critical)")
            print("⚠️  High Priority: \(high)")
            print("📊 Total Defects: \(total)")
            print("🎯 Maintainability Score: \(String(format: "%.1f", result.maintainabilityScore))/100")

            if result.requiresRefactoring {
                print("🔴 STATUS: Requires immediate refactoring")
            } else if result.hasCriticalIssues {
                print("🟡 STATUS: Needs attention")
            } else {
                print("🟢 STATUS: Good, but could be improved")
            }
        } else {
            print("✅ No architectural issues detected")
            print("🎯 Maintainability Score: 100.0/100")
            print("🟢 STATUS: Excellent")
        }
        print()
    }

    public func outputDefects(for result: AnalysisResult) {
        let defectsBySeverity = result.defectsBySeverity

        // Critical defects
        if let critical = defectsBySeverity[.critical], !critical.isEmpty {
            print("🚨 CRITICAL ISSUES:")
            print("-" * 40)
            for defect in critical {
                outputDefect(defect)
            }
            print()
        }

        // High priority defects
        if let high = defectsBySeverity[.high], !high.isEmpty {
            print("⚠️ HIGH PRIORITY:")
            print("-" * 30)
            for defect in high {
                outputDefect(defect)
            }
            print()
        }

        // Medium priority defects
        if let medium = defectsBySeverity[.medium], !medium.isEmpty {
            print("📊 MEDIUM PRIORITY:")
            print("-" * 30)
            for defect in medium {
                outputDefect(defect)
            }
            print()
        }

        // Low priority defects
        if let low = defectsBySeverity[.low], !low.isEmpty {
            print("ℹ️ LOW PRIORITY:")
            print("-" * 25)
            for defect in low {
                outputDefect(defect)
            }
            print()
        }
    }

    public func outputDefect(_ defect: ArchitecturalDefect) {
        print("• \(defect.message)")
        print("  💡 \(defect.suggestion)")
        print()
    }

    public func outputSuccessMessage() {
        print("🎉 Congratulations!")
        print("Your code follows good architectural practices.")
        print()
    }

    public func outputFooter(for result: AnalysisResult) {
        print("=" * 60)
        print("Analysis completed at \(formatDate(result.analyzedAt))")
        print("Use this report to improve your code architecture!")
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