//
//  CodeElement.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Code element enumeration for architectural defect analysis
//

import Foundation

/// Represents a code element that can contain smells
public enum CodeElement: Codable, Equatable {
    case `class`(name: String)
    case method(className: String, methodName: String)
    case file(path: String)

    public var name: String {
        switch self {
        case .class(let name): return name
        case .method(_, let methodName): return methodName
        case .file(let path): return path
        }
    }

    public var displayName: String {
        switch self {
        case .class(let name): return "class \(name)"
        case .method(let className, let methodName): return "\(className).\(methodName)"
        case .file(let path): return path
        }
    }
}