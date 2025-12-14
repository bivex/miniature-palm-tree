//
//  Thresholds.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Academic threshold values from Z notation specifications
//

import Foundation
import Yams

/**
 Thresholds configuration based on Z notation:
 ```
 Thresholds
 ├─ godClassThresholds : GodClassThresholds
 ├─ multifacetedAbstractionThresholds : MultifacetedAbstractionThresholds
 ├─ deficientEncapsulationThresholds : DeficientEncapsulationThresholds
 ├─ longMethodThresholds : LongMethodThresholds
 ├─ lazyClassThresholds : LazyClassThresholds
 ├─ messageChainThresholds : MessageChainThresholds
 ├─ brokenHierarchyThresholds : BrokenHierarchyThresholds
 └─ cyclicDependencyThresholds : CyclicDependencyThresholds
 ```
 */
/// Thresholds for class-level code smells
public struct ClassSmellThresholds: Sendable, Codable {
    public let godClassWMC: Int
    public let godClassTCC: Double
    public let godClassATFD: Int
    public let godClassLOC: Int
    public let mfaLCOM: Double
    public let mfaWMC: Int
    public let mfaNOF: Int
    public let mfaNOM: Int
    public let deficientEncapsulationWOA: Double
    public let lazyClassNOM: Int
    public let lazyClassNOF: Int
    public let lazyClassDIT: Int

    private enum CodingKeys: String, CodingKey {
        case godClassWMC = "god_class_wmc"
        case godClassTCC = "god_class_tcc"
        case godClassATFD = "god_class_atfd"
        case godClassLOC = "god_class_loc"
        case mfaLCOM = "mfa_lcom"
        case mfaWMC = "mfa_wmc"
        case mfaNOF = "mfa_nof"
        case mfaNOM = "mfa_nom"
        case deficientEncapsulationWOA = "deficient_encapsulation_woa"
        case lazyClassNOM = "lazy_class_nom"
        case lazyClassNOF = "lazy_class_nof"
        case lazyClassDIT = "lazy_class_dit"
    }

    public init(
        godClassWMC: Int = 47,
        godClassTCC: Double = 0.33,
        godClassATFD: Int = 5,
        godClassLOC: Int = 500,
        mfaLCOM: Double = 0.725,
        mfaWMC: Int = 34,
        mfaNOF: Int = 8,
        mfaNOM: Int = 14,
        deficientEncapsulationWOA: Double = 0.3,
        lazyClassNOM: Int = 5,
        lazyClassNOF: Int = 5,
        lazyClassDIT: Int = 2
    ) {
        self.godClassWMC = godClassWMC
        self.godClassTCC = godClassTCC
        self.godClassATFD = godClassATFD
        self.godClassLOC = godClassLOC
        self.mfaLCOM = mfaLCOM
        self.mfaWMC = mfaWMC
        self.mfaNOF = mfaNOF
        self.mfaNOM = mfaNOM
        self.deficientEncapsulationWOA = deficientEncapsulationWOA
        self.lazyClassNOM = lazyClassNOM
        self.lazyClassNOF = lazyClassNOF
        self.lazyClassDIT = lazyClassDIT
    }

    /// Check if class metrics indicate various code smells
    public func checkSmells(wmc: Int, tcc: Double, atfd: Int, lcom5: Double, nof: Int, nom: Int, woa: Double, dit: Int) -> [String: Bool] {
        [
            "godClass": atfd > godClassATFD && wmc >= godClassWMC && tcc < godClassTCC,
            "multifacetedAbstraction": lcom5 > mfaLCOM && (wmc >= mfaWMC || nof >= mfaNOF || nom >= mfaNOM),
            "deficientEncapsulation": woa > deficientEncapsulationWOA,
            "lazyClass": (nom < lazyClassNOM && nof < lazyClassNOF) || (dit > 0 && dit < lazyClassDIT && nom < lazyClassNOM)
        ]
    }
}

/// Thresholds for method-level code smells
public struct MethodSmellThresholds: Sendable, Codable {
    public let longMethodLOC: Int
    public let longMethodCC: Int
    public let longMethodNOI: Int

    private enum CodingKeys: String, CodingKey {
        case longMethodLOC = "long_method_loc"
        case longMethodCC = "long_method_cc"
        case longMethodNOI = "long_method_noi"
    }

    public init(longMethodLOC: Int = 50, longMethodCC: Int = 10, longMethodNOI: Int = 30) {
        self.longMethodLOC = longMethodLOC
        self.longMethodCC = longMethodCC
        self.longMethodNOI = longMethodNOI
    }

    /// Check if method metrics indicate Long Method smell
    public func checkSmells(loc: Int, complexity: Int, noi: Int) -> [String: Bool] {
        ["longMethod": loc > longMethodLOC || noi > longMethodNOI || complexity > longMethodCC]
    }
}

/// Thresholds for structural code smells
public struct StructuralSmellThresholds: Sendable, Codable {
    public let messageChainLength: Int
    public let brokenHierarchyDIT: Int
    public let cyclicDependencyLength: Int
    public let featureEnvyThreshold: Int

    private enum CodingKeys: String, CodingKey {
        case messageChainLength = "message_chain_length"
        case brokenHierarchyDIT = "broken_hierarchy_dit"
        case cyclicDependencyLength = "cyclic_dependency_length"
        case featureEnvyThreshold = "feature_envy_threshold"
    }

    public init(messageChainLength: Int = 3, brokenHierarchyDIT: Int = 3, cyclicDependencyLength: Int = 2, featureEnvyThreshold: Int = 3) {
        self.messageChainLength = messageChainLength
        self.brokenHierarchyDIT = brokenHierarchyDIT
        self.cyclicDependencyLength = cyclicDependencyLength
        self.featureEnvyThreshold = featureEnvyThreshold
    }
}

public struct Thresholds: Sendable {

    // MARK: - Composed Threshold Groups
    public let classSmells: ClassSmellThresholds
    public let methodSmells: MethodSmellThresholds
    public let structuralSmells: StructuralSmellThresholds

    // MARK: - Cohesive Methods

    /// Check if class metrics indicate various code smells
    public func checkClassSmells(wmc: Int, tcc: Double, atfd: Int, lcom5: Double, nof: Int, nom: Int, woa: Double, dit: Int) -> [String: Bool] {
        classSmells.checkSmells(wmc: wmc, tcc: tcc, atfd: atfd, lcom5: lcom5, nof: nof, nom: nom, woa: woa, dit: dit)
    }

    /// Check if method metrics indicate Long Method smell
    public func checkMethodSmells(loc: Int, complexity: Int, noi: Int) -> [String: Bool] {
        methodSmells.checkSmells(loc: loc, complexity: complexity, noi: noi)
    }




    // MARK: - Initialization

    /// Default academic thresholds from Lanza & Marinescu, Habchi et al., and SwiftLint
    public static let academic = Thresholds(
        classSmells: ClassSmellThresholds(
            godClassWMC: 47,
            godClassTCC: 0.33,
            godClassATFD: 5,
            godClassLOC: 500,
            mfaLCOM: 0.725,
            mfaWMC: 34,
            mfaNOF: 8,
            mfaNOM: 14,
            deficientEncapsulationWOA: 0.3,
            lazyClassNOM: 5,
            lazyClassNOF: 5,
            lazyClassDIT: 2
        ),
        methodSmells: MethodSmellThresholds(
            longMethodLOC: 50,
            longMethodCC: 10,
            longMethodNOI: 30
        ),
        structuralSmells: StructuralSmellThresholds(
            messageChainLength: 5,
            brokenHierarchyDIT: 3,
            cyclicDependencyLength: 2,
            featureEnvyThreshold: 3
        )
    )

    /// Lenient thresholds for less strict analysis
    public static let lenient = Thresholds(
        classSmells: ClassSmellThresholds(
            godClassWMC: 60,
            godClassTCC: 0.25,
            godClassATFD: 7,
            godClassLOC: 750,
            mfaLCOM: 0.8,
            mfaWMC: 40,
            mfaNOF: 10,
            mfaNOM: 16,
            deficientEncapsulationWOA: 0.4,
            lazyClassNOM: 3,
            lazyClassNOF: 3,
            lazyClassDIT: 1
        ),
        methodSmells: MethodSmellThresholds(
            longMethodLOC: 75,
            longMethodCC: 15,
            longMethodNOI: 40
        ),
        structuralSmells: StructuralSmellThresholds(
            messageChainLength: 4,
            brokenHierarchyDIT: 4,
            cyclicDependencyLength: 3,
            featureEnvyThreshold: 4
        )
    )

    /// Strict thresholds for more aggressive defect detection
    public static let strict = Thresholds(
        classSmells: ClassSmellThresholds(
            godClassWMC: 35,
            godClassTCC: 0.4,
            godClassATFD: 3,
            godClassLOC: 400,
            mfaLCOM: 0.6,
            mfaWMC: 25,
            mfaNOF: 6,
            mfaNOM: 12,
            deficientEncapsulationWOA: 0.2,
            lazyClassNOM: 7,
            lazyClassNOF: 7,
            lazyClassDIT: 3
        ),
        methodSmells: MethodSmellThresholds(
            longMethodLOC: 40,
            longMethodCC: 8,
            longMethodNOI: 25
        ),
        structuralSmells: StructuralSmellThresholds(
            messageChainLength: 2,
            brokenHierarchyDIT: 2,
            cyclicDependencyLength: 1,
            featureEnvyThreshold: 2
        )
    )

    public init(
        classSmells: ClassSmellThresholds = .init(),
        methodSmells: MethodSmellThresholds = .init(),
        structuralSmells: StructuralSmellThresholds = .init()
    ) {
        self.classSmells = classSmells
        self.methodSmells = methodSmells
        self.structuralSmells = structuralSmells
    }

    // Legacy initializer for backward compatibility
    public init(
        θ_WMC_GodClass: Int = 47,
        θ_TCC_GodClass: Double = 0.33,
        θ_ATFD_GodClass: Int = 5,
        θ_LOC_GodClass: Int = 500,
        θ_LCOM_MFA: Double = 0.725,
        θ_WMC_MFA: Int = 34,
        θ_NOF_MFA: Int = 8,
        θ_NOM_MFA: Int = 14,
        θ_WOA_DE: Double = 0.3,
        θ_LOC_LongMethod: Int = 50,
        θ_CC_LongMethod: Int = 10,
        θ_NOI_LongMethod: Int = 30,
        θ_NOM_LazyClass: Int = 5,
        θ_NOF_LazyClass: Int = 5,
        θ_DIT_LazyClass: Int = 2,
        θ_ChainLength: Int = 3,
        θ_DIT_BrokenHierarchy: Int = 3,
        θ_CycleLength: Int = 2,
        θ_FeatureEnvyThreshold: Int = 3
    ) {
        self.init(
            classSmells: ClassSmellThresholds(
                godClassWMC: θ_WMC_GodClass,
                godClassTCC: θ_TCC_GodClass,
                godClassATFD: θ_ATFD_GodClass,
                godClassLOC: θ_LOC_GodClass,
                mfaLCOM: θ_LCOM_MFA,
                mfaWMC: θ_WMC_MFA,
                mfaNOF: θ_NOF_MFA,
                mfaNOM: θ_NOM_MFA,
                deficientEncapsulationWOA: θ_WOA_DE,
                lazyClassNOM: θ_NOM_LazyClass,
                lazyClassNOF: θ_NOF_LazyClass,
                lazyClassDIT: θ_DIT_LazyClass
            ),
            methodSmells: MethodSmellThresholds(
                longMethodLOC: θ_LOC_LongMethod,
                longMethodCC: θ_CC_LongMethod,
                longMethodNOI: θ_NOI_LongMethod
            ),
            structuralSmells: StructuralSmellThresholds(
                messageChainLength: θ_ChainLength,
                brokenHierarchyDIT: θ_DIT_BrokenHierarchy,
                cyclicDependencyLength: θ_CycleLength,
                featureEnvyThreshold: θ_FeatureEnvyThreshold
            )
        )
    }

    // MARK: - Convenience Methods

    /// Creates thresholds from a JSON configuration
    public static func fromJSON(_ jsonData: Data) throws -> Thresholds {
        let decoder = JSONDecoder()
        return try decoder.decode(Thresholds.self, from: jsonData)
    }

    /// Exports thresholds to JSON
    public func toJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(self)
    }

    /// Creates thresholds from a YAML configuration
    public static func fromYAML(_ yamlString: String) throws -> Thresholds {
        return try YAMLDecoder().decode(Thresholds.self, from: yamlString)
    }

    /// Creates thresholds from a YAML file
    public static func fromYAMLFile(at path: String) throws -> Thresholds {
        let content = try String(contentsOfFile: path, encoding: .utf8)
        return try fromYAML(content)
    }

    /// Exports thresholds to YAML
    public func toYAML() throws -> String {
        return try YAMLEncoder().encode(self)
    }
}

// MARK: - Codable Support

extension Thresholds: Codable {
    private enum CodingKeys: String, CodingKey {
        case classSmells = "class_smells"
        case methodSmells = "method_smells"
        case structuralSmells = "structural_smells"
    }
}

// MARK: - Threshold Validation

