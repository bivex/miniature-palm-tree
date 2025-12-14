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
- **academic** (default): Academic thresholds from research literature
- **lenient**: More permissive thresholds
- **strict**: More aggressive defect detection

## Exporting Current Thresholds

You can export the current thresholds to YAML format programmatically using the Thresholds API.