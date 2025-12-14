//
 //  JSONExporter.swift
 //  ASTAnalyzer
 //
 //  Created on 2025-12-14.
 //

import Foundation

/// Service for exporting analysis results to JSON format organized by smell types
public final class JSONExporter {

    private let fileManager: FileManager
    private let jsonEncoder: JSONEncoder

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.jsonEncoder.dateEncodingStrategy = .iso8601
    }

    /// Exports smell report to JSON files organized by smell type
    /// - Parameters:
    ///   - report: The smell report to export
    ///   - outputDirectory: Base directory for JSON export (defaults to current directory)
    /// - Throws: File system errors
    public func export(report: SmellReport, to outputDirectory: String = ".") throws {
        // Create timestamped subdirectory
        let timestamp = formatTimestamp(report.metadata.timestamp)
        let exportDirectory = "\(outputDirectory)/analysis_\(timestamp)"

        try createDirectoryIfNeeded(at: exportDirectory)

        // Group smells by type
        let smellsByType = Dictionary(grouping: report.smellsByClass.values.flatMap { $0 }) { $0.type }

        // Export each smell type to separate JSON file
        for (smellType, instances) in smellsByType {
            let jsonData = try createSmellTypeJSON(smellType: smellType, instances: instances, report: report)
            let filename = sanitizeFilename("\(smellType.rawValue).json")
            let filePath = "\(exportDirectory)/\(filename)"
            try jsonData.write(to: URL(fileURLWithPath: filePath))
        }

        // Export summary report
        let summaryData = try createSummaryJSON(report: report)
        let summaryPath = "\(exportDirectory)/summary.json"
        try summaryData.write(to: URL(fileURLWithPath: summaryPath))

        print("📁 JSON export completed: \(exportDirectory)")
        print("📊 Exported \(smellsByType.count) smell types + summary")
    }

    // MARK: - Private Methods

    private func createDirectoryIfNeeded(at path: String) throws {
        if !fileManager.fileExists(atPath: path) {
            try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: date)
    }

    private func sanitizeFilename(_ filename: String) -> String {
        // Replace spaces and special characters with underscores for filesystem safety
        let invalidChars = CharacterSet(charactersIn: " \\/:*?\"<>|")
        return filename.components(separatedBy: invalidChars).joined(separator: "_")
    }

    private func createSmellTypeJSON(smellType: DefectType, instances: [SmellInstance], report: SmellReport) throws -> Data {
        let smellTypeData: [String: Any] = [
            "smellType": smellType.rawValue,
            "description": SmellReport.getSmellTypeDescription(smellType),
            "totalInstances": instances.count,
            "instances": instances.map { $0.jsonRepresentation },
            "metadata": [
                "analysisTimestamp": report.metadata.timestamp.ISO8601Format(),
                "analysisDuration": report.metadata.duration,
                "filesAnalyzed": report.metadata.filesAnalyzed,
                "classesAnalyzed": report.metadata.classesAnalyzed,
                "methodsAnalyzed": report.metadata.methodsAnalyzed
            ]
        ]

        return try JSONSerialization.data(withJSONObject: smellTypeData, options: [.prettyPrinted, .sortedKeys])
    }

    private func createSummaryJSON(report: SmellReport) throws -> Data {
        return try JSONSerialization.data(withJSONObject: report.jsonRepresentation, options: [.prettyPrinted, .sortedKeys])
    }

}