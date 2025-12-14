//
//  FileSystemValidator.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Protocol for file system validation operations
//

import Foundation

/// Protocol for file system validation operations
public protocol FileSystemValidator {
    /// Validates that a path exists and returns its type
    func validatePath(_ path: String) throws -> PathType

    /// Validates and creates a JSON output directory if needed
    func validateAndCreateJSONOutputDirectory(_ outputDir: String?) throws

    /// Validates and creates a Markdown output directory if needed
    func validateAndCreateMarkdownOutputDirectory(_ outputDir: String?) throws

    /// Validates that a thresholds file exists and is valid
    func validateThresholdsFile(_ thresholdsFile: String?) throws

    /// Converts a relative path to an absolute path
    func resolveAbsolutePath(_ path: String) -> String
}

/// Implementation of FileSystemValidator
public final class DefaultFileSystemValidator: FileSystemValidator {

    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func validatePath(_ path: String) throws -> PathType {
        // Validate path
        guard !path.isEmpty else {
            throw ApplicationError.invalidArguments(
                message: "Path cannot be empty",
                example: "astanalyzer /path/to/file.swift --json /path/to/output"
            )
        }

        var isDirectory: ObjCBool = false

        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
            throw ApplicationError.invalidArguments(
                message: "Path '\(path)' does not exist",
                example: "astanalyzer /path/to/file.swift --json /path/to/output"
            )
        }

        if isDirectory.boolValue {
            return .directory(path)
        } else {
            // Validate it's a Swift file
            guard path.hasSuffix(".swift") else {
                throw ApplicationError.invalidArguments(
                    message: "File must be a Swift source file (.swift)",
                    example: "astanalyzer /path/to/file.swift --json /path/to/output"
                )
            }
            return .file(path)
        }
    }

    public func validateAndCreateJSONOutputDirectory(_ outputDir: String?) throws {
        guard let outputDir = outputDir else { return }

        var isOutputDir: ObjCBool = false
        if fileManager.fileExists(atPath: outputDir, isDirectory: &isOutputDir) {
            guard isOutputDir.boolValue else {
                throw ApplicationError.invalidArguments(
                    message: "JSON output path must be a directory: \(outputDir)",
                    example: "astanalyzer /path/to/file.swift --json /path/to/output/dir"
                )
            }
        } else {
            // Directory doesn't exist, we'll create it
            do {
                try fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
            } catch {
                throw ApplicationError.invalidArguments(
                    message: "Cannot create JSON output directory: \(outputDir)",
                    example: "astanalyzer /path/to/file.swift --json /path/to/output/dir"
                )
            }
        }
    }

    public func validateAndCreateMarkdownOutputDirectory(_ outputDir: String?) throws {
        guard let outputDir = outputDir else { return }

        var isOutputDir: ObjCBool = false
        if fileManager.fileExists(atPath: outputDir, isDirectory: &isOutputDir) {
            guard isOutputDir.boolValue else {
                throw ApplicationError.invalidArguments(
                    message: "Markdown output path must be a directory: \(outputDir)",
                    example: "astanalyzer /path/to/file.swift --markdown /path/to/output/dir"
                )
            }
        } else {
            // Directory doesn't exist, we'll create it
            do {
                try fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
            } catch {
                throw ApplicationError.invalidArguments(
                    message: "Cannot create Markdown output directory: \(outputDir)",
                    example: "astanalyzer /path/to/file.swift --markdown /path/to/output/dir"
                )
            }
        }
    }

    public func validateThresholdsFile(_ thresholdsFile: String?) throws {
        guard let thresholdsFile = thresholdsFile else { return }

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: thresholdsFile, isDirectory: &isDirectory) else {
            throw ApplicationError.invalidArguments(
                message: "Thresholds file does not exist: \(thresholdsFile)",
                example: "astanalyzer /path/to/file.swift --thresholds /path/to/thresholds.yml"
            )
        }

        guard !isDirectory.boolValue else {
            throw ApplicationError.invalidArguments(
                message: "Thresholds path must be a file, not a directory: \(thresholdsFile)",
                example: "astanalyzer /path/to/file.swift --thresholds /path/to/thresholds.yml"
            )
        }

        // Check if it's a YAML file
        guard thresholdsFile.hasSuffix(".yml") || thresholdsFile.hasSuffix(".yaml") else {
            throw ApplicationError.invalidArguments(
                message: "Thresholds file must be a YAML file (.yml or .yaml): \(thresholdsFile)",
                example: "astanalyzer /path/to/file.swift --thresholds /path/to/thresholds.yml"
            )
        }
    }

    public func resolveAbsolutePath(_ path: String) -> String {
        if path.hasPrefix("/") {
            return path
        } else {
            let currentDirectory = fileManager.currentDirectoryPath
            return (currentDirectory as NSString).appendingPathComponent(path)
        }
    }
}