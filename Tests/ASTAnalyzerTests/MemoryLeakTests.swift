//
//  MemoryLeakTests.swift
//  ASTAnalyzerTests
//
//  Memory leak detection tests for ASTAnalyzer
//

import Foundation
@testable import ASTAnalyzer

// Simple test runner without XCTest dependency
struct TestRunner {
    static func runTest(name: String, test: () async throws -> Void) async throws {
        print("🧪 Running test: \(name)")
        try await test()
        print("✅ Test passed: \(name)")
    }
}

class MemoryLeakTests {

    var testFileURL: URL!
    var testDirectoryURL: URL!
    var memoryProfiler: MemoryProfiler!

    func setUp() {
        memoryProfiler = MemoryProfiler()

        // Create test file
        let testFileContent = """
        import Foundation

        class TestClass {
            var property: String = "test"
            func method() { print("test") }
        }

        func testFunction() {
            let obj = TestClass()
            obj.method()
        }
        """

        testFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("memory_test.swift")
        try? testFileContent.write(to: testFileURL, atomically: true, encoding: .utf8)

        // Create test directory with multiple files
        testDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("memory_test_dir")
        try? FileManager.default.createDirectory(at: testDirectoryURL, withIntermediateDirectories: true)

        for i in 1...5 {
            let fileURL = testDirectoryURL.appendingPathComponent("file\(i).swift")
            try? testFileContent.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }

    func tearDown() {
        try? FileManager.default.removeItem(at: testFileURL)
        try? FileManager.default.removeItem(at: testDirectoryURL)
        memoryProfiler = nil
    }

    func testMemoryUsageStabilitySingleFile() async throws {
        memoryProfiler.takeSnapshot(label: "test_start")

        let analyzer = ProjectSmellAnalyzer(thresholds: .academic)

        // Run analysis multiple times to check for memory leaks
        for iteration in 1...10 {
            let sourceFile = SourceFile(filePath: testFileURL.path, content: try String(contentsOf: testFileURL))
            try sourceFile.validate()

            let sourceFiles = [sourceFile]
            let report = await analyzer.analyze(sourceFiles: sourceFiles)

            // Verify report was generated
            if report.smellsByType.isEmpty {
                throw TestError.assertionFailed("Analysis should detect some smells")
            }

            memoryProfiler.takeSnapshot(label: "iteration_\(iteration)")
        }

        memoryProfiler.takeSnapshot(label: "test_end")

        let analysis = memoryProfiler.analyzeMemoryUsage()

        // Print memory analysis for debugging
        print("Memory Analysis for Single File Test:")
        for recommendation in analysis.recommendations {
            print("  \(recommendation)")
        }

        // Assert no significant memory leak (less than 10MB growth)
        if analysis.memoryGrowth >= 10 * 1024 * 1024 {
            throw TestError.assertionFailed("Memory growth should be less than 10MB, got \(analysis.memoryGrowth) bytes")
        }
    }

    func testMemoryUsageStabilityDirectory() async throws {
        memoryProfiler.takeSnapshot(label: "test_start")

        let analyzer = ProjectSmellAnalyzer(thresholds: .academic)

        // Run analysis multiple times to check for memory leaks
        for iteration in 1...5 {
            let enumerator = FileManager.default.enumerator(at: testDirectoryURL, includingPropertiesForKeys: nil)?
                .compactMap { $0 as? URL }
                .filter { $0.pathExtension == "swift" }

            let sourceFiles: [SourceFile] = try (enumerator?.compactMap { url -> SourceFile? in
                let content = try String(contentsOf: url)
                return SourceFile(filePath: url.path, content: content)
            } ?? [])

            let report = await analyzer.analyze(sourceFiles: sourceFiles)

            // Verify report was generated
            if report.smellsByType.isEmpty {
                throw TestError.assertionFailed("Analysis should detect some smells")
            }

            memoryProfiler.takeSnapshot(label: "iteration_\(iteration)")
        }

        memoryProfiler.takeSnapshot(label: "test_end")

        let analysis = memoryProfiler.analyzeMemoryUsage()

        // Print memory analysis for debugging
        print("Memory Analysis for Directory Test:")
        for recommendation in analysis.recommendations {
            print("  \(recommendation)")
        }

        // Assert no significant memory leak (less than 20MB growth for directory analysis)
        if analysis.memoryGrowth >= 20 * 1024 * 1024 {
            throw TestError.assertionFailed("Memory growth should be less than 20MB, got \(analysis.memoryGrowth) bytes")
        }
    }

    func testMemoryUsageWithJSONExport() async throws {
        memoryProfiler.takeSnapshot(label: "test_start")

        let analyzer = ProjectSmellAnalyzer(thresholds: .academic)
        let jsonExporter = JSONExporter()

        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("json_export_test")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Run analysis with JSON export multiple times
        for iteration in 1...5 {
            let sourceFile = SourceFile(filePath: testFileURL.path, content: try String(contentsOf: testFileURL))
            try sourceFile.validate()

            let sourceFiles = [sourceFile]
            let report = await analyzer.analyze(sourceFiles: sourceFiles)

            let outputPath = tempDir.appendingPathComponent("test_\(iteration).json").path
            try jsonExporter.export(report: report, to: outputPath)

            memoryProfiler.takeSnapshot(label: "iteration_\(iteration)")
        }

        memoryProfiler.takeSnapshot(label: "test_end")

        let analysis = memoryProfiler.analyzeMemoryUsage()

        // Print memory analysis for debugging
        print("Memory Analysis for JSON Export Test:")
        for recommendation in analysis.recommendations {
            print("  \(recommendation)")
        }

        // Assert no significant memory leak (less than 15MB growth)
        if analysis.memoryGrowth >= 15 * 1024 * 1024 {
            throw TestError.assertionFailed("Memory growth should be less than 15MB, got \(analysis.memoryGrowth) bytes")
        }
    }

    func testLargeFileMemoryUsage() async throws {
        // Create a large test file
        var largeContent = "import Foundation\n\n"
        largeContent += "class LargeTestClass {\n"

        // Add many properties and methods
        for i in 1...1000 {
            largeContent += "    var property\(i): String = \"value\(i)\"\n"
            if i % 100 == 0 {
                largeContent += "\n    func method\(i/100)() {\n"
                for j in 1...10 {
                    largeContent += "        let local\(j) = \(j)\n"
                }
                largeContent += "    }\n\n"
            }
        }
        largeContent += "}\n"

        let largeFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("large_memory_test.swift")
        try largeContent.write(to: largeFileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: largeFileURL) }

        memoryProfiler.takeSnapshot(label: "large_test_start")

        let analyzer = ProjectSmellAnalyzer(thresholds: .academic)

        // Test large file analysis
        for iteration in 1...3 {
            let sourceFile = SourceFile(filePath: largeFileURL.path, content: largeContent)
            try sourceFile.validate()

            let sourceFiles = [sourceFile]
            let report = await analyzer.analyze(sourceFiles: sourceFiles)

            if report.smellsByType.isEmpty {
                throw TestError.assertionFailed("Large file analysis should detect smells")
            }

            memoryProfiler.takeSnapshot(label: "large_iteration_\(iteration)")
        }

        memoryProfiler.takeSnapshot(label: "large_test_end")

        let analysis = memoryProfiler.analyzeMemoryUsage()

        print("Memory Analysis for Large File Test:")
        for recommendation in analysis.recommendations {
            print("  \(recommendation)")
        }

        // Assert no significant memory leak (less than 50MB growth for large file)
        if analysis.memoryGrowth >= 50 * 1024 * 1024 {
            throw TestError.assertionFailed("Memory growth should be less than 50MB for large file, got \(analysis.memoryGrowth) bytes")
        }
    }
}

// Test error type
enum TestError: Error {
    case assertionFailed(String)
}

// Main test runner
@main
struct MemoryTestMain {
    static func main() async {
        print("🧪 Starting Memory Leak Tests")

        let testSuite = MemoryLeakTests()
        testSuite.setUp()
        defer { testSuite.tearDown() }

        // Run tests sequentially
        print("🧪 Running test: Single File Memory Stability")
        do {
            try await testSuite.testMemoryUsageStabilitySingleFile()
            print("✅ Test passed: Single File Memory Stability")
        } catch {
            print("❌ Test failed: Single File Memory Stability - \(error)")
            exit(1)
        }

        print("🧪 Running test: Directory Memory Stability")
        do {
            try await testSuite.testMemoryUsageStabilityDirectory()
            print("✅ Test passed: Directory Memory Stability")
        } catch {
            print("❌ Test failed: Directory Memory Stability - \(error)")
            exit(1)
        }

        print("🧪 Running test: JSON Export Memory Usage")
        do {
            try await testSuite.testMemoryUsageWithJSONExport()
            print("✅ Test passed: JSON Export Memory Usage")
        } catch {
            print("❌ Test failed: JSON Export Memory Usage - \(error)")
            exit(1)
        }

        print("🧪 Running test: Large File Memory Usage")
        do {
            try await testSuite.testLargeFileMemoryUsage()
            print("✅ Test passed: Large File Memory Usage")
        } catch {
            print("❌ Test failed: Large File Memory Usage - \(error)")
            exit(1)
        }

        print("🎉 All memory leak tests completed successfully!")
    }
}