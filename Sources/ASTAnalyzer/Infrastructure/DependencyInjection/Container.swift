//
//  Container.swift
//  ASTAnalyzer
//
//  Created on 2025-01-14.
//

import Foundation

/// Dependency injection container for the application
public final class Container {

    private var services: [String: Any] = [:]
    private let configuration: AppConfiguration

    public init(configuration: AppConfiguration = .default) {
        self.configuration = configuration
        registerDependencies()
    }

    // MARK: - Service Registration

    private func registerDependencies() {
        // Infrastructure
        register(FileReader.self) { _ in FileSystemReader() }
        register(SyntaxParser.self) { _ in SwiftSyntaxParser() }
        register(JSONExporter.self) { _ in JSONExporter() }
        register(MarkdownExporter.self) { _ in MarkdownExporter() }
        register(FileSystemService.self) { _ in FileSystemService() }

        // Domain Services
        register(AnalysisCoordinator.self) { container in
            let detectors: [DefectDetector] = [
                // Updated detectors based on  et al. (MSR 2016) design configuration smells
                MultifacetedAbstractionDetector(),              // DMF - Multifaceted Abstraction
                InsufficientModularizationDetector(),           // DIM - Insufficient Modularization
                UnnecessaryAbstractionDetector(),               // DUA - Unnecessary Abstraction
                ImperativeAbstractionDetector(),                // DIA - Imperative Abstraction
                MissingAbstractionDetector(),                   // DMA - Missing Abstraction
                DuplicateBlockDetector(),                       // DDB - Duplicate Block
                BrokenHierarchyDetector(),                      // DBH - Broken Hierarchy
                UnstructuredModuleDetector(),                   // DUM - Unstructured Module
                DenseStructureDetector(),                       // DDS - Dense Structure
                DeficientEncapsulationDetector(),               // DDE - Deficient Encapsulation
                WeakenedModularityDetector()                    // DWM - Weakened Modularity
            ]
            return AnalysisCoordinator(defectDetectors: detectors)
        }

        // Application Services
        register(AnalyzeFileUseCase.self) { container in
            AnalyzeFileUseCase(
                fileReader: container.resolve(FileReader.self),
                syntaxParser: container.resolve(SyntaxParser.self),
                analysisCoordinator: container.resolve(AnalysisCoordinator.self)
            )
        }

        register(AnalyzeDirectoryUseCase.self) { container in
            AnalyzeDirectoryUseCase(
                fileReader: container.resolve(FileReader.self),
                analyzeFileUseCase: container.resolve(AnalyzeFileUseCase.self)
            )
        }
    }

    // MARK: - Service Resolution

    public func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: T.self)

        guard let service = services[key] as? T else {
            fatalError("No service registered for type \(T.self)")
        }

        return service
    }

    private func register<T>(_ type: T.Type, factory: @escaping (Container) -> T) {
        let key = String(describing: T.self)
        services[key] = factory(self)
    }
}