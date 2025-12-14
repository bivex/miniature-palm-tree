//
//  MissingAbstractionDetector.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//
//

import Foundation
import SwiftSyntax

/// Detects missing abstraction (too many unencapsulated elements) (Missing Abstraction)
/// Based on DMA (Missing Abstraction):
/// - Unencapsulated elements in module > threshold
public final class MissingAbstractionDetector: BaseDefectDetector {

    private let thresholds: Thresholds

    public init(thresholds: Thresholds = .academic) {
        self.thresholds = thresholds
        super.init(detectableDefects: [.missingAbstraction])
    }

    public override func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [ArchitecturalDefect] {
        var defects: [ArchitecturalDefect] = []

        let unencapsulatedElements = countUnencapsulatedElements(in: sourceFile)

        if unencapsulatedElements.count > thresholds.moduleSmells.missingAbstractionMaxElements {
            let elementTypes = unencapsulatedElements.map { $0.type }.joined(separator: ", ")
            let defect = ArchitecturalDefect(
                type: .missingAbstraction,
                severity: .medium,
                message: "File contains \(unencapsulatedElements.count) unencapsulated elements (\(elementTypes)) - exceeds maximum of \(thresholds.moduleSmells.missingAbstractionMaxElements)",
                location: createLocation(filePath: filePath),
                suggestion: "Encapsulate global elements in appropriate types or consider using access control modifiers"
            )
            defects.append(defect)
        }

        return defects
    }

    private func countUnencapsulatedElements(in sourceFile: SourceFileSyntax) -> [(name: String, type: String)] {
        var elements: [(String, String)] = []

        for statement in sourceFile.statements {
            if let decl = statement.item.as(DeclSyntax.self) {
                // Check for global variable declarations
                if let varDecl = decl.as(VariableDeclSyntax.self) {
                    if !isInsideTypeDeclaration(varDecl) {
                        let names = varDecl.bindings.compactMap { binding -> String? in
                            if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                                return identifier.identifier.text
                            }
                            return nil
                        }
                        elements.append(contentsOf: names.map { ($0, "variable") })
                    }
                }
                // Check for global function declarations
                else if let funcDecl = decl.as(FunctionDeclSyntax.self) {
                    if !isInsideTypeDeclaration(funcDecl) {
                        elements.append((funcDecl.name.text, "function"))
                    }
                }
                // Check for global typealias declarations
                else if let typealiasDecl = decl.as(TypeAliasDeclSyntax.self) {
                    if !isInsideTypeDeclaration(typealiasDecl) {
                        elements.append((typealiasDecl.name.text, "typealias"))
                    }
                }
            }
        }

        return elements
    }

    private func isInsideTypeDeclaration(_ decl: some SyntaxProtocol) -> Bool {
        var current: Syntax? = decl.parent

        while let parent = current {
            if parent.is(ClassDeclSyntax.self) ||
               parent.is(StructDeclSyntax.self) ||
               parent.is(EnumDeclSyntax.self) ||
               parent.is(ActorDeclSyntax.self) ||
               parent.is(ProtocolDeclSyntax.self) ||
               parent.is(ExtensionDeclSyntax.self) {
                return true
            }

            // Also check if it's inside a function (local scope)
            if parent.is(FunctionDeclSyntax.self) ||
               parent.is(InitializerDeclSyntax.self) ||
               parent.is(DeinitializerDeclSyntax.self) {
                return true
            }

            current = parent.parent
        }

        return false
    }
}