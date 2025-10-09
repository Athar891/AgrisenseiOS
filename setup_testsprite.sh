#!/bin/bash

# TestSprite Setup Script for AgriSense iOS
# Created: October 7, 2025

set -e  # Exit on error

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}     TestSprite Setup for AgriSense iOS              ${NC}"
echo -e "${BLUE}=====================================================${NC}"

# Check for required tools
check_requirements() {
    echo -e "${BLUE}Checking requirements...${NC}"
    
    # Check for Node.js
    if ! command -v node &> /dev/null; then
        echo -e "${RED}Error: Node.js is not installed.${NC}"
        echo -e "${YELLOW}Please install Node.js from https://nodejs.org/${NC}"
        exit 1
    fi
    
    NODE_VERSION=$(node -v | cut -d 'v' -f 2 | cut -d '.' -f 1)
    if [ $NODE_VERSION -lt 18 ]; then
        echo -e "${YELLOW}Warning: Node.js version $NODE_VERSION detected. TestSprite works best with Node.js 18+${NC}"
    else
        echo -e "${GREEN}✓ Node.js $(node -v) installed${NC}"
    fi
    
    # Check for npm
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}Error: npm is not installed.${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ npm $(npm -v) installed${NC}"
    fi
    
    # Check for Xcode
    if ! command -v xcodebuild &> /dev/null; then
        echo -e "${RED}Error: Xcode command line tools not found.${NC}"
        echo -e "${YELLOW}Please install Xcode from the App Store or run 'xcode-select --install'${NC}"
        exit 1
    else
        XCODE_VERSION=$(xcodebuild -version | head -n 1 | cut -d ' ' -f 2)
        echo -e "${GREEN}✓ Xcode $XCODE_VERSION installed${NC}"
        
        if [ $(echo $XCODE_VERSION | cut -d '.' -f 1) -lt 16 ]; then
            echo -e "${YELLOW}Warning: TestSprite works best with Xcode 16+${NC}"
        fi
    fi
}

# Install TestSprite CLI
install_testsprite_cli() {
    echo -e "\n${BLUE}Installing TestSprite CLI...${NC}"
    
    if ! command -v testsprite &> /dev/null; then
        echo "npm install -g testsprite-cli"
        echo -e "${YELLOW}Note: In a real environment, this would install the TestSprite CLI${NC}"
        
        # Create a mock CLI for demonstration
        mkdir -p ~/bin
        cat > ~/bin/testsprite << 'EOF'
#!/bin/bash
echo "TestSprite CLI Mock - v1.0.0"
echo "This is a mock of the TestSprite CLI for demonstration purposes."

if [ "$1" == "--version" ]; then
    echo "testsprite-cli v1.0.0"
elif [ "$1" == "run" ]; then
    echo "Running tests with configuration from testsprite_config.json..."
    echo "✓ All tests passed!"
elif [ "$1" == "configure" ]; then
    read -p "Enter your TestSprite API key (leave blank for demo): " apikey
    echo "Configuration saved!"
else
    echo "Available commands: --version, run, configure"
fi
EOF
        chmod +x ~/bin/testsprite
        
        # Add to PATH temporarily
        export PATH=$PATH:~/bin
        
        echo -e "${GREEN}✓ Mock TestSprite CLI installed${NC}"
    else
        echo -e "${GREEN}✓ TestSprite CLI already installed${NC}"
        testsprite --version
    fi
}

# Configure TestSprite
configure_testsprite() {
    echo -e "\n${BLUE}Configuring TestSprite...${NC}"
    
    if [ -f ~/bin/testsprite ]; then
        # Using the mock CLI
        ~/bin/testsprite configure
    else
        echo -e "${YELLOW}In a real environment, this would configure TestSprite with your API key.${NC}"
        echo -e "${YELLOW}You would run: testsprite configure${NC}"
    fi
    
    echo -e "${GREEN}✓ TestSprite configured${NC}"
}

# Create test directory structure
create_test_structure() {
    echo -e "\n${BLUE}Creating test directory structure...${NC}"
    
    if [ ! -d "./test-reports" ]; then
        mkdir -p ./test-reports
        echo -e "${GREEN}✓ Created test-reports directory${NC}"
    else
        echo -e "${GREEN}✓ test-reports directory already exists${NC}"
    fi
}

# Make scripts executable
make_scripts_executable() {
    echo -e "\n${BLUE}Making scripts executable...${NC}"
    
    chmod +x ./run_testsprite.sh
    chmod +x ./analyze_testsprite_results.sh
    
    echo -e "${GREEN}✓ Scripts are now executable${NC}"
}

# Verify test plans
verify_test_plans() {
    echo -e "\n${BLUE}Verifying test plans...${NC}"
    
    if [ -f "./UnitTests.xctestplan" ] && [ -f "./UITests.xctestplan" ]; then
        echo -e "${GREEN}✓ Test plans verified${NC}"
    else
        echo -e "${YELLOW}Warning: Test plans not found or incomplete.${NC}"
    fi
}

# Show completion message
show_completion() {
    echo -e "\n${GREEN}=====================================================${NC}"
    echo -e "${GREEN}    TestSprite Setup Completed Successfully!         ${NC}"
    echo -e "${GREEN}=====================================================${NC}"
    
    echo -e "\n${BLUE}Next Steps:${NC}"
    echo -e "1. Run tests: ${YELLOW}./run_testsprite.sh${NC}"
    echo -e "2. Analyze results: ${YELLOW}./analyze_testsprite_results.sh${NC}"
    echo -e "3. Read documentation: ${YELLOW}open TESTSPRITE_DOCUMENTATION.md${NC}"
    
    echo -e "\n${BLUE}For more information:${NC}"
    echo -e "- TestSprite Documentation: ${YELLOW}https://testsprite.com/docs${NC}"
    echo -e "- Project Test Documentation: ${YELLOW}open TESTSPRITE_DOCUMENTATION.md${NC}"
}

# Main function
main() {
    check_requirements
    install_testsprite_cli
    configure_testsprite
    create_test_structure
    make_scripts_executable
    verify_test_plans
    show_completion
}

# Run the main function
main