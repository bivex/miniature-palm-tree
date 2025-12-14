//
//  main.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//

import Foundation

/// Main entry point for the AST Analyzer command-line tool
func main() async {
    do {
        let argumentParser = ArgumentParser()
        let config = try argumentParser.parseArguments(CommandLine.arguments)
        let application = try ConsoleApplication(config: config)
        await application.run(with: CommandLine.arguments)
    } catch {
        let errorHandler = ErrorHandler()
        errorHandler.handleError(error)
    }
}

// Run the application
await main()