//
//  ZNotationModels.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Formal models based on Z notation specifications for architectural defect detection
//

import Foundation

// MARK: - Basic Types (from Z notation)

/// Access levels for Swift declarations (extended from Z notation)
public enum AccessLevel: String, CaseIterable {
    case `private`
    case `fileprivate`
    case `internal`
    case `public`
    case `open`
}

/// Represents a Swift type (simplified for analysis)
public struct Type: Equatable, Hashable {
    public let name: String
    public let isOptional: Bool

    public init(name: String, isOptional: Bool = false) {
        self.name = name
        self.isOptional = isOptional
    }
}

/// Parameter in a method signature
public struct Parameter: Equatable, Hashable {
    public let name: String
    public let type: Type

    public init(name: String, type: Type) {
        self.name = name
        self.type = type
    }
}

// MARK: - Core Entities (from Z notation)

/**
 Class model based on Z notation:
 ```
 Class
 ├─ name : NAME
 ├─ methods : ℙ Method
 ├─ attributes : ℙ Attribute
 ├─ parentName : NAME ∪ {∅}
 ├─ protocols : ℙ Protocol
 ├─ accessLevel : AccessLevel
 ├─ loc : ℕ
 ├─ isViewController : 𝔹
 └─ loc > 0 ∧ name ≠ ∅
 ```
 */
public struct Class: Equatable, Hashable {
    public let name: String
    public let methods: Set<Method>
    public let attributes: Set<Attribute>
    public let parentName: String? // Parent class name (not full reference to avoid recursion)
    public let protocols: Set<String> // Protocol names
    public let accessLevel: AccessLevel
    public let loc: Int
    public let isViewController: Bool

    public init(
        name: String,
        methods: Set<Method> = [],
        attributes: Set<Attribute> = [],
        parentName: String? = nil,
        protocols: Set<String> = [],
        accessLevel: AccessLevel = .internal,
        loc: Int,
        isViewController: Bool = false
    ) {
        precondition(loc > 0, "LOC must be greater than 0")
        precondition(!name.isEmpty, "Name cannot be empty")

        self.name = name
        self.methods = methods
        self.attributes = attributes
        self.parentName = parentName
        self.protocols = protocols
        self.accessLevel = accessLevel
        self.loc = loc
        self.isViewController = isViewController
    }

    // Computed properties for analysis
    public var nom: Int { methods.count }
    public var nof: Int { attributes.count }
    public var noa: Int { attributes.filter { !$0.isComputed }.count }
}

/**
 Method model based on Z notation:
 ```
 Method
 ├─ name : NAME
 ├─ parameters : seq Parameter
 ├─ returnType : Type
 ├─ accessLevel : AccessLevel
 ├─ instructions : seq INSTRUCTION
 ├─ loc : ℕ
 ├─ cyclomaticComplexity : ℕ
 ├─ accessedAttributes : ℙ Attribute
 ├─ calledMethods : ℙ Method
 ├─ foreignDataAccess : ℙ Attribute
 ├─ nestingDepth : ℕ
 └─ loc ≥ 1 ∧ cyclomaticComplexity ≥ 1
 ```
 */
public struct Method: Equatable, Hashable {
    public let name: String
    public let parameters: [Parameter]
    public let returnType: Type?
    public let accessLevel: AccessLevel
    public let instructions: [String] // Simplified as strings
    public let loc: Int
    public let cyclomaticComplexity: Int
    public let accessedAttributes: Set<Attribute>
    public let calledMethods: Set<Method>
    public let foreignDataAccess: Set<Attribute>
    public let nestingDepth: Int

    public init(
        name: String,
        parameters: [Parameter] = [],
        returnType: Type? = nil,
        accessLevel: AccessLevel = .internal,
        instructions: [String] = [],
        loc: Int,
        cyclomaticComplexity: Int,
        accessedAttributes: Set<Attribute> = [],
        calledMethods: Set<Method> = [],
        foreignDataAccess: Set<Attribute> = [],
        nestingDepth: Int = 0
    ) {
        precondition(loc >= 1, "LOC must be at least 1")
        precondition(cyclomaticComplexity >= 1, "Cyclomatic complexity must be at least 1")

        self.name = name
        self.parameters = parameters
        self.returnType = returnType
        self.accessLevel = accessLevel
        self.instructions = instructions
        self.loc = loc
        self.cyclomaticComplexity = cyclomaticComplexity
        self.accessedAttributes = accessedAttributes
        self.calledMethods = calledMethods
        self.foreignDataAccess = foreignDataAccess
        self.nestingDepth = nestingDepth
    }

    // Computed properties for analysis
    public var noi: Int { instructions.count }
    public var nop: Int { parameters.count }
}

/**
 Attribute model based on Z notation:
 ```
 Attribute
 ├─ name : NAME
 ├─ type : Type
 ├─ accessLevel : AccessLevel
 ├─ isComputed : 𝔹
 ├─ hasGetter : 𝔹
 ├─ hasSetter : 𝔹
 └─
 ```
 */
public struct Attribute: Equatable, Hashable {
    public let name: String
    public let type: Type
    public let accessLevel: AccessLevel
    public let isComputed: Bool
    public let hasGetter: Bool
    public let hasSetter: Bool

    public init(
        name: String,
        type: Type,
        accessLevel: AccessLevel = .internal,
        isComputed: Bool = false,
        hasGetter: Bool = true,
        hasSetter: Bool = true
    ) {
        self.name = name
        self.type = type
        self.accessLevel = accessLevel
        self.isComputed = isComputed
        self.hasGetter = hasGetter
        self.hasSetter = hasSetter
    }
}

/**
 Swift Project model based on Z notation:
 ```
 SwiftProject
 ├─ classes : ℙ Class
 ├─ protocols : ℙ Protocol
 ├─ extensions : ℙ Extension
 ├─ dependencies : Class ↔ Class
 └─ ∀ c₁, c₂ : classes • c₁ ≠ c₂ ⇒ c₁.name ≠ c₂.name
 ```
 */
public struct SwiftProject: Equatable {
    public let classes: Set<Class>
    public let protocols: Set<String> // Protocol names
    public let extensions: Set<String> // Extension targets
    public let dependencies: [Class: Set<Class>]

    public init(
        classes: Set<Class> = [],
        protocols: Set<String> = [],
        extensions: Set<String> = [],
        dependencies: [Class: Set<Class>] = [:]
    ) {
        // Validate unique class names
        let classNames = classes.map { $0.name }
        precondition(classNames.count == Set(classNames).count, "Class names must be unique")

        self.classes = classes
        self.protocols = protocols
        self.extensions = extensions
        self.dependencies = dependencies
    }

    // Helper methods
    public func getClass(byName name: String) -> Class? {
        classes.first { $0.name == name }
    }

    public func getDependencies(for class: Class) -> Set<Class> {
        dependencies[`class`] ?? []
    }
}