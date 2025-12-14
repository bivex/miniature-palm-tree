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

    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Parses command line arguments into configuration
    /// - Parameter arguments: Command line arguments
    /// - Returns: Parsed analysis configuration
    /// - Throws: ApplicationError if arguments are invalid
    public func parseArguments(_ arguments: [String]) throws -> AnalysisConfig {
        try validateArgumentCount(arguments)

        let (enableJSONExport, jsonOutputDirectory, enableMarkdownExport, markdownOutputDirectory, thresholdsFilePath, pathArgumentIndex) = parseExportOptions(arguments)

        let path = arguments[pathArgumentIndex]
        let pathType = try validatePath(path, executableName: arguments[0])

        try validateAndCreateJSONOutputDirectory(jsonOutputDirectory, executableName: arguments[0])
        try validateAndCreateMarkdownOutputDirectory(markdownOutputDirectory, executableName: arguments[0])
        try validateThresholdsFile(thresholdsFilePath, executableName: arguments[0])

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

    private func parseExportOptions(_ arguments: [String]) -> (enableJSONExport: Bool, jsonOutputDirectory: String?, enableMarkdownExport: Bool, markdownOutputDirectory: String?, thresholdsFilePath: String?, pathArgumentIndex: Int) {
        var processedArgs = Set<String>()

        let (enableJSONExport, jsonOutputDirectory) = parseJSONFlag(arguments, processedArgs: &processedArgs)
        let (enableMarkdownExport, markdownOutputDirectory) = parseMarkdownFlag(arguments, processedArgs: &processedArgs)
        let thresholdsFilePath = parseThresholdsFlag(arguments, processedArgs: &processedArgs)
        let pathArgumentIndex = determinePathArgumentIndex(arguments, processedArgs: processedArgs)

        return (enableJSONExport, jsonOutputDirectory, enableMarkdownExport, markdownOutputDirectory, thresholdsFilePath, pathArgumentIndex)
    }

    private func parseJSONFlag(_ arguments: [String], processedArgs: inout Set<String>) -> (enabled: Bool, directory: String?) {
        guard arguments.contains("--json") else { return (false, nil) }

        let jsonIndex = arguments.firstIndex(of: "--json")!
        processedArgs.insert("--json")

        if jsonIndex + 1 < arguments.count && !arguments[jsonIndex + 1].hasPrefix("-") {
            let directory = arguments[jsonIndex + 1]
            processedArgs.insert(directory)
            return (true, directory)
        }

        return (true, nil)
    }

    private func parseMarkdownFlag(_ arguments: [String], processedArgs: inout Set<String>) -> (enabled: Bool, directory: String?) {
        guard arguments.contains("--markdown") else { return (false, nil) }

        let markdownIndex = arguments.firstIndex(of: "--markdown")!
        processedArgs.insert("--markdown")

        if markdownIndex + 1 < arguments.count && !arguments[markdownIndex + 1].hasPrefix("-") && !processedArgs.contains(arguments[markdownIndex + 1]) {
            let directory = arguments[markdownIndex + 1]
            processedArgs.insert(directory)
            return (true, directory)
        }

        return (true, nil)
    }

    private func parseThresholdsFlag(_ arguments: [String], processedArgs: inout Set<String>) -> String? {
        guard arguments.contains("--thresholds") else { return nil }

        let thresholdsIndex = arguments.firstIndex(of: "--thresholds")!
        processedArgs.insert("--thresholds")

        if thresholdsIndex + 1 < arguments.count && !arguments[thresholdsIndex + 1].hasPrefix("-") {
            let filePath = arguments[thresholdsIndex + 1]
            processedArgs.insert(filePath)
            return filePath
        }

        return nil
    }

    private func determinePathArgumentIndex(_ arguments: [String], processedArgs: Set<String>) -> Int {
        for (index, arg) in arguments.enumerated() {
            if index > 0 && !arg.hasPrefix("-") && !processedArgs.contains(arg) {
                return index
            }
        }
        return 1
    }

    private func validatePath(_ path: String, executableName: String) throws -> PathType {
        // Validate path
        guard !path.isEmpty else {
            throw ApplicationError.invalidArguments(
                message: "Path cannot be empty",
                example: "\(executableName) /path/to/file.swift --json /path/to/output"
            )
        }

        var isDirectory: ObjCBool = false

        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
            throw ApplicationError.invalidArguments(
                message: "Path '\(path)' does not exist",
                example: "\(executableName) /path/to/file.swift --json /path/to/output"
            )
        }

        if isDirectory.boolValue {
            return .directory(path)
        } else {
            // Validate it's a Swift file
            guard path.hasSuffix(".swift") else {
                throw ApplicationError.invalidArguments(
                    message: "File must be a Swift source file (.swift)",
                    example: "\(executableName) /path/to/file.swift --json /path/to/output"
                )
            }
            return .file(path)
        }
    }

    private func validateAndCreateJSONOutputDirectory(_ outputDir: String?, executableName: String) throws {
        guard let outputDir = outputDir else { return }

        var isOutputDir: ObjCBool = false
        if fileManager.fileExists(atPath: outputDir, isDirectory: &isOutputDir) {
            guard isOutputDir.boolValue else {
                throw ApplicationError.invalidArguments(
                    message: "JSON output path must be a directory: \(outputDir)",
                    example: "\(executableName) /path/to/file.swift --json /path/to/output/dir"
                )
            }
        } else {
            // Directory doesn't exist, we'll create it
            do {
                try fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
            } catch {
                throw ApplicationError.invalidArguments(
                    message: "Cannot create JSON output directory: \(outputDir)",
                    example: "\(executableName) /path/to/file.swift --json /path/to/output/dir"
                )
            }
        }
    }

    private func validateAndCreateMarkdownOutputDirectory(_ outputDir: String?, executableName: String) throws {
        guard let outputDir = outputDir else { return }

        var isOutputDir: ObjCBool = false
        if fileManager.fileExists(atPath: outputDir, isDirectory: &isOutputDir) {
            guard isOutputDir.boolValue else {
                throw ApplicationError.invalidArguments(
                    message: "Markdown output path must be a directory: \(outputDir)",
                    example: "\(executableName) /path/to/file.swift --markdown /path/to/output/dir"
                )
            }
        } else {
            // Directory doesn't exist, we'll create it
            do {
                try fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
            } catch {
                throw ApplicationError.invalidArguments(
                    message: "Cannot create Markdown output directory: \(outputDir)",
                    example: "\(executableName) /path/to/file.swift --markdown /path/to/output/dir"
                )
            }
        }
    }

    private func validateThresholdsFile(_ thresholdsFile: String?, executableName: String) throws {
        guard let thresholdsFile = thresholdsFile else { return }

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: thresholdsFile, isDirectory: &isDirectory) else {
            throw ApplicationError.invalidArguments(
                message: "Thresholds file does not exist: \(thresholdsFile)",
                example: "\(executableName) /path/to/file.swift --thresholds /path/to/thresholds.yml"
            )
        }

        guard !isDirectory.boolValue else {
            throw ApplicationError.invalidArguments(
                message: "Thresholds path must be a file, not a directory: \(thresholdsFile)",
                example: "\(executableName) /path/to/file.swift --thresholds /path/to/thresholds.yml"
            )
        }

        // Check if it's a YAML file
        guard thresholdsFile.hasSuffix(".yml") || thresholdsFile.hasSuffix(".yaml") else {
            throw ApplicationError.invalidArguments(
                message: "Thresholds file must be a YAML file (.yml or .yaml): \(thresholdsFile)",
                example: "\(executableName) /path/to/file.swift --thresholds /path/to/thresholds.yml"
            )
        }
    }
}