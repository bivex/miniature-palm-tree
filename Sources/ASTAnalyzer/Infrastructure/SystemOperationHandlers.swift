//
//  SystemOperationHandlers.swift
//  ASTAnalyzer
//
//  Created on 2025-12-15.
//  Abstractions for system operations to eliminate imperative calls
//

import Foundation

/// Protocol for memory information retrieval operations
public protocol MemoryInfoProvider {
    func getMemoryStatistics() -> MemoryProfiler.MemoryStats
}

/// Protocol for argument parsing operations
public protocol ArgumentProcessingHandler {
    func getCommandLineArguments() -> [String]
}

/// Default implementation of MemoryInfoProvider
public final class DefaultMemoryInfoProvider: MemoryInfoProvider {
    public init() {}

    public func getMemoryStatistics() -> MemoryProfiler.MemoryStats {
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
            return MemoryProfiler.MemoryStats(
                residentSize: UInt64(info.resident_size),
                virtualSize: UInt64(info.virtual_size),
                peakResidentSize: 0 // This would need to be tracked separately
            )
        } else {
            // Fallback: use a basic estimation
            let estimatedSize = UInt64(50 * 1024 * 1024) // 50 MB estimate
            return MemoryProfiler.MemoryStats(
                residentSize: estimatedSize,
                virtualSize: estimatedSize,
                peakResidentSize: estimatedSize
            )
        }
    }
}

/// Protocol for handling memory snapshot state mutations
public protocol MemorySnapshotStateHandler {
    func addSnapshot(_ snapshot: MemoryProfiler.MemorySnapshot)
    func getSnapshots() -> [MemoryProfiler.MemorySnapshot]
    func clearSnapshots()
}

/// Default implementation of MemorySnapshotStateHandler
public final class DefaultMemorySnapshotStateHandler: MemorySnapshotStateHandler {
    private var snapshots: [MemoryProfiler.MemorySnapshot] = []

    public init() {}

    public func addSnapshot(_ snapshot: MemoryProfiler.MemorySnapshot) {
        snapshots.append(snapshot)
    }

    public func getSnapshots() -> [MemoryProfiler.MemorySnapshot] {
        return snapshots
    }

    public func clearSnapshots() {
        snapshots.removeAll()
    }
}

/// Default implementation of ArgumentProcessingHandler
public final class DefaultArgumentProcessingHandler: ArgumentProcessingHandler {
    public init() {}

    public func getCommandLineArguments() -> [String] {
        return CommandLine.arguments
    }
}

/// Protocol for handling argument parsing state mutations
public protocol ArgumentStateHandler {
    func addProcessedArgument(_ argument: String)
    func isArgumentProcessed(_ argument: String) -> Bool
    func getProcessedArguments() -> Set<String>
    func clearProcessedArguments()
}

/// Default implementation of ArgumentStateHandler
public final class DefaultArgumentStateHandler: ArgumentStateHandler {
    private var processedArgs: Set<String> = []

    public init() {}

    public func addProcessedArgument(_ argument: String) {
        processedArgs.insert(argument)
    }

    public func isArgumentProcessed(_ argument: String) -> Bool {
        return processedArgs.contains(argument)
    }

    public func getProcessedArguments() -> Set<String> {
        return processedArgs
    }

    public func clearProcessedArguments() {
        processedArgs.removeAll()
    }
}

/// Test implementation for testing purposes
public final class TestArgumentProcessingHandler: ArgumentProcessingHandler {
    private let testArguments: [String]

    public init(arguments: [String]) {
        self.testArguments = arguments
    }

    public func getCommandLineArguments() -> [String] {
        return testArguments
    }
}