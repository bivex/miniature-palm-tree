//
//  ImperativeAbstractionModels.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Models for Imperative Abstraction detection
//

import Foundation

/// Information about a type with imperative abstraction issues
struct ImperativeTypeInfo {
    let typeName: String // "Class", "Struct", etc.
    let name: String
    let execCount: Int
    let totalElements: Int
    let execRatio: Double
}