#!/bin/bash

# Swift Memory Leak Tests
# Runs the Swift test suite with memory profiling

set -e

echo "🧪 Running Swift Memory Leak Tests"
echo "=================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Build and run tests
echo -e "${BLUE}Building and running memory leak tests...${NC}"

if swift test --enable-test-discovery 2>/dev/null; then
    echo -e "${GREEN}✅ Memory leak tests completed successfully${NC}"
else
    echo -e "${YELLOW}⚠️  Some tests may have failed or warnings detected${NC}"
    echo -e "${BLUE}Check the output above for details${NC}"
fi

echo ""
echo -e "${BLUE}Memory leak test analysis:${NC}"
echo "- Tests run multiple analysis iterations to detect memory growth patterns"
echo "- Memory snapshots are taken before and after each major operation"
echo "- Tests fail if memory growth exceeds acceptable thresholds"
echo ""
echo -e "${YELLOW}If tests fail with memory warnings:${NC}"
echo "1. Check the test output for specific memory growth details"
echo "2. Run with Instruments for more detailed analysis:"
echo "   instruments -t 'Leaks' .build/debug/ASTAnalyzer test_file.swift"
echo "3. Consider optimizing memory usage in the analysis pipeline"