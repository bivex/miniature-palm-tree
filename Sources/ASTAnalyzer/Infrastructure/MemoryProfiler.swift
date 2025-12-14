//
//  MemoryProfiler.swift
//  ASTAnalyzer
//
//  Created for memory leak detection and profiling
//

import Foundation

/// Memory profiling utility for detecting potential memory leaks
public final class MemoryProfiler {

    private var memorySnapshots: [MemorySnapshot] = []
    private let startTime = Date()

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

    public init() {}

    /// Takes a memory snapshot
    public func takeSnapshot(label: String = "") {
        let stats = getMemoryStats()
        let snapshot = MemorySnapshot(
            timestamp: Date(),
            residentSize: stats.residentSize,
            virtualSize: stats.virtualSize,
            startTime: startTime
        )
        memorySnapshots.append(snapshot)

        if !label.isEmpty {
            print("📊 Memory snapshot '\(label)': \(String(format: "%.2f", snapshot.residentSizeMB)) MB RSS")
        }
    }

    /// Gets current memory statistics
    public func getMemoryStats() -> MemoryStats {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         intPtr,
                         &count)
            }
        }

        if result == KERN_SUCCESS {
            let currentPeakSize = memorySnapshots.map { $0.residentSize }.max() ?? info.resident_size
            return MemoryStats(
                residentSize: UInt64(info.resident_size),
                virtualSize: UInt64(info.virtual_size),
                peakResidentSize: currentPeakSize
            )
        } else {
            // Fallback: use a basic estimation
            // Note: This is a simplified fallback when task_info fails
            let estimatedSize = UInt64(50 * 1024 * 1024) // 50 MB estimate
            let fallbackPeakSize = memorySnapshots.map { $0.residentSize }.max() ?? estimatedSize
            return MemoryStats(
                residentSize: estimatedSize,
                virtualSize: estimatedSize,
                peakResidentSize: fallbackPeakSize
            )
        }
    }

    /// Analyzes memory usage patterns and detects potential leaks
    public func analyzeMemoryUsage() -> MemoryAnalysis {
        guard memorySnapshots.count >= 2 else {
            return MemoryAnalysis(
                totalSnapshots: memorySnapshots.count,
                memoryGrowth: 0,
                averageGrowthRate: 0,
                potentialLeakDetected: false,
                recommendations: ["Take more snapshots for meaningful analysis"]
            )
        }

        let firstSnapshot = memorySnapshots.first!
        let lastSnapshot = memorySnapshots.last!

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

            let enumeratedSnapshots = memorySnapshots.enumerated()
            let peakSnapshot = enumeratedSnapshots.max(by: { $0.element.residentSize < $1.element.residentSize })
            if let peakIndex = peakSnapshot?.offset {
                recommendations.append("   Peak at snapshot \(peakIndex + 1)")
            }
        } else {
            recommendations.append("✅ No significant memory growth detected")
        }

        return MemoryAnalysis(
            totalSnapshots: memorySnapshots.count,
            memoryGrowth: memoryGrowth,
            averageGrowthRate: averageGrowthRate,
            potentialLeakDetected: potentialLeakDetected,
            recommendations: recommendations
        )
    }

    /// Prints a detailed memory report
    public func printMemoryReport() {
        print("\n📊 Memory Profiling Report")
        print("==========================")

        let stats = getMemoryStats()
        print("Current Memory Usage:")
        print("  Resident Size (RSS): \(String(format: "%.2f", stats.residentSizeMB)) MB")
        print("  Virtual Size (VSZ): \(String(format: "%.2f", stats.virtualSizeMB)) MB")
        print("  Peak RSS: \(String(format: "%.2f", stats.peakResidentSizeMB)) MB")

        if !memorySnapshots.isEmpty {
            print("\nSnapshot History (\(memorySnapshots.count) snapshots):")
            for (index, snapshot) in memorySnapshots.enumerated() {
                let timeDesc = snapshot.timestampDescription
                let rssMB = Double(snapshot.residentSize) / 1024.0 / 1024.0
                let vszMB = Double(snapshot.virtualSize) / 1024.0 / 1024.0
                print("  \(index + 1). \(timeDesc)s: RSS=\(String(format: "%.2f", rssMB)) MB, VSZ=\(String(format: "%.2f", vszMB)) MB")
            }
        }

        let analysis = analyzeMemoryUsage()
        print("\nAnalysis:")
        for recommendation in analysis.recommendations {
            print("  \(recommendation)")
        }
    }

    /// Resets profiling data
    public func reset() {
        memorySnapshots.removeAll()
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