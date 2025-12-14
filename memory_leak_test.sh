#!/bin/bash

# Memory Leak Test Script for ASTAnalyzer
# This script runs the analyzer multiple times to stress test for memory leaks

set -e

echo "🔍 Starting Memory Leak Test for ASTAnalyzer"
echo "=============================================="

# Configuration
EXECUTABLE_NAME="ASTAnalyzer"
TEST_FILE="test_file.swift"
TEST_DIR="test_project"
ITERATIONS=50  # Number of times to run each test
TEMP_DIR=$(mktemp -d)
JSON_OUTPUT_DIR="$TEMP_DIR/json_output"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Build the project first
echo -e "${BLUE}Building ASTAnalyzer...${NC}"
swift build --configuration release

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful${NC}"

# Function to run a single test iteration
run_test() {
    local test_type="$1"
    local iteration="$2"

    case "$test_type" in
        "file")
            ./.build/release/$EXECUTABLE_NAME "$TEST_FILE" --json "$JSON_OUTPUT_DIR/file_$iteration" > /dev/null 2>&1
            ;;
        "directory")
            ./.build/release/$EXECUTABLE_NAME "$TEST_DIR" --json "$JSON_OUTPUT_DIR/dir_$iteration" > /dev/null 2>&1
            ;;
        "file_no_json")
            ./.build/release/$EXECUTABLE_NAME "$TEST_FILE" > /dev/null 2>&1
            ;;
        "directory_no_json")
            ./.build/release/$EXECUTABLE_NAME "$TEST_DIR" > /dev/null 2>&1
            ;;
    esac
}

# Function to run multiple iterations of a test
run_test_iterations() {
    local test_type="$1"
    local test_name="$2"

    echo -e "${YELLOW}Running $test_name test ($ITERATIONS iterations)...${NC}"

    for i in $(seq 1 $ITERATIONS); do
        if [ $((i % 10)) -eq 0 ]; then
            echo -e "${BLUE}  Iteration $i/$ITERATIONS${NC}"
        fi

        run_test "$test_type" "$i"

        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Test failed at iteration $i${NC}"
            return 1
        fi
    done

    echo -e "${GREEN}✅ $test_name test completed successfully${NC}"
    return 0
}

# Create output directory
mkdir -p "$JSON_OUTPUT_DIR"

# Get initial memory usage
echo -e "${BLUE}Getting initial memory baseline...${NC}"
initial_memory=$(ps -o rss= -p $$ | awk '{print $1}')

echo "Initial memory usage: ${initial_memory} KB"

# Test 1: Single file analysis with JSON export
if ! run_test_iterations "file" "Single File with JSON"; then
    exit 1
fi

# Test 2: Directory analysis with JSON export
if ! run_test_iterations "directory" "Directory with JSON"; then
    exit 1
fi

# Test 3: Single file analysis without JSON export
if ! run_test_iterations "file_no_json" "Single File without JSON"; then
    exit 1
fi

# Test 4: Directory analysis without JSON export
if ! run_test_iterations "directory_no_json" "Directory without JSON"; then
    exit 1
fi

# Get final memory usage
final_memory=$(ps -o rss= -p $$ | awk '{print $1}')
memory_diff=$((final_memory - initial_memory))

echo ""
echo -e "${BLUE}Memory Usage Summary:${NC}"
echo "Initial memory: ${initial_memory} KB"
echo "Final memory: ${final_memory} KB"
echo "Memory difference: ${memory_diff} KB"

if [ $memory_diff -gt 10000 ]; then  # More than 10MB increase
    echo -e "${RED}⚠️  WARNING: Significant memory increase detected (${memory_diff} KB)${NC}"
    echo -e "${RED}This may indicate a memory leak. Run with Instruments for detailed analysis.${NC}"
elif [ $memory_diff -gt 0 ]; then
    echo -e "${YELLOW}ℹ️  Minor memory increase detected (${memory_diff} KB)${NC}"
else
    echo -e "${GREEN}✅ No significant memory increase detected${NC}"
fi

# Cleanup
echo -e "${BLUE}Cleaning up temporary files...${NC}"
rm -rf "$TEMP_DIR"

echo ""
echo -e "${GREEN}🎉 Memory leak test completed!${NC}"
echo ""
echo -e "${BLUE}Next steps for detailed memory analysis:${NC}"
echo "1. Run with Instruments: instruments -t 'Leaks' .build/release/$EXECUTABLE_NAME $TEST_FILE"
echo "2. Or use Xcode: Product > Profile > Leaks"
echo "3. Check for growing memory usage patterns over time"

exit 0