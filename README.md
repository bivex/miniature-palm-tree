# AST Analyzer - Swift Code Quality & Architecture Analysis Tool

[![Swift](https://img.shields.io/badge/Swift-6.0+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%2014+-blue.svg)](https://www.apple.com/macos)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Build](https://img.shields.io/badge/build-passing-brightgreen.svg)](https://github.com/your-repo/ast-analyzer/actions)

**Advanced Swift AST Analyzer** - A powerful command-line tool for detecting architectural defects, code smells, and maintainability issues in Swift codebases. Built with Clean Architecture principles and Domain-Driven Design (DDD) patterns.

**Keywords:** Swift code analysis, architectural defects detection, Clean Architecture, DDD, static code analysis, code quality metrics, refactoring tools, anti-patterns, maintainability scoring, Swift development tools, code review automation

## 📋 Overview

**AST Analyzer** is a comprehensive static analysis tool specifically designed for Swift developers who want to maintain high code quality and architectural integrity in their projects. This powerful command-line utility performs deep analysis of Swift source code to identify architectural defects, code smells, and maintainability issues that could impact long-term project sustainability.

### 🔍 What It Analyzes

- **Architectural Anti-patterns**: Detects violations of SOLID principles, Clean Architecture patterns, and Domain-Driven Design best practices
- **Code Quality Metrics**: Measures maintainability scores, complexity metrics, and code health indicators
- **Performance Indicators**: Identifies potential performance bottlenecks and optimization opportunities
- **Best Practice Compliance**: Ensures adherence to Swift coding standards and architectural guidelines

### 🏗️ Built with Best Practices

The analyzer itself follows industry-leading software architecture principles:
- **Clean Architecture** layered approach for maximum testability and maintainability
- **Domain-Driven Design (DDD)** with rich domain models and business logic encapsulation
- **SOLID Principles** ensuring single responsibility and dependency inversion
- **Test-Driven Development (TDD)** approach with comprehensive test coverage

## 🏛️ Architecture & Design Patterns

This project serves as a **reference implementation** of modern Swift application architecture, demonstrating best practices in software design and clean code principles.

### 📚 Clean Architecture Layers

The codebase is meticulously organized into four distinct layers, each with clear responsibilities and dependencies:

#### 🎯 Domain Layer (`Sources/ASTAnalyzer/Domain/`)
**Core Business Logic & Rules**
- **Entities & Value Objects**: Immutable domain models representing business concepts
- **Domain Services**: Business logic that doesn't naturally fit entities
- **Business Rules**: Invariants and validation logic
- **Analysis Models**: Defect types, severity levels, and architectural patterns

#### 🔄 Application Layer (`Sources/ASTAnalyzer/Application/`)
**Use Cases & Application Services**
- **Use Cases**: Application-specific business logic orchestration
- **Command/Query Handlers**: CQRS pattern implementation
- **Application Services**: Cross-cutting concerns coordination

#### 🔌 Infrastructure Layer (`Sources/ASTAnalyzer/Infrastructure/`)
**External Concerns & Adapters**
- **Repository Adapters**: Data persistence abstractions
- **External Service Adapters**: Third-party integrations
- **Configuration Management**: Environment-specific settings
- **Dependency Injection**: IoC container implementation

#### 💻 Presentation Layer (`Sources/ASTAnalyzer/Presentation/`)
**User Interface & Output Formatting**
- **Console Interface**: Command-line user experience
- **Output Formatters**: Multiple export formats (Console, JSON, HTML)
- **Progress Indicators**: Real-time analysis feedback

### 🎨 Design Principles Implemented

#### SOLID Principles
- **Single Responsibility**: Each class has one reason to change
- **Open/Closed**: Open for extension, closed for modification
- **Liskov Substitution**: Subtypes are substitutable for base types
- **Interface Segregation**: Clients depend only on methods they use
- **Dependency Inversion**: Depend on abstractions, not concretions

#### Architectural Patterns
- **Ports & Adapters (Hexagonal Architecture)**: Technology-agnostic core
- **Dependency Injection**: Loose coupling through IoC container
- **Command Query Responsibility Segregation (CQRS)**: Separate read/write models
- **Domain-Driven Design (DDD)**: Ubiquitous language and bounded contexts

## 🚀 Key Features & Capabilities

### 🔍 Advanced Architectural Defect Detection

**AST Analyzer** employs sophisticated static analysis techniques to identify critical architectural issues that impact code maintainability, scalability, and development velocity. The tool uses formal methods and mathematical modeling to detect anti-patterns with high precision.

#### 🏗️ Architectural Anti-patterns Detected

| Anti-pattern | Description | Impact Level |
|-------------|-------------|-------------|
| **Multifaceted Abstraction** | Classes with multiple responsibilities violating SRP | 🔴 Critical |
| **God Class** | Overly complex classes with too many methods/properties | 🔴 Critical |
| **Insufficient Modularization** | Monolithic files that should be split | 🟡 High |
| **Unnecessary Abstraction** | Empty protocols or interfaces | 🟡 Medium |
| **Missing Abstraction** | Code duplication requiring extraction | 🟡 High |
| **Broken Hierarchy** | Inheritance violations (Liskov Substitution) | 🔴 Critical |
| **Dense Structure** | Methods/functions exceeding complexity limits | 🟡 Medium |
| **Deficient Encapsulation** | Exposed internal state | 🟡 Medium |
| **Weakened Modularity** | Tight coupling between modules | 🟡 High |
| **Long Method** | Methods exceeding recommended line limits | 🟡 Medium |
| **Lazy Class** | Classes with insufficient functionality | 🟢 Low |
| **Data Class** | Classes containing only data, no behavior | 🟢 Low |
| **Massive View Controller** | View Controllers that violate Single Responsibility Principle | 🔴 Critical |

#### 📊 Comprehensive Code Quality Metrics

**Maintainability Index Calculation**
```
Maintainability Score = 100 - (Defect Count × 5) - (Severity Weight × 2) - (Complexity Penalty)
```

**Metrics Analyzed:**
- **Cyclomatic Complexity**: Control flow complexity measurement
- **Lines of Code (LOC)**: Method and class size analysis
- **Coupling Metrics**: Afferent/Efferent coupling analysis
- **Cohesion Metrics**: LCOM (Lack of Cohesion in Methods)
- **Depth of Inheritance**: Inheritance hierarchy analysis
- **Number of Methods/Properties**: Class interface complexity
- **Testability Index**: Code testability assessment

#### 🎯 Smart Severity Classification

- **🔴 Critical**: Immediate refactoring required (health score < 0.5)
- **🟡 High**: Should be addressed soon (0.5 ≤ score < 0.7)
- **🟢 Medium**: Consider refactoring when possible (0.7 ≤ score < 0.8)
- **🔵 Low**: Minor improvements suggested (0.8 ≤ score < 1.0)

## 📖 Usage Guide & Examples

### 🛠️ Installation & Setup

#### System Requirements
- **Swift**: 6.0 or later
- **Platform**: macOS 14.0+
- **Memory**: 512MB minimum, 1GB recommended
- **Storage**: 50MB for installation

#### Building from Source

```bash
# Clone the repository
git clone https://github.com/your-username/ast-analyzer.git
cd ast-analyzer

# Build the project
swift build --configuration release

# Run tests (optional)
swift test
```

#### Installing Globally (Recommended)

```bash
# Build and install
swift build --configuration release
sudo cp .build/release/ASTAnalyzer /usr/local/bin/

# Verify installation
ast-analyzer --help
```

### 🎮 Command Line Interface

#### Basic Syntax
```bash
ast-analyzer [OPTIONS] <PATH>
```

#### Command Line Options

| Option | Description | Example |
|--------|-------------|---------|
| `--json [DIR]` | Export results to JSON format in timestamped folders | `--json ./reports` |
| `--markdown [DIR]` | Export results to Markdown format in timestamped folders | `--markdown ./reports` |
| `--help` | Display help information | `--help` |
| `--version` | Show version information | `--version` |

#### Analysis Targets
- **Single File**: Analyze individual Swift source files
- **Directory**: Recursively analyze all Swift files in a directory
- **Project**: Analyze entire Xcode projects or Swift packages

### 📝 Usage Examples

#### 🔍 Single File Analysis
```bash
# Analyze a specific Swift file
swift run ASTAnalyzer Sources/App/ViewController.swift

# Analyze with JSON export
swift run ASTAnalyzer Sources/App/Model.swift --json ./analysis-reports

# Analyze with Markdown export
swift run ASTAnalyzer Sources/App/ViewController.swift --markdown ./reports
```

#### 📁 Directory Analysis
```bash
# Analyze entire project directory
swift run ASTAnalyzer ./Sources --json ./project-analysis

# Analyze specific module
swift run ASTAnalyzer Sources/Core/ --json ./core-analysis

# Analyze with both JSON and Markdown export
swift run ASTAnalyzer ./Sources --json ./json-reports --markdown ./markdown-reports
```

#### 📊 Export Examples
```bash
# JSON export to custom directory
swift run ASTAnalyzer ./MyApp --json ./quality-reports

# Markdown export to current directory
swift run ASTAnalyzer File.swift --markdown

# Combined exports
swift run ASTAnalyzer ./Sources --json ./json-output --markdown ./markdown-output
```

### 📋 Sample Output

#### Console Report Format
```
🔍 Architectural Analysis Report
============================================================
📄 File: ViewController.swift
📍 Path: Sources/App/ViewController.swift
📊 Lines: 245
⏱️  Analysis Time: 0.023s

📈 SUMMARY:
------------------------------
🚨 Critical Issues: 2
⚠️  High Priority: 3
📊 Total Defects: 7
🎯 Maintainability Score: 68.5/100
🟡 STATUS: Needs attention

🚨 CRITICAL ISSUES:
----------------------------------------
• Class 'ViewController' has multifaceted abstraction (LCOM5: 0.95, WMC: 18, NOF: 8, NOM: 18)
  💡 Split into smaller classes, each handling a single responsibility

⚠️ HIGH PRIORITY:
------------------------------
• File contains 245 lines - exceeds recommended maximum of 200
  💡 Split into multiple files with related functionality
• Method 'viewDidLoad' contains 67 lines - too large
  💡 Break down into several smaller methods
```

#### JSON Export Structure
```
analysis-reports/
└── analysis_2025-12-14_14-30-15/
    ├── God_Class.json
    ├── Long_Method.json
    ├── Massive_View_Controller.json
    ├── Multifaceted_Abstraction.json
    └── summary.json
```

#### Markdown Export Structure
```
markdown-reports/
└── analysis_2025-12-14_14-30-15/
    ├── God_Class.md
    ├── Long_Method.md
    ├── Massive_View_Controller.md
    ├── Multifaceted_Abstraction.md
    └── README.md  # Summary report
```

## ⚙️ Configuration & Customization

### 🔧 Threshold Configuration

**AST Analyzer** uses configurable thresholds based on academic research and industry best practices. Customize detection sensitivity through the `Thresholds` configuration:

#### Academic Thresholds (Default)
```swift
let academicThresholds = Thresholds.academic
// God Class: WMC > 47, TCC < 0.33, ATFD > 5, LOC > 500
// Long Method: LOC > 50, CC > 10, NOI > 30
// Multifaceted Abstraction: LCOM > 0.725, WMC > 34
```

#### Lenient Thresholds
```swift
let lenientThresholds = Thresholds.lenient
// More permissive thresholds for legacy codebases
```

#### Strict Thresholds
```swift
let strictThresholds = Thresholds.strict
// Aggressive detection for new projects
```

#### Team-Specific Configurations

The analyzer now includes specialized configurations for different team types and organizational contexts:

```swift
// Startup teams - lenient for fast development
let startupThresholds = try Thresholds.startup()

// Enterprise teams - strict compliance and maintainability
let enterpriseThresholds = try Thresholds.enterprise()

// Research teams - academic-level scrutiny
let researchThresholds = try Thresholds.research()

// Legacy codebases - very lenient for existing projects
let legacyThresholds = try Thresholds.legacy()

// Mobile development - iOS/Swift optimized
let mobileThresholds = try Thresholds.mobile()
```

Each configuration is tailored to specific development contexts:
- **Startup**: Prioritizes development velocity with more lenient thresholds
- **Enterprise**: Emphasizes code quality and maintainability for large organizations
- **Research**: Provides thorough analysis for academic and research environments
- **Legacy**: Accommodates existing codebases that can't be immediately refactored
- **Mobile**: Optimized for iOS/Swift development patterns and constraints

#### Custom Configuration
```swift
let customConfig = Thresholds(
    classSmells: ClassSmellThresholds(
        godClassWMC: 40,           // Weighted Methods per Class
        godClassTCC: 0.4,          // Tight Class Cohesion
        godClassATFD: 4,           // Access To Foreign Data
        godClassLOC: 400,          // Lines of Code
        mfaLCOM: 0.8,             // Lack of Cohesion in Methods
        mfaWMC: 30,               // Multifaceted Abstraction WMC
        mfaNOF: 6,                // Number of Fields
        mfaNOM: 12,               // Number of Methods
        deficientEncapsulationWOA: 0.25, // Weakness of Abstraction
        lazyClassNOM: 3,          // Lazy Class Methods
        lazyClassNOF: 3,          // Lazy Class Fields
        lazyClassDIT: 1           // Depth of Inheritance Tree
    ),
    methodSmells: MethodSmellThresholds(
        longMethodLOC: 40,        // Long Method Lines
        longMethodCC: 8,          // Cyclomatic Complexity
        longMethodNOI: 25         // Number of Instructions
    )
)
```

### 📤 JSON Export Configuration

The `--json` flag enables comprehensive JSON export with the following features:

#### Export Structure
- **Timestamped Directories**: `analysis_YYYY-MM-DD_HH-MM-SS/`
- **Organized by Smell Type**: Separate JSON files for each defect category
- **Summary Report**: Consolidated analysis metadata and statistics
- **Detailed Instances**: Complete defect information with locations and suggestions

#### JSON Schema
```json
{
  "summary": {
    "totalSmells": 15,
    "healthScore": 0.75,
    "healthScorePercentage": "75.0%",
    "healthStatus": "Fair",
    "requiresRefactoring": true,
    "criticalSmellsCount": 3
  },
  "smellsByType": [
    {
      "type": "God Class",
      "count": 2,
      "description": "A class that knows too much or does too much"
    }
  ],
  "recommendations": ["Refactor large classes into smaller components"],
  "metadata": {
    "timestamp": "2025-12-14T14:30:15Z",
    "duration": 0.023,
    "filesAnalyzed": 5,
    "classesAnalyzed": 12,
    "methodsAnalyzed": 45
  }
}
```

## 🛠️ Extending & Customizing the Analyzer

**AST Analyzer** is designed for extensibility, allowing developers to add custom defect detectors, output formats, and analysis rules. The modular architecture supports plugin-based extensions and custom integrations.

### 🔧 Adding Custom Defect Detectors

#### Step 1: Implement the DefectDetector Protocol

Create a new detector class that analyzes specific code patterns:

```swift
import SwiftSyntax

final class CustomSmellDetector: DefectDetector {
    let detectableDefects: [DefectType] = [.customSmell]

    func detectDefects(in sourceFile: SourceFileSyntax, filePath: String) -> [SmellInstance] {
        var defects: [SmellInstance] = []

        // Traverse the AST and detect custom patterns
        let visitor = CustomSmellVisitor()
        visitor.walk(sourceFile)

        for violation in visitor.violations {
            let defect = SmellInstance(
                type: .customSmell,
                element: .class(name: violation.className),
                severity: violation.severity,
                location: Location(
                    filePath: filePath,
                    lineNumber: violation.lineNumber,
                    context: violation.context
                ),
                message: violation.message,
                suggestion: violation.suggestion
            )
            defects.append(defect)
        }

        return defects
    }
}

private class CustomSmellVisitor: SyntaxVisitor {
    var violations: [CustomViolation] = []

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        // Analyze class declarations for custom patterns
        let className = node.name.text
        let methodCount = node.members.members.count

        if methodCount > 20 {  // Custom rule
            violations.append(CustomViolation(
                className: className,
                severity: 0.7,
                lineNumber: node.position.line,
                context: "class \(className)",
                message: "Class '\(className)' has too many methods (\(methodCount))",
                suggestion: "Consider splitting this class into smaller components"
            ))
        }

        return .visitChildren
    }
}
```

#### Step 2: Register the Detector

Add your custom detector to the dependency injection container:

```swift
// In Container.swift
register(AnalysisCoordinator.self) { container in
    let detectors: [DefectDetector] = [
        MultifacetedAbstractionDetector(),
        InsufficientModularizationDetector(),
        DeficientEncapsulationDetector(),
        GodClassDetector(),
        LazyClassDetector(),
        LongMethodDetector(),
        MassiveViewControllerDetector(),
        CustomSmellDetector(),  // Your custom detector
        // ... other detectors
    ]
    return AnalysisCoordinator(defectDetectors: detectors)
}
```

### 🎨 Adding Custom Output Formats

#### Implementing Custom Presenters

Create new output formats by implementing the presenter protocols:

```swift
final class HTMLAnalysisResultPresenter: AnalysisResultPresenter {
    func present(result: AnalysisResult) {
        let html = generateHTML(for: result)
        let outputPath = "analysis-report.html"
        try html.write(toFile: outputPath, atomically: true, encoding: .utf8)
        print("📄 HTML report generated: \(outputPath)")
    }

    private func generateHTML(for result: AnalysisResult) -> String {
        // Generate comprehensive HTML report
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <title>AST Analysis Report - \(result.sourceFile.filePath)</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; }
                .critical { color: #dc3545; }
                .high { color: #fd7e14; }
                .medium { color: #ffc107; }
                .low { color: #28a745; }
            </style>
        </head>
        <body>
            <h1>Architectural Analysis Report</h1>
            <h2>\(result.sourceFile.filePath)</h2>
            <p><strong>Score:</strong> \(result.maintainabilityScore)/100</p>
            <!-- Detailed HTML content -->
        </body>
        </html>
        """
    }
}
```

#### Supported Export Formats
- **Console**: Human-readable terminal output with emojis and colors
- **JSON**: Structured data export for CI/CD integration and tooling
- **Markdown**: Documentation-friendly format for GitHub/GitLab integration
- **HTML**: Web-viewable reports with interactive elements
- **XML**: Machine-readable format for enterprise tools
- **CSV**: Spreadsheet-compatible tabular data

### 🔌 Integration APIs

#### CI/CD Integration
```bash
# In GitHub Actions
- name: Code Quality Analysis
  run: |
    swift run ASTAnalyzer ./Sources --json ./reports
    # Parse JSON reports for quality gates
    if [ $(jq '.summary.healthScore < 0.7' ./reports/analysis_*/summary.json) = "true" ]; then
        echo "Code quality below threshold"
        exit 1
    fi
```

#### Custom Tool Integration
```swift
import ASTAnalyzer

let analyzer = ProjectSmellAnalyzer(thresholds: .strict)
let report = try await analyzer.analyze(sourceFiles: sourceFiles)

// Process results programmatically
for smell in report.smellsByClass.values.flatMap({ $0 }) {
    switch smell.type {
    case .godClass:
        // Handle God Class detection
        break
    case .longMethod:
        // Handle Long Method detection
        break
    // ... handle other smell types
    }
}
```

## Requirements

- Swift 6.2+
- macOS 14+

## Dependencies

- [SwiftSyntax](https://github.com/swiftlang/swift-syntax): For parsing Swift source code

## License

This project demonstrates Clean Architecture principles for Swift applications.