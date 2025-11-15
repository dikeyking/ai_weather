#!/bin/bash

# Weather App - Build and Test Script
# macOS 天气应用构建和测试脚本

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Weather App - Build & Test${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Project settings
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEME="Weather"
DESTINATION="platform=macOS"

# Function to print colored output
print_status() {
    echo -e "${GREEN}▶${NC} $1"
}

print_error() {
    echo -e "${RED}✖${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode not found. Please install Xcode from the Mac App Store."
    exit 1
fi

print_success "Xcode found"

# Check Xcode version
XCODE_VERSION=$(xcodebuild -version | grep "Xcode" | awk '{print $2}')
print_status "Xcode version: $XCODE_VERSION"

echo ""
print_status "Building project..."

# Clean build folder
xcodebuild clean \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    > /dev/null 2>&1

print_success "Clean completed"

# Build project
xcodebuild build \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -quiet

if [ $? -eq 0 ]; then
    print_success "Build successful"
else
    print_error "Build failed"
    exit 1
fi

echo ""
print_status "Running tests..."

# Run tests
xcodebuild test \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -quiet

if [ $? -eq 0 ]; then
    print_success "All tests passed"
else
    print_error "Some tests failed"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Build and Test Completed Successfully${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Open the project: open Weather.xcodeproj"
echo "  2. Press Cmd+R to run the app"
echo "  3. Press Cmd+U to run tests in Xcode"
echo ""
echo "For more information, see:"
echo "  - README.md (User guide)"
echo "  - PLAN.md (Design document)"
echo "  - IMPLEMENTATION.md (Implementation summary)"
echo "  - QUICKREF.md (Quick reference)"
echo ""

exit 0
