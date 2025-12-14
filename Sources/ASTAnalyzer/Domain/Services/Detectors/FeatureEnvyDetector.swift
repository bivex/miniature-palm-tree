//
//  FeatureEnvyDetector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Detects Feature Envy code smell based on Z notation specification
//

import Foundation
import SwiftSyntax

/// Detects Feature Envy smell
/// Based on Z notation:
/// ```
/// FeatureEnvyDetector
/// ├─ hasFeatureEnvy : Method → 𝔹
/// ├─ enviedClass : Method → Class ∪ {∅}
/// ├─ localAccess : Method → ℕ
/// ├─ foreignAccess : Method × Class → ℕ
/// └─ ∀ m : Method • hasFeatureEnvy(m) ⇔ ∃ c' : Class • foreignAccess(m, c') > localAccess(m) ∧ foreignAccess(m, c') > 3
/// ```
public final class FeatureEnvyDetector: BaseDefectDetector {

    private let thresholds: Thresholds

    public init(thresholds: Thresholds = .academic) {
        self.thresholds = thresholds
        super.init(detectableDefects: [.featureEnvy])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        let visitor = FeatureEnvyVisitor()
        visitor.walk(sourceFile)

        // Analyze each method for feature envy
        for method in visitor.methods {
            let analysis = analyzeMethodAccess(method, allClasses: visitor.classes)

            if let defect = analysis.createDefect(for: method, filePath: filePath) {
                defects.append(defect)
            }
        }

        return defects
    }

    /// Analyzes a method's attribute access patterns
    private func analyzeMethodAccess(_ method: VisitorMethodInfo, allClasses: [ClassInfo]) -> AccessAnalysis {
        guard let body = method.node.body else {
            return AccessAnalysis(localAccess: 0, foreignAccess: [:], hasFeatureEnvy: false, enviedClass: nil)
        }

        let visitor = AttributeAccessVisitor(className: method.className, allClasses: allClasses)
        visitor.walk(body)

        let localAccess = visitor.localAttributeAccess.count
        let foreignAccess = visitor.foreignAttributeAccess

        // Find the class with maximum foreign access
        let maxForeignAccess = foreignAccess.values.max() ?? 0
        let enviedClass = foreignAccess.first { $0.value == maxForeignAccess }?.key

        let hasFeatureEnvy = maxForeignAccess > localAccess && maxForeignAccess > thresholds.structuralSmells.featureEnvyThreshold

        return AccessAnalysis(
            localAccess: localAccess,
            foreignAccess: foreignAccess,
            hasFeatureEnvy: hasFeatureEnvy,
            enviedClass: enviedClass
        )
    }
}

// MARK: - Private Structures


private struct AccessAnalysis {
    let localAccess: Int
    let foreignAccess: [String: Int] // className -> accessCount
    let hasFeatureEnvy: Bool
    let enviedClass: String?
    let maxForeignAccess: Int

    init(localAccess: Int, foreignAccess: [String: Int], hasFeatureEnvy: Bool, enviedClass: String?) {
        self.localAccess = localAccess
        self.foreignAccess = foreignAccess
        self.hasFeatureEnvy = hasFeatureEnvy
        self.enviedClass = enviedClass
        self.maxForeignAccess = foreignAccess.values.max() ?? 0
    }

    /// Creates an architectural defect if feature envy is detected
    func createDefect(for method: VisitorMethodInfo, filePath: String) -> ArchitecturalDefect? {
        guard hasFeatureEnvy else { return nil }

        let enviedClassName = enviedClass ?? "unknown"
        return ArchitecturalDefect(
            type: .featureEnvy,
            severity: .high,
            message: "Method '\(method.name)' in class '\(method.className)' exhibits feature envy towards '\(enviedClassName)' (local access: \(localAccess), foreign access: \(maxForeignAccess))",
            location: Location(filePath: filePath, lineNumber: nil, columnNumber: nil, context: "\(method.className).\(method.name)"),
            suggestion: "Consider moving this method to class '\(enviedClassName)' or extracting the envied functionality"
        )
    }
}

// MARK: - Private Visitors

private class FeatureEnvyVisitor: SyntaxVisitor {
    private let stateHandler: FeatureEnvyStateHandler

    var methods: [VisitorMethodInfo] { stateHandler.methodsResult }
    var classes: [ClassInfo] { stateHandler.classesResult }

    init(stateHandler: FeatureEnvyStateHandler = DefaultFeatureEnvyStateHandler()) {
        self.stateHandler = stateHandler
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let className = node.name.text
        var attributes: [String] = []

        // Collect attributes from this class
        for member in node.memberBlock.members {
            if let variableDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in variableDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        attributes.append(identifier.identifier.text)
                    }
                }
            }
        }

        stateHandler.recordClass(name: className, attributes: attributes)

        // Continue visiting to find methods
        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let className = node.name.text
        var attributes: [String] = []

        // Collect attributes from this struct
        for member in node.memberBlock.members {
            if let variableDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in variableDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        attributes.append(identifier.identifier.text)
                    }
                }
            }
        }

        stateHandler.recordClass(name: className, attributes: attributes)

        // Continue visiting to find methods
        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        // Find the containing class/struct
        var currentNode: Syntax = node._syntaxNode
        var className = "Global"

        while let parent = currentNode.parent {
            if let classDecl = parent.as(ClassDeclSyntax.self) {
                className = classDecl.name.text
                break
            } else if let structDecl = parent.as(StructDeclSyntax.self) {
                className = structDecl.name.text
                break
            }
            currentNode = parent
        }

        let methodName = node.name.text
        stateHandler.recordMethod(className: className, name: methodName, node: node)

        return .skipChildren
    }
}

private class AttributeAccessVisitor: SyntaxVisitor {
    let className: String
    let allClasses: [ClassInfo]

    var localAttributeAccess: Set<String> = []
    var foreignAttributeAccess: [String: Int] = [:]

    // Track variable declarations and their types within the method
    private var variableDeclarations: [String: String] = [:]

    init(className: String, allClasses: [ClassInfo]) {
        self.className = className
        self.allClasses = allClasses
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        // Track variable declarations and their types
        for binding in node.bindings {
            if let typeAnnotation = binding.typeAnnotation {
                let typeName = typeAnnotation.type.description.trimmingCharacters(in: CharacterSet.whitespaces)
                if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                    let varName = identifier.identifier.text
                    variableDeclarations[varName] = typeName
                }
            }
        }
        return .visitChildren
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        // Check if this is attribute access (e.g., self.property or object.property)
        if let base = node.base,
           let baseExpr = base.as(DeclReferenceExprSyntax.self),
           baseExpr.baseName.text == "self" {
            // Local attribute access
            localAttributeAccess.insert(node.declName.baseName.text)
        } else if let base = node.base,
                  let baseExpr = base.as(DeclReferenceExprSyntax.self) {
            // Potential foreign attribute access
            let baseName = baseExpr.baseName.text

            // Only count access to user-defined classes, not built-in types
            if isUserDefinedClassInstance(baseName) {
                let inferredClassName = inferClassName(for: baseName)
                if inferredClassName != self.className {
                    foreignAttributeAccess[inferredClassName, default: 0] += 1
                }
            }
        }

        return .visitChildren
    }

    private func isUserDefinedClassInstance(_ name: String) -> Bool {
        // Skip common keywords
        let keywords = ["self", "super", "true", "false", "nil"]
        if keywords.contains(name) {
            return false
        }

        // Check if this variable was declared in the method and is a built-in type
        if let declaredType = variableDeclarations[name] {
            let builtInTypes = ["String", "Int", "Double", "Float", "Bool", "Array", "Dictionary", "Set", "Optional"]
            if builtInTypes.contains(where: { declaredType.contains($0) }) {
                return false
            }
        }

        // Check if the name corresponds to a known class
        let capitalized = name.prefix(1).uppercased() + name.dropFirst()
        return allClasses.contains { $0.name.lowercased() == name.lowercased() ||
                                   $0.name.lowercased() == capitalized.lowercased() }
    }

    private func inferClassName(for variableName: String) -> String {
        // First check if we have a declared type for this variable
        if let declaredType = variableDeclarations[variableName] {
            // Extract the base type name (remove generics, optionals, etc.)
            let cleanedType = declaredType.replacingOccurrences(of: "?", with: "")
                .replacingOccurrences(of: "!", with: "")
            let components = cleanedType.components(separatedBy: CharacterSet(charactersIn: "<["))
            let baseType = components.first ?? declaredType
            return baseType.trimmingCharacters(in: .whitespaces)
        }

        // Fallback to heuristic-based inference
        let capitalized = variableName.prefix(1).uppercased() + variableName.dropFirst()

        // Check if any class name matches or is similar
        for classInfo in allClasses {
            if classInfo.name.lowercased() == variableName.lowercased() ||
               classInfo.name.lowercased() == capitalized.lowercased() {
                return classInfo.name
            }
        }

        // If no match found, assume it's a class instance with the capitalized name
        return capitalized
    }
}