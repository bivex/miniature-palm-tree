//
//  ConsoleUtilities.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Common utilities for console output formatting
//

import Foundation

/// Utility extensions for console output
extension String {
    /// Repeats a string a given number of times
    /// - Parameters:
    ///   - lhs: The string to repeat
    ///   - rhs: The number of times to repeat
    /// - Returns: The repeated string
    static func *(lhs: String, rhs: Int) -> String {
        String(repeating: lhs, count: rhs)
    }
}