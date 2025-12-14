//
//  ErrorHandler.swift
//  ASTAnalyzer
//
//  Created on 2025-12-14.
//

import Foundation

/// Service responsible for handling and presenting errors
public final class ErrorHandler {

    /// Handles an error by presenting appropriate message and exiting
    /// - Parameter error: The error to handle
    public func handleError(_ error: Error) -> Never {
        switch error {
        case let analysisError as AnalysisError:
            print("❌ Analysis Error: \(analysisError.localizedDescription)")

        case let appError as ApplicationError:
            print("❌ Application Error: \(appError.localizedDescription)")
            if let example = appError.example {
                print("💡 Example: \(example)")
            }

        default:
            print("❌ Unexpected Error: \(error.localizedDescription)")
        }

        exit(1)
    }
}

/// Application-specific errors
public enum ApplicationError: Error {
    case invalidArguments(message: String, example: String?)

    public var localizedDescription: String {
        switch self {
        case .invalidArguments(let message, _):
            return message
        }
    }

    public var example: String? {
        switch self {
        case .invalidArguments(_, let example):
            return example
        }
    }
}