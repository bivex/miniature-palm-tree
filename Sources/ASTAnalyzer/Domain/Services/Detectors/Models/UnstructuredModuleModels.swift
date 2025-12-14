//
//  UnstructuredModuleModels.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Models for Unstructured Module detection
//

import Foundation

/// Analysis result for file structure
public struct StructureAnalysis {
    var hasClasses = false
    var hasStructs = false
    var hasEnums = false
    var hasProtocols = false
    var hasActors = false
    var hasExtensions = false
    var hasGlobalFunctions = false
    var hasGlobalVariables = false

    var layers: Set<String> = []

    var hasMixedLayers: Bool {
        return layers.count > 2 // More than 2 layers indicate mixing
    }
}