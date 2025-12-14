//
//  ConsoleApplication.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//

import Foundation

/// Console application entry point using Z notation-based analysis
public final class ConsoleApplication {

    private let argumentParser: ArgumentParser
    private let analyzer: ProjectSmellAnalyzer
    private let fileSystemService: FileSystemService
    private let outputManager: OutputManager
    private let errorHandler: ErrorHandler

    public init(thresholds: Thresholds = .academic) {
        self.argumentParser = ArgumentParser()
        self.analyzer = ProjectSmellAnalyzer(thresholds: thresholds)
        self.fileSystemService = FileSystemService()
        self.outputManager = OutputManager(
            filePresenter: AnalysisResultPresenter(),
            directoryPresenter: DirectoryAnalysisResultPresenter(),
            jsonExporter: JSONExporter(),
            markdownExporter: MarkdownExporter()
        )
        self.errorHandler = ErrorHandler()
    }

    public init(config: AnalysisConfig) throws {
        self.argumentParser = ArgumentParser()

        // Load thresholds from YAML file if specified, otherwise use academic defaults
        let thresholds = try config.thresholdsFilePath.map { try Thresholds.fromYAMLFile(at: $0) } ?? .academic

        self.analyzer = ProjectSmellAnalyzer(thresholds: thresholds)
        self.fileSystemService = FileSystemService()
        self.outputManager = OutputManager(
            filePresenter: AnalysisResultPresenter(),
            directoryPresenter: DirectoryAnalysisResultPresenter(),
            jsonExporter: JSONExporter(),
            markdownExporter: MarkdownExporter()
        )
        self.errorHandler = ErrorHandler()
    }

    /// Runs the console application with command line arguments
    /// - Parameter arguments: Command line arguments
    public func run(with arguments: [String]) async {
        let profiler = setupMemoryProfiling(with: arguments)

        do {
            let config = try argumentParser.parseArguments(arguments)

            profiler?.takeSnapshot(label: "before_analysis")
            let report = try await performAnalysis(with: config)
            profiler?.takeSnapshot(label: "after_analysis")

            outputManager.presentResults(report: report, config: config)

            profiler?.takeSnapshot(label: "before_exports")
            try outputManager.exportResults(report: report, config: config)
            profiler?.takeSnapshot(label: "after_exports")

            finalizeMemoryProfiling(profiler)

        } catch {
            errorHandler.handleError(error)
        }
    }

    // MARK: - Private Methods

    private func setupMemoryProfiling(with arguments: [String]) -> MemoryProfiler? {
        let enableMemoryProfiling = arguments.contains("--profile-memory")
        let profiler = enableMemoryProfiling ? MemoryProfiler() : nil

        if enableMemoryProfiling {
            print("🧠 Memory profiling enabled")
            profiler?.takeSnapshot(label: "start")
        }

        return profiler
    }

    private func finalizeMemoryProfiling(_ profiler: MemoryProfiler?) {
        profiler?.takeSnapshot(label: "end")
        profiler?.outputMemoryReport()
    }

    private func performAnalysis(with config: AnalysisConfig) async throws -> SmellReport {
        switch config.pathType {
        case .file(let filePath):
            let content = try fileSystemService.loadFileContent(at: filePath)
            let sourceFile = SourceFile(filePath: filePath, content: content)
            try sourceFile.validate()
            let sourceFiles = [sourceFile]
            return await analyzer.analyze(sourceFiles: sourceFiles)

        case .directory(let directoryPath):
            let swiftFilePaths = try fileSystemService.findSwiftFiles(in: directoryPath)
            guard !swiftFilePaths.isEmpty else {
                throw AnalysisError.noSwiftFilesFound(directoryPath: directoryPath)
            }
            let sourceFiles = try swiftFilePaths.map { path in
                let content = try fileSystemService.loadFileContent(at: path)
                return SourceFile(filePath: path, content: content)
            }
            return await analyzer.analyze(sourceFiles: sourceFiles)
        }
    }
}