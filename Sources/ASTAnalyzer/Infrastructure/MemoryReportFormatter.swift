//
//  MemoryReportFormatter.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Protocol for formatting memory profiling reports
//

import Foundation

/// Protocol for formatting and outputting memory profiling reports
public protocol MemoryReportFormatter {
    /// Outputs a formatted memory profiling report
    func outputMemoryReport(stats: MemoryProfiler.MemoryStats, snapshots: [MemoryProfiler.MemorySnapshot], analysis: MemoryAnalysis)
}

/// Console implementation of MemoryReportFormatter
public final class ConsoleMemoryReportFormatter: MemoryReportFormatter {

    public init() {}

    public func outputMemoryReport(stats: MemoryProfiler.MemoryStats, snapshots: [MemoryProfiler.MemorySnapshot], analysis: MemoryAnalysis) {
        print("\n📊 Memory Profiling Report")
        print("==========================")

        print("Current Memory Usage:")
        print("  Resident Size (RSS): \(String(format: "%.2f", stats.residentSizeMB)) MB")
        print("  Virtual Size (VSZ): \(String(format: "%.2f", stats.virtualSizeMB)) MB")
        print("  Peak RSS: \(String(format: "%.2f", stats.peakResidentSizeMB)) MB")

        if !snapshots.isEmpty {
            print("\nSnapshot History (\(snapshots.count) snapshots):")
            for (index, snapshot) in snapshots.enumerated() {
                let timeDesc = snapshot.timestampDescription
                let rssMB = Double(snapshot.residentSize) / 1024.0 / 1024.0
                let vszMB = Double(snapshot.virtualSize) / 1024.0 / 1024.0
                print("  \(index + 1). \(timeDesc)s: RSS=\(String(format: "%.2f", rssMB)) MB, VSZ=\(String(format: "%.2f", vszMB)) MB")
            }
        }

        print("\nAnalysis:")
        for recommendation in analysis.recommendations {
            print("  \(recommendation)")
        }
    }
}

/// Snapshot output handler
public protocol SnapshotOutputHandler {
    /// Outputs a memory snapshot with optional label
    func outputSnapshot(snapshot: MemoryProfiler.MemorySnapshot, label: String)
}

/// Console implementation of SnapshotOutputHandler
public final class ConsoleSnapshotOutputHandler: SnapshotOutputHandler {

    public init() {}

    public func outputSnapshot(snapshot: MemoryProfiler.MemorySnapshot, label: String) {
        if !label.isEmpty {
            print("📊 Memory snapshot '\(label)': \(String(format: "%.2f", snapshot.residentSizeMB)) MB RSS")
        }
    }
}