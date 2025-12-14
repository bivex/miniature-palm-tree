//
//  ArgumentParser.swift
//  ASTAnalyzer
//
//  Created on 2025-12-14.
//

import Foundation

/// Configuration for analysis execution
public struct AnalysisConfig {
    let pathType: PathType
    let enableJSONExport: Bool
    let jsonOutputDirectory: String?
    let enableMarkdownExport: Bool
    let markdownOutputDirectory: String?
    let thresholdsFilePath: String?

    init(pathType: PathType, enableJSONExport: Bool = false, jsonOutputDirectory: String? = nil, enableMarkdownExport: Bool = false, markdownOutputDirectory: String? = nil, thresholdsFilePath: String? = nil) {
        self.pathType = pathType
        self.enableJSONExport = enableJSONExport
        self.jsonOutputDirectory = jsonOutputDirectory
        self.enableMarkdownExport = enableMarkdownExport
        self.markdownOutputDirectory = markdownOutputDirectory
        self.thresholdsFilePath = thresholdsFilePath
    }
}

/// Enum representing the type of path (file or directory)
public enum PathType {
    case file(String)
    case directory(String)
}

/// Service responsible for parsing command line arguments
public final class ArgumentParser {

    private let argumentProcessingHandler: ArgumentProcessingHandler
    private let fileSystemValidator: FileSystemValidator

    public init(argumentProcessingHandler: ArgumentProcessingHandler = DefaultArgumentProcessingHandler(),
                fileSystemValidator: FileSystemValidator = DefaultFileSystemValidator()) {
        self.argumentProcessingHandler = argumentProcessingHandler
        self.fileSystemValidator = fileSystemValidator
    }

    /// Parses command line arguments into configuration
    /// - Parameter arguments: Command line arguments
    /// - Returns: Parsed analysis configuration
    /// - Throws: ApplicationError if arguments are invalid
    public func parseArguments(_ arguments: [String]) throws -> AnalysisConfig {
        try validateArgumentCount(arguments)

        let stateHandler = DefaultArgumentStateHandler()
        let (enableJSONExport, jsonOutputDirectory, enableMarkdownExport, markdownOutputDirectory, thresholdsFilePath, pathArgumentIndex) = parseExportOptions(arguments, stateHandler: stateHandler)

        let path = arguments[pathArgumentIndex]
        let pathType = try fileSystemValidator.validatePath(path)

        try fileSystemValidator.validateAndCreateJSONOutputDirectory(jsonOutputDirectory)
        try fileSystemValidator.validateAndCreateMarkdownOutputDirectory(markdownOutputDirectory)
        try fileSystemValidator.validateThresholdsFile(thresholdsFilePath)

        return AnalysisConfig(
            pathType: pathType,
            enableJSONExport: enableJSONExport,
            jsonOutputDirectory: jsonOutputDirectory,
            enableMarkdownExport: enableMarkdownExport,
            markdownOutputDirectory: markdownOutputDirectory,
            thresholdsFilePath: thresholdsFilePath
        )
    }

    // MARK: - Private Methods

    private func validateArgumentCount(_ arguments: [String]) throws {
        // Filter out profiling flags for argument count validation
        let filteredArgs = arguments.filter { !$0.hasPrefix("--profile") }
        guard filteredArgs.count >= 2 else {
            throw ApplicationError.invalidArguments(
                message: "Usage: \(arguments[0]) <swift_file_path_or_directory> [--json [output_directory]] [--markdown [output_directory]] [--thresholds file.yml] [--profile-memory]",
                example: "\(arguments[0]) /path/to/file.swift --json /path/to/output --markdown ./reports --thresholds config.yml --profile-memory"
            )
        }
    }

    private func parseExportOptions(_ arguments: [String], stateHandler: ArgumentStateHandler) -> (enableJSONExport: Bool, jsonOutputDirectory: String?, enableMarkdownExport: Bool, markdownOutputDirectory: String?, thresholdsFilePath: String?, pathArgumentIndex: Int) {
        let (enableJSONExport, jsonOutputDirectory) = parseJSONFlag(arguments, stateHandler: stateHandler)
        let (enableMarkdownExport, markdownOutputDirectory) = parseMarkdownFlag(arguments, stateHandler: stateHandler)
        let thresholdsFilePath = parseThresholdsFlag(arguments, stateHandler: stateHandler)
        let pathArgumentIndex = determinePathArgumentIndex(arguments, stateHandler: stateHandler)

        return (enableJSONExport, jsonOutputDirectory, enableMarkdownExport, markdownOutputDirectory, thresholdsFilePath, pathArgumentIndex)
    }

    private func parseJSONFlag(_ arguments: [String], stateHandler: ArgumentStateHandler) -> (enabled: Bool, directory: String?) {
        guard arguments.contains("--json") else { return (false, nil) }

        let jsonIndex = arguments.firstIndex(of: "--json")!
        stateHandler.addProcessedArgument("--json")

        if jsonIndex + 1 < arguments.count && !arguments[jsonIndex + 1].hasPrefix("-") {
            let directory = arguments[jsonIndex + 1]
            stateHandler.addProcessedArgument(directory)
            return (true, directory)
        }

        return (true, nil)
    }

    private func parseMarkdownFlag(_ arguments: [String], stateHandler: ArgumentStateHandler) -> (enabled: Bool, directory: String?) {
        guard arguments.contains("--markdown") else { return (false, nil) }

        let markdownIndex = arguments.firstIndex(of: "--markdown")!
        stateHandler.addProcessedArgument("--markdown")

        if markdownIndex + 1 < arguments.count && !arguments[markdownIndex + 1].hasPrefix("-") && !stateHandler.isArgumentProcessed(arguments[markdownIndex + 1]) {
            let directory = arguments[markdownIndex + 1]
            stateHandler.addProcessedArgument(directory)
            return (true, directory)
        }

        return (true, nil)
    }

    private func parseThresholdsFlag(_ arguments: [String], stateHandler: ArgumentStateHandler) -> String? {
        guard arguments.contains("--thresholds") else { return nil }

        let thresholdsIndex = arguments.firstIndex(of: "--thresholds")!
        stateHandler.addProcessedArgument("--thresholds")

        if thresholdsIndex + 1 < arguments.count && !arguments[thresholdsIndex + 1].hasPrefix("-") {
            let filePath = arguments[thresholdsIndex + 1]
            stateHandler.addProcessedArgument(filePath)

            // Convert relative path to absolute path
            return fileSystemValidator.resolveAbsolutePath(filePath)
        }

        return nil
    }

    private func determinePathArgumentIndex(_ arguments: [String], stateHandler: ArgumentStateHandler) -> Int {
        for (index, arg) in arguments.enumerated() {
            if index > 0 && !arg.hasPrefix("-") && !stateHandler.isArgumentProcessed(arg) {
                return index
            }
        }
        return 1
    }

}