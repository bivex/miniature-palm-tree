//
//  MemoryProfiler.swift
//  ASTAnalyzer
//
//  Created for memory leak detection and profiling
//

import Foundation

/// Memory profiling utility for detecting potential memory leaks
public final class MemoryProfiler {

    private let memoryInfoProvider: MemoryInfoProvider
    private let snapshotStateHandler: MemorySnapshotStateHandler
    private let startTime = Date()
    private let snapshotOutputHandler: SnapshotOutputHandler
    private let reportFormatter: MemoryReportFormatter

    public init(memoryInfoProvider: MemoryInfoProvider = DefaultMemoryInfoProvider(),
                snapshotStateHandler: MemorySnapshotStateHandler = DefaultMemorySnapshotStateHandler(),
                snapshotOutputHandler: SnapshotOutputHandler = ConsoleSnapshotOutputHandler(),
                reportFormatter: MemoryReportFormatter = ConsoleMemoryReportFormatter()) {
        self.memoryInfoProvider = memoryInfoProvider
        self.snapshotStateHandler = snapshotStateHandler
        self.snapshotOutputHandler = snapshotOutputHandler
        self.reportFormatter = reportFormatter
    }

    /// Represents a memory snapshot at a specific point in time
    public struct MemorySnapshot {
        public let timestamp: Date
        public let residentSize: UInt64
        public let virtualSize: UInt64
        public let timestampDescription: String

        public var residentSizeMB: Double { Double(residentSize) / 1024.0 / 1024.0 }
        public var virtualSizeMB: Double { Double(virtualSize) / 1024.0 / 1024.0 }

        public init(timestamp: Date, residentSize: UInt64, virtualSize: UInt64, startTime: Date) {
            self.timestamp = timestamp
            self.residentSize = residentSize
            self.virtualSize = virtualSize
            self.timestampDescription = String(format: "%.2f", timestamp.timeIntervalSince(startTime))
        }
    }

    /// Current memory statistics
    public struct MemoryStats {
        public let residentSize: UInt64  // Physical memory used (RSS)
        public let virtualSize: UInt64   // Virtual memory allocated (VSZ)
        public let peakResidentSize: UInt64 // Peak RSS during profiling

        public var residentSizeMB: Double { Double(residentSize) / 1024.0 / 1024.0 }
        public var virtualSizeMB: Double { Double(virtualSize) / 1024.0 / 1024.0 }
        public var peakResidentSizeMB: Double { Double(peakResidentSize) / 1024.0 / 1024.0 }
    }

    /// Takes a memory snapshot
    public func takeSnapshot(label: String = "") {
        let stats = memoryInfoProvider.getMemoryStatistics()
        let snapshot = MemorySnapshot(
            timestamp: Date(),
            residentSize: stats.residentSize,
            virtualSize: stats.virtualSize,
            startTime: startTime
        )
        snapshotStateHandler.addSnapshot(snapshot)

        snapshotOutputHandler.outputSnapshot(snapshot: snapshot, label: label)
    }

    /// Gets current memory statistics
    public func getMemoryStats() -> MemoryStats {
        let stats = memoryInfoProvider.getMemoryStatistics()
        let currentPeakSize = snapshotStateHandler.getSnapshots().map { $0.residentSize }.max() ?? stats.residentSize
        return MemoryStats(
            residentSize: stats.residentSize,
            virtualSize: stats.virtualSize,
            peakResidentSize: currentPeakSize
        )
    }

    /// Analyzes memory usage patterns and detects potential leaks
    public func analyzeMemoryUsage() -> MemoryAnalysis {
        let snapshots = snapshotStateHandler.getSnapshots()
        guard snapshots.count >= 2 else {
            return MemoryAnalysis(
                totalSnapshots: snapshots.count,
                memoryGrowth: 0,
                averageGrowthRate: 0,
                potentialLeakDetected: false,
                recommendations: ["Take more snapshots for meaningful analysis"]
            )
        }

        let firstSnapshot = snapshots.first!
        let lastSnapshot = snapshots.last!

        let memoryGrowth = Int64(lastSnapshot.residentSize) - Int64(firstSnapshot.residentSize)
        let timeSpan = lastSnapshot.timestamp.timeIntervalSince(firstSnapshot.timestamp)
        let averageGrowthRate = timeSpan > 0 ? Double(memoryGrowth) / timeSpan : 0

        // Detect potential memory leak: significant growth over time
        let growthThreshold: UInt64 = 50 * 1024 * 1024  // 50 MB
        let growthRateThreshold: Double = 1024 * 1024   // 1 MB per second

        let potentialLeakDetected = memoryGrowth > growthThreshold ||
                                   (averageGrowthRate > growthRateThreshold && timeSpan > 10)

        var recommendations: [String] = []

        if potentialLeakDetected {
            recommendations.append("⚠️  Potential memory leak detected")
            recommendations.append("   Growth: \(String(format: "%.2f", Double(memoryGrowth) / 1024.0 / 1024.0)) MB")
            recommendations.append("   Rate: \(String(format: "%.2f", averageGrowthRate / 1024.0 / 1024.0)) MB/s")

            let enumeratedSnapshots = snapshots.enumerated()
            let peakSnapshot = enumeratedSnapshots.max(by: { $0.element.residentSize < $1.element.residentSize })
            if let peakIndex = peakSnapshot?.offset {
                recommendations.append("   Peak at snapshot \(peakIndex + 1)")
            }
        } else {
            recommendations.append("✅ No significant memory growth detected")
        }

        return MemoryAnalysis(
            totalSnapshots: snapshots.count,
            memoryGrowth: memoryGrowth,
            averageGrowthRate: averageGrowthRate,
            potentialLeakDetected: potentialLeakDetected,
            recommendations: recommendations
        )
    }

    /// Outputs a detailed memory report using the configured formatter
    public func outputMemoryReport() {
        let stats = getMemoryStats()
        let analysis = analyzeMemoryUsage()
        reportFormatter.outputMemoryReport(stats: stats, snapshots: snapshotStateHandler.getSnapshots(), analysis: analysis)
    }

    /// Resets profiling data
    public func reset() {
        snapshotStateHandler.clearSnapshots()
    }
}

/// Memory analysis results
public struct MemoryAnalysis {
    public let totalSnapshots: Int
    public let memoryGrowth: Int64  // Bytes
    public let averageGrowthRate: Double  // Bytes per second
    public let potentialLeakDetected: Bool
    public let recommendations: [String]
}