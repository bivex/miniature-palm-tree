//
//  ConsoleOutputHandler.swift
//  ASTAnalyzer
//
//  Created on 2025-12-15.
//  Protocol for console output operations to separate side effects from formatting logic
//

/// Protocol for handling console output operations
public protocol ConsoleOutputHandler {
    /// Outputs a line of text to the console
    func output(_ text: String)

    /// Outputs a line of text with a newline terminator
    func outputLine(_ text: String)

    /// Outputs text without a trailing newline
    func outputInline(_ text: String)

    /// Outputs an empty line
    func outputEmptyLine()
}

/// Default console implementation that uses standard print statements
public final class StandardConsoleOutputHandler: ConsoleOutputHandler {
    public init() {}

    public func output(_ text: String) {
        print(text)
    }

    public func outputLine(_ text: String) {
        print(text)
    }

    public func outputInline(_ text: String) {
        print(text, terminator: "")
    }

    public func outputEmptyLine() {
        print()
    }
}

/// Test console implementation that captures output for testing
public final class TestConsoleOutputHandler: ConsoleOutputHandler {
    public private(set) var outputLines: [String] = []

    public init() {}

    public func output(_ text: String) {
        outputLines.append(text)
    }

    public func outputLine(_ text: String) {
        outputLines.append(text)
    }

    public func outputInline(_ text: String) {
        if outputLines.isEmpty {
            outputLines.append(text)
        } else {
            outputLines[outputLines.count - 1] += text
        }
    }

    public func outputEmptyLine() {
        outputLines.append("")
    }

    public func clearOutput() {
        outputLines.removeAll()
    }
}