//
//  CyclicDependencyDetector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Detects Cyclic Dependencies based on Z notation specification
//

import Foundation
import SwiftSyntax

/// Detects Cyclic Dependency smell
/// Based on Z notation:
/// ```
/// CyclicDependencyDetector
/// ├─ dependencyGraph : Class ↔ Class
/// ├─ cycles : ℙ (seq Class)
/// ├─ hasCyclicDependency : Class → 𝔹
/// ├─ cyclicPartners : Class → ℙ Class
/// └─ Cycle ::= {path : seq Class | head(path) = last(path) ∧ ∀ i : 1..#path-1 • (path(i), path(i+1)) ∈ dependencyGraph}
/// ```
public final class CyclicDependencyDetector: BaseDefectDetector {

    private let thresholds: Thresholds

    public init(thresholds: Thresholds = .academic) {
        self.thresholds = thresholds
        super.init(detectableDefects: [.cyclicDependency])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        let dependencyVisitor = DependencyGraphVisitor()
        dependencyVisitor.walk(sourceFile)

        let graph = dependencyVisitor.buildDependencyGraph()

        // Find all cycles in the dependency graph
        let cycles = findCycles(in: graph)

        // Filter cycles that exceed the threshold length
        let significantCycles = cycles.filter { $0.count > thresholds.structuralSmells.cyclicDependencyLength }

        // Create defects for each class involved in significant cycles
        var reportedClasses = Set<String>()

        for cycle in significantCycles {
            for className in cycle {
                if !reportedClasses.contains(className) {
                    reportedClasses.insert(className)

                    let cycleDescription = cycle.joined(separator: " → ")
                    let defect = ArchitecturalDefect(
                        type: .cyclicDependency,
                        severity: calculateSeverity(for: cycle.count),
                        message: "Class '\(className)' is part of a cyclic dependency: \(cycleDescription)",
                        location: createLocation(filePath: filePath, context: "class \(className)"),
                        suggestion: "Break the circular dependency by introducing an interface, using dependency injection, or restructuring the classes"
                    )
                    defects.append(defect)
                }
            }
        }

        return defects
    }

    /// Finds all cycles in the dependency graph using DFS
    private func findCycles(in graph: DependencyGraph) -> [[String]] {
        var cycles: [[String]] = []
        var visited = Set<String>()
        var recStack = Set<String>()
        var path: [String] = []

        for node in graph.nodes {
            if !visited.contains(node) {
                dfs(node, graph: graph, visited: &visited, recStack: &recStack, path: &path, cycles: &cycles)
            }
        }

        return cycles
    }

    /// DFS helper for cycle detection
    private func dfs(_ node: String,
                     graph: DependencyGraph,
                     visited: inout Set<String>,
                     recStack: inout Set<String>,
                     path: inout [String],
                     cycles: inout [[String]]) {

        visited.insert(node)
        recStack.insert(node)
        path.append(node)

        for neighbor in graph.adjacencyList[node, default: []] {
            if !visited.contains(neighbor) {
                dfs(neighbor, graph: graph, visited: &visited, recStack: &recStack, path: &path, cycles: &cycles)
            } else if recStack.contains(neighbor) {
                // Found a cycle
                if let cycleStartIndex = path.firstIndex(of: neighbor) {
                    let cycle = Array(path[cycleStartIndex...])
                    cycles.append(cycle)
                }
            }
        }

        recStack.remove(node)
        path.removeLast()
    }

    /// Calculates severity based on cycle length
    private func calculateSeverity(for cycleLength: Int) -> Severity {
        switch cycleLength {
        case 2: return .medium
        case 3: return .high
        default: return .critical
        }
    }
}

// MARK: - Private Structures

private struct DependencyGraph {
    let nodes: Set<String>
    let adjacencyList: [String: [String]]

    init(nodes: Set<String>, adjacencyList: [String: [String]]) {
        self.nodes = nodes
        self.adjacencyList = adjacencyList
    }
}

// MARK: - Private Visitors

private class DependencyGraphVisitor: SyntaxVisitor {
    private var classes: [String: ClassInfo] = [:]
    private var dependencies: [(from: String, to: String)] = []

    struct ClassInfo {
        let name: String
        let attributes: [String]
        let methods: [String]
    }

    init() {
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let className = node.name.text
        var attributes: [String] = []
        var methods: [String] = []

        // Collect attributes and methods
        for member in node.memberBlock.members {
            if let variableDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in variableDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        attributes.append(identifier.identifier.text)
                    }
                }
            } else if let functionDecl = member.decl.as(FunctionDeclSyntax.self) {
                methods.append(functionDecl.name.text)
            }
        }

        classes[className] = ClassInfo(name: className, attributes: attributes, methods: methods)

        // Analyze inheritance dependencies
        if let inheritanceClause = node.inheritanceClause {
            for inheritedType in inheritanceClause.inheritedTypes {
                let inheritedTypeName = inheritedType.type.description.trimmingCharacters(in: .whitespaces)
                dependencies.append((from: className, to: inheritedTypeName))
            }
        }

        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let className = node.name.text
        var attributes: [String] = []

        // Collect attributes
        for member in node.memberBlock.members {
            if let variableDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in variableDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                        attributes.append(identifier.identifier.text)
                    }
                }
            }
        }

        classes[className] = ClassInfo(name: className, attributes: attributes, methods: [])

        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        // Find the containing class
        var currentNode: Syntax = node._syntaxNode
        var containingClass: String?

        while let parent = currentNode.parent {
            if let classDecl = parent.as(ClassDeclSyntax.self) {
                containingClass = classDecl.name.text
                break
            } else if let structDecl = parent.as(StructDeclSyntax.self) {
                containingClass = structDecl.name.text
                break
            }
            currentNode = parent
        }

        guard let className = containingClass,
              let body = node.body else { return .skipChildren }

        // Analyze method body for dependencies
        let methodVisitor = MethodDependencyVisitor(containingClass: className)
        methodVisitor.walk(body, classNames: Set(classes.keys))

        dependencies.append(contentsOf: methodVisitor.dependencies)

        return .skipChildren
    }

    func buildDependencyGraph() -> DependencyGraph {
        var adjacencyList: [String: [String]] = [:]

        for (from, to) in dependencies {
            // Only include dependencies between known classes
            if classes.keys.contains(from) && classes.keys.contains(to) {
                adjacencyList[from, default: []].append(to)
            }
        }

        return DependencyGraph(nodes: Set(classes.keys), adjacencyList: adjacencyList)
    }
}

private class MethodDependencyVisitor: SyntaxVisitor {
    let containingClass: String
    var dependencies: [(from: String, to: String)] = []
    private var currentClassNames: Set<String> = []

    init(containingClass: String) {
        self.containingClass = containingClass
        super.init(viewMode: .sourceAccurate)
    }

    func walk(_ node: some SyntaxProtocol, classNames: Set<String>) {
        self.currentClassNames = classNames
        super.walk(node)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        // Analyze function calls for dependencies
        if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
           let base = memberAccess.base,
           let baseExpr = base.as(DeclReferenceExprSyntax.self) {

            let baseName = baseExpr.baseName.text

            // Check if this is a call on another class instance
            if let targetClass = MethodDependencyVisitor.inferClassFromVariable(baseName, classNames: currentClassNames) {
                dependencies.append((from: containingClass, to: targetClass))
            }
        }

        return .visitChildren
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        // Analyze member access for attribute dependencies
        if let base = node.base,
           let baseExpr = base.as(DeclReferenceExprSyntax.self) {
            let baseName = baseExpr.baseName.text

            // Check if this is access to another class's attribute
            if let targetClass = MethodDependencyVisitor.inferClassFromVariable(baseName, classNames: currentClassNames) {
                dependencies.append((from: containingClass, to: targetClass))
            }
        }

        return .visitChildren
    }

    private static func inferClassFromVariable(_ variableName: String, classNames: Set<String>) -> String? {
        // Simplified inference - check if variable name matches a known class
        for className in classNames {
            if className.lowercased() == variableName.lowercased() ||
               className.lowercased() == variableName.dropFirst().lowercased() {
                return className
            }
        }

        // Check common naming patterns (e.g., "user" -> "User")
        let capitalized = variableName.prefix(1).uppercased() + variableName.dropFirst()
        if classNames.contains(capitalized) {
            return capitalized
        }

        return nil
    }
}