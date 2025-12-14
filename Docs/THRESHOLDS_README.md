# YAML Thresholds Configuration

You can now configure custom thresholds for code smell detection using YAML configuration files.

## Usage

```bash
swift run ASTAnalyzer <file_or_directory> --thresholds <config.yml>
```

## Example YAML Configuration

```yaml
class_smells:
  god_class_wmc: 47
  god_class_tcc: 0.33
  god_class_atfd: 5
  god_class_loc: 500
  mfa_lcom: 0.725
  mfa_wmc: 34
  mfa_nof: 8
  mfa_nom: 14
  deficient_encapsulation_woa: 0.3
  lazy_class_nom: 5
  lazy_class_nof: 5
  lazy_class_dit: 2

method_smells:
  long_method_loc: 50
  long_method_cc: 10
  long_method_noi: 30

structural_smells:
  message_chain_length: 3
  broken_hierarchy_dit: 3
  cyclic_dependency_length: 2
  feature_envy_threshold: 3
```

## Available Thresholds

### Detector Mappings
- **FeatureEnvyDetector**: Uses `structural_smells.feature_envy_threshold`
- **CyclicDependencyDetector**: Uses `structural_smells.cyclic_dependency_length`
- **MessageChainDetector**: Uses `structural_smells.message_chain_length`
- **BrokenHierarchyDetector**: Uses `structural_smells.broken_hierarchy_dit`

### Class Smell Thresholds
- **god_class_wmc**: Weighted Methods per Class for God Class detection
- **god_class_tcc**: Tight Class Cohesion for God Class detection
- **god_class_atfd**: Access to Foreign Data for God Class detection
- **god_class_loc**: Lines of Code for God Class detection
- **mfa_lcom**: Lack of Cohesion in Methods for Multifaceted Abstraction
- **mfa_wmc**: Weighted Methods per Class for Multifaceted Abstraction
- **mfa_nof**: Number of Fields for Multifaceted Abstraction
- **mfa_nom**: Number of Methods for Multifaceted Abstraction
- **deficient_encapsulation_woa**: Weight of Access for Deficient Encapsulation
- **lazy_class_nom**: Number of Methods for Lazy Class detection
- **lazy_class_nof**: Number of Fields for Lazy Class detection
- **lazy_class_dit**: Depth of Inheritance Tree for Lazy Class detection

### Method Smell Thresholds
- **long_method_loc**: Lines of Code for Long Method detection
- **long_method_cc**: Cyclomatic Complexity for Long Method detection
- **long_method_noi**: Number of Instructions for Long Method detection

### Structural Smell Thresholds
- **message_chain_length**: Maximum length of message chains
- **broken_hierarchy_dit**: Depth of Inheritance Tree for Broken Hierarchy
- **cyclic_dependency_length**: Length of cyclic dependencies
- **feature_envy_threshold**: Minimum foreign attribute access count for Feature Envy detection

## Built-in Configurations

The tool includes several built-in threshold configurations:

### Legacy Configurations
- **academic** (default): Academic thresholds from research literature
- **lenient**: More permissive thresholds
- **strict**: More aggressive defect detection

### Team/Company Profiles

The tool now includes specialized configurations for different types of teams and organizations:

- **startup**: Lenient thresholds optimized for fast-moving startup teams that prioritize speed over strict quality metrics
- **enterprise**: Strict thresholds designed for large organizations with complex codebases and compliance requirements
- **research**: Academic-level scrutiny for research teams requiring thorough analysis
- **legacy**: Very lenient thresholds for teams working with existing large codebases
- **mobile**: Balanced thresholds optimized for iOS/Swift mobile development patterns

### Developer Experience Level Profiles

The analyzer also provides configurations tailored to different developer experience levels:

- **junior**: More lenient thresholds to support learning and avoid overwhelming new developers with too many issues
- **middle**: Balanced thresholds based on academic research, suitable for experienced developers
- **senior**: Strict thresholds for expert developers who can handle complex refactoring tasks and want early issue detection

These profiles are loaded from YAML files in `Config/teams/` and can be used programmatically:

```swift
// Load team-specific thresholds
let thresholds = try Thresholds.startup()      // For startup teams
let thresholds = try Thresholds.enterprise()   // For enterprise teams
let thresholds = try Thresholds.research()     // For research teams
let thresholds = try Thresholds.legacy()       // For legacy codebases
let thresholds = try Thresholds.mobile()       // For mobile development

// Load experience level thresholds
let thresholds = try Thresholds.junior()       // For junior developers
let thresholds = try Thresholds.middle()       // For middle developers
let thresholds = try Thresholds.senior()       // For senior developers
```

### Custom Team Configurations

Teams can create their own configurations by:

1. Copying `Config/teams/config_template.yml` to create a custom config
2. Modifying thresholds based on team needs and codebase characteristics
3. Loading the custom config using `--thresholds` flag or the API

Example custom team configuration structure:
```
Config/teams/
├── startup/
│   └── default.yml          # Startup team defaults
├── enterprise/
│   └── default.yml          # Enterprise team defaults
├── research/
│   └── default.yml          # Research team defaults
├── legacy/
│   └── default.yml          # Legacy codebase defaults
├── mobile/
│   └── default.yml          # Mobile development defaults
├── junior/
│   └── default.yml          # Junior developer defaults
├── middle/
│   └── default.yml          # Middle developer defaults
├── senior/
│   └── default.yml          # Senior developer defaults
├── your_team/
│   ├── default.yml          # Your team's custom config
│   ├── ios_focused.yml      # iOS-specific variant
│   └── backend_focused.yml  # Backend-specific variant
└── config_template.yml      # Template for new teams
```

## Exporting Current Thresholds

You can export the current thresholds to YAML format programmatically using the Thresholds API.