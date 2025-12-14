#!/bin/bash

# Instruments Memory Leak Test Script
# Uses Apple's Instruments tool to detect memory leaks

set -e

echo "🔍 Running Detailed Memory Leak Analysis with Instruments"
echo "======================================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
EXECUTABLE="./.build/release/ASTAnalyzer"
TEST_FILE="test_file.swift"
TEST_DIR="test_project"
OUTPUT_DIR="./instruments_output"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Check if Instruments is available
if ! command -v instruments &> /dev/null; then
    echo -e "${RED}❌ Instruments command line tool not found${NC}"
    echo -e "${YELLOW}Please install Xcode command line tools:${NC}"
    echo "  xcode-select --install"
    exit 1
fi

# Build the project
echo -e "${BLUE}Building ASTAnalyzer in release mode...${NC}"
swift build --configuration release

if [ ! -f "$EXECUTABLE" ]; then
    echo -e "${RED}❌ Executable not found at $EXECUTABLE${NC}"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo -e "${GREEN}✅ Build successful${NC}"

# Function to run Instruments with Leaks template
run_instruments_leaks() {
    local test_name="$1"
    local target="$2"
    local output_file="$OUTPUT_DIR/${test_name}_${TIMESTAMP}.trace"

    echo -e "${BLUE}Running Instruments Leaks analysis: $test_name${NC}"
    echo -e "${YELLOW}Target: $target${NC}"
    echo -e "${YELLOW}Output: $output_file${NC}"

    # Run Instruments with Leaks template
    # Note: Using -D to specify output directory for the trace
    instruments -t "Leaks" \
                -D "$output_file" \
                "$EXECUTABLE" \
                "$target" \
                --json "$OUTPUT_DIR/json_temp" \
                2>/dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Instruments analysis completed for $test_name${NC}"
    else
        echo -e "${YELLOW}⚠️  Instruments completed with warnings for $test_name${NC}"
    fi

    echo ""
}

# Clean up any existing temp JSON directory
rm -rf "$OUTPUT_DIR/json_temp"
mkdir -p "$OUTPUT_DIR/json_temp"

# Run different test scenarios with Instruments
echo -e "${BLUE}Starting Instruments memory leak analysis...${NC}"
echo ""

# Test 1: Single file analysis
run_instruments_leaks "single_file" "$TEST_FILE"

# Test 2: Directory analysis
run_instruments_leaks "directory" "$TEST_DIR"

# Test 3: Large file analysis (if we create one)
echo -e "${BLUE}Creating a large test file for stress testing...${NC}"
LARGE_TEST_FILE="$OUTPUT_DIR/large_test_file.swift"
cat > "$LARGE_TEST_FILE" << 'EOF'
// Large test file for memory leak stress testing
import Foundation

class LargeTestClass {
    // Many properties to test memory usage
EOF

# Add many similar classes to make it large
for i in {1..100}; do
    cat >> "$LARGE_TEST_FILE" << EOF
    var property${i}: String = "test${i}"
    var number${i}: Int = ${i}
EOF
done

cat >> "$LARGE_TEST_FILE" << 'EOF'
}

func largeMethod() {
EOF

# Add a very long method
for i in {1..200}; do
    echo "    let var${i} = ${i}" >> "$LARGE_TEST_FILE"
    echo "    print(\"Variable ${i}: \\(var${i})\")" >> "$LARGE_TEST_FILE"
done

cat >> "$LARGE_TEST_FILE" << 'EOF'
}

class AnotherLargeClass {
EOF

for i in {1..50}; do
    cat >> "$LARGE_TEST_FILE" << EOF
    func method${i}() {
        print("Method ${i}")
    }
EOF
done

echo "}" >> "$LARGE_TEST_FILE"

echo -e "${GREEN}✅ Large test file created${NC}"

# Test 4: Large file analysis
run_instruments_leaks "large_file" "$LARGE_TEST_FILE"

# Cleanup
echo -e "${BLUE}Cleaning up temporary files...${NC}"
rm -rf "$OUTPUT_DIR/json_temp"
rm -f "$LARGE_TEST_FILE"

echo ""
echo -e "${GREEN}🎉 Instruments memory leak analysis completed!${NC}"
echo ""
echo -e "${BLUE}Analysis Results:${NC}"
echo "Trace files saved to: $OUTPUT_DIR"
echo ""
echo -e "${YELLOW}To view the results:${NC}"
echo "1. Open Instruments application"
echo "2. File > Open Recent Traces, or File > Open"
echo "3. Navigate to $OUTPUT_DIR and open the .trace files"
echo ""
echo -e "${YELLOW}What to look for in Instruments:${NC}"
echo "- Leaks instrument: Look for red spikes indicating memory leaks"
echo "- Allocations instrument: Check for growing memory usage over time"
echo "- Look at the call tree to identify where leaks are occurring"
echo ""
echo -e "${BLUE}Alternative: Use Xcode profiling${NC}"
echo "1. Open terminal and run: open -a Instruments"
echo "2. Or from Xcode: Product > Profile"
echo "3. Select 'Leaks' template and choose your executable"