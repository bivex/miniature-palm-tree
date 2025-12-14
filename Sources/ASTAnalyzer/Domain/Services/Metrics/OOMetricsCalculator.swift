//
//  OOMetricsCalculator.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//  Object-Oriented metrics calculators based on Z notation specifications
//

import Foundation

// MARK: - Basic Metrics (from Z notation)

/**
 Basic quantitative metrics based on Z notation:
 ```
 BasicMetrics
 ├─ NOM : Class → ℕ                    -- Number of Methods
 ├─ NOF : Class → ℕ                    -- Number of Fields
 ├─ NOA : Class → ℕ                    -- Number of Attributes
 ├─ LOC : Class → ℕ                    -- Lines of Code
 ├─ NOI : Method → ℕ                   -- Number of Instructions
 ├─ NOP : Method → ℕ                   -- Number of Parameters
 └─ [with proper calculations]
 ```
 */
public struct BasicMetrics {
    public let nom: Int  // Number of Methods
    public let nof: Int  // Number of Fields
    public let noa: Int  // Number of Attributes
    public let loc: Int  // Lines of Code

    public init(for class: Class) {
        self.nom = `class`.methods.count
        self.nof = `class`.attributes.count
        self.noa = `class`.attributes.filter { !$0.isComputed }.count
        self.loc = `class`.loc
    }
}

public struct MethodMetrics {
    public let noi: Int  // Number of Instructions
    public let nop: Int  // Number of Parameters

    public init(for method: Method) {
        self.noi = method.instructions.count
        self.nop = method.parameters.count
    }
}

// MARK: - Weighted Methods per Class (WMC)

/**
 WMC Metric based on Z notation:
 ```
 WMC_Metric
 ├─ WMC : Class → ℕ
 └─ ∀ c : Class • WMC(c) = Σ{m : c.methods • m.cyclomaticComplexity}
 ```
 */
public struct WMC_Calculator {
    public static func calculate(for `class`: Class) -> Int {
        `class`.methods.reduce(0) { $0 + $1.cyclomaticComplexity }
    }
}

// MARK: - Lack of Cohesion of Methods (LCOM)

/**
 LCOM Metric based on Z notation:
 ```
 LCOM_Metric
 ├─ LCOM : Class → ℝ
 ├─ methodAttributeAccess : Method × Attribute → 𝔹
 └─ [LCOM4 and LCOM5 implementations]
 ```
 */
public struct LCOM_Calculator {

    /**
     LCOM4: Graph connectivity analysis
     ∀ c : Class •
       let M == c.methods
           A == c.attributes
           accessMatrix == {(m,a) : M × A | a ∈ m.accessedAttributes}
       in
         P = pairs without common attributes
         Q = pairs with common attributes
         LCOM(c) = max(0, #P - #Q)
     */
    public static func calculateLCOM4(for `class`: Class) -> Int {
        let methods = `class`.methods
        let attributes = `class`.attributes

        guard !methods.isEmpty && !attributes.isEmpty else { return 0 }

        // Count method pairs without common attributes (P)
        // Count method pairs with common attributes (Q)
        var pairsWithoutCommon = 0
        var pairsWithCommon = 0

        let methodArray = Array(methods)
        for i in 0..<methodArray.count {
            for j in (i+1)..<methodArray.count {
                let method1 = methodArray[i]
                let method2 = methodArray[j]

                let commonAttributes = method1.accessedAttributes.intersection(method2.accessedAttributes)
                if commonAttributes.isEmpty {
                    pairsWithoutCommon += 1
                } else {
                    pairsWithCommon += 1
                }
            }
        }

        return max(0, pairsWithoutCommon - pairsWithCommon)
    }

    /**
     LCOM5: Normalized cohesion metric (0..1)
     ∀ c : Class •
       let m == #(c.methods)
           a == #(c.attributes)
           sumAccess == Σ{attr : c.attributes • #{meth : c.methods | attr ∈ meth.accessedAttributes}}
       in
         a = 0 ∨ m ≤ 1 ⇒ LCOM5(c) = 0
         a > 0 ∧ m > 1 ⇒ LCOM5(c) = (m - sumAccess/a) / (m - 1)
     */
    public static func calculateLCOM5(for `class`: Class) -> Double {
        let m = Double(`class`.methods.count)
        let a = Double(`class`.attributes.count)

        guard a > 0 && m > 1 else { return 0.0 }

        // Calculate sum of access counts for each attribute
        let sumAccess = `class`.attributes.reduce(0.0) { total, attribute in
            let accessCount = Double(`class`.methods.filter { $0.accessedAttributes.contains(attribute) }.count)
            return total + accessCount
        }

        let lcom5 = (m - sumAccess / a) / (m - 1)
        return max(0.0, min(1.0, lcom5)) // Clamp to [0, 1]
    }
}

// MARK: - Coupling Between Objects (CBO)

/**
 CBO Metric based on Z notation:
 ```
 CBO_Metric
 ├─ CBO : Class → ℕ
 ├─ uses : Class ↔ Class
 └─ ∀ c : Class • CBO(c) = #{c' : Class | (c,c') ∈ uses ∨ (c',c) ∈ uses}
 ```
 */
public struct CBO_Calculator {
    public static func calculate(for `class`: Class, in project: SwiftProject) -> Int {
        var coupledClasses = Set<Class>()

        // Direct dependencies from this class
        if let dependencies = project.dependencies[`class`] {
            coupledClasses.formUnion(dependencies)
        }

        // Reverse dependencies (classes that use this class)
        for (otherClass, deps) in project.dependencies {
            if deps.contains(`class`) {
                coupledClasses.insert(otherClass)
            }
        }

        // Additional coupling through method calls and attribute types
        for method in `class`.methods {
            // Coupling through method calls
            for calledMethod in method.calledMethods {
                // Find which class contains the called method
                if let containingClass = project.classes.first(where: { $0.methods.contains(calledMethod) }) {
                    coupledClasses.insert(containingClass)
                }
            }

            // Coupling through parameter types
            for param in method.parameters {
                if let typeClass = project.getClass(byName: param.type.name) {
                    coupledClasses.insert(typeClass)
                }
            }

            // Coupling through return type
            if let returnType = method.returnType,
               let typeClass = project.getClass(byName: returnType.name) {
                coupledClasses.insert(typeClass)
            }
        }

        // Coupling through attribute types
        for attribute in `class`.attributes {
            if let typeClass = project.getClass(byName: attribute.type.name) {
                coupledClasses.insert(typeClass)
            }
        }

        // Remove self-coupling
        coupledClasses.remove(`class`)

        return coupledClasses.count
    }
}

// MARK: - Depth of Inheritance Tree (DIT)

/**
 DIT Metric based on Z notation:
 ```
 DIT_Metric
 ├─ DIT : Class → ℕ
 └─ ∀ c : Class •
     c.parentName = ∅ ⇒ DIT(c) = 0
     c.parentName ≠ ∅ ⇒ DIT(c) = 1 + DIT(c.parent)
 ```
 */
public struct DIT_Calculator {
    public static func calculate(for `class`: Class, in project: SwiftProject) -> Int {
        var depth = 0
        var currentParentName = `class`.parentName

        while let parentName = currentParentName {
            depth += 1
            // Look up parent class in project
            let parentClass = project.classes.first { $0.name == parentName }
            currentParentName = parentClass?.parentName
        }

        return depth
    }
}

// MARK: - Tight Class Cohesion (TCC)

/**
 TCC Metric based on Z notation:
 ```
 TCC_Metric
 ├─ TCC : Class → ℝ
 ├─ directlyConnected : Method × Method → 𝔹
 └─ [calculates ratio of connected method pairs]
 ```
 */
public struct TCC_Calculator {
    public static func calculate(for `class`: Class) -> Double {
        // Only consider visible (public/open/internal) methods
        let visibleMethods = `class`.methods.filter { method in
            [.public, .open, .internal].contains(method.accessLevel)
        }

        let n = visibleMethods.count
        guard n > 1 else { return 1.0 }

        let maxPairs = n * (n - 1) / 2
        var connectedPairs = 0

        let methodArray = Array(visibleMethods)
        for i in 0..<methodArray.count {
            for j in (i+1)..<methodArray.count {
                let method1 = methodArray[i]
                let method2 = methodArray[j]

                // Methods are connected if they access common attributes
                if !method1.accessedAttributes.intersection(method2.accessedAttributes).isEmpty {
                    connectedPairs += 1
                }
            }
        }

        return Double(connectedPairs) / Double(maxPairs)
    }
}

// MARK: - Access to Foreign Data (ATFD)

/**
 ATFD Metric based on Z notation:
 ```
 ATFD_Metric
 ├─ ATFD : Class → ℕ
 └─ ∀ c : Class • ATFD(c) = #{a : Attribute |
     a ∉ c.attributes ∧ ∃ m : c.methods • a ∈ m.foreignDataAccess}
 ```
 */
public struct ATFD_Calculator {
    public static func calculate(for `class`: Class) -> Int {
        var foreignAttributes = Set<Attribute>()

        for method in `class`.methods {
            foreignAttributes.formUnion(method.foreignDataAccess)
        }

        // Remove any attributes that belong to this class
        foreignAttributes.subtract(`class`.attributes)

        return foreignAttributes.count
    }
}

// MARK: - Weight of class that is Accessible (WOA)

/**
 WOA Metric based on Z notation:
 ```
 WOA_Metric
 ├─ WOA : Class → ℝ
 └─ ∀ c : Class •
     let publicMembers == #{m : c.methods | m.accessLevel ∈ {public, open}} +
                          #{a : c.attributes | a.accessLevel ∈ {public, open}}
         totalMembers == #(c.methods) + #(c.attributes)
     in
       totalMembers = 0 ⇒ WOA(c) = 0
       totalMembers > 0 ⇒ WOA(c) = publicMembers / totalMembers
 ```
 */
public struct WOA_Calculator {
    public static func calculate(for `class`: Class) -> Double {
        let publicMethods = `class`.methods.filter { [.public, .open].contains($0.accessLevel) }.count
        let publicAttributes = `class`.attributes.filter { [.public, .open].contains($0.accessLevel) }.count

        let publicMembers = publicMethods + publicAttributes
        let totalMembers = `class`.methods.count + `class`.attributes.count

        guard totalMembers > 0 else { return 0.0 }

        return Double(publicMembers) / Double(totalMembers)
    }
}

// MARK: - Composite Metrics Calculator

/// Convenience calculator that computes all metrics for a class
public struct OOMetricsCalculator {
    public let basic: BasicMetrics
    public let wmc: Int
    public let lcom4: Int
    public let lcom5: Double
    public let cbo: Int
    public let dit: Int
    public let tcc: Double
    public let atfd: Int
    public let woa: Double

    public init(for `class`: Class, in project: SwiftProject) {
        self.basic = BasicMetrics(for: `class`)
        self.wmc = WMC_Calculator.calculate(for: `class`)
        self.lcom4 = LCOM_Calculator.calculateLCOM4(for: `class`)
        self.lcom5 = LCOM_Calculator.calculateLCOM5(for: `class`)
        self.cbo = CBO_Calculator.calculate(for: `class`, in: project)
        self.dit = DIT_Calculator.calculate(for: `class`, in: project)
        self.tcc = TCC_Calculator.calculate(for: `class`)
        self.atfd = ATFD_Calculator.calculate(for: `class`)
        self.woa = WOA_Calculator.calculate(for: `class`)
    }
}