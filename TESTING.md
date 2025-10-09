# AgriSense iOS Testing with TestSprite

## Overview

This repository contains the AgriSense iOS application, an agricultural management platform for farmers, buyers, and suppliers. This README focuses on the testing infrastructure using TestSprite, an AI-powered automated testing tool.

## Quick Start

To set up TestSprite for testing:

```bash
# First-time setup
./setup_testsprite.sh

# Run all tests
./run_testsprite.sh

# Analyze test results
./analyze_testsprite.results.sh
```

## Test Structure

The testing suite is organized into the following components:

- **Unit Tests**: Located in `AgrisenseTests/` directory
- **UI Tests**: Located in `AgrisenseUITests/` directory
- **Test Plans**: `UnitTests.xctestplan` and `UITests.xctestplan`
- **TestSprite Configuration**: `testsprite_config.json`
- **Mock Data**: `testsprite_mock_data.json`

## Test Documentation

For comprehensive information about the testing setup, please refer to the [TestSprite Documentation](./TESTSPRITE_DOCUMENTATION.md).

## Key Features Tested

- **User Management**: Authentication, profile management, security
- **Crop Management**: Creating, updating, and deleting crops
- **Weather Services**: Data fetching and processing
- **Marketplace**: Product listings, orders, transactions
- **Security**: Input validation, secure storage, network security
- **UI Flows**: Navigation, forms, interactive elements

## Adding Tests

### Unit Tests

1. Create a new file in `AgrisenseTests/`
2. Import the Testing framework and the app module
3. Create a struct with test functions using the `@Test` macro
4. Add test to the appropriate suite in `testsprite_config.json`

Example:

```swift
import Testing
@testable import Agrisense

struct NewFeatureTests {
    @Test func testFeature() async throws {
        // Test code
    }
}
```

### UI Tests

1. Create a new file in `AgrisenseUITests/`
2. Use XCTest and XCUITest frameworks
3. Add test to UI test suite in `testsprite_config.json`

## Best Practices

- Run tests before submitting pull requests
- Keep tests independent and isolated
- Mock external dependencies
- Maintain high code coverage
- Follow naming conventions for test files and functions

## Continuous Integration

TestSprite is configured to run in CI environments:

- **GitHub Actions**: Tests run on every push and pull request
- **Jenkins**: Tests run on a scheduled basis (daily)

## Test Reports

After running tests, you can find comprehensive reports in:

- `./test-reports/summary.html`: Overall test summary
- `./test-reports/coverage/`: Code coverage reports
- `./test-reports/unit-tests.log`: Unit test detailed logs
- `./test-reports/ui-tests.log`: UI test detailed logs

## Need Help?

- See the detailed [TestSprite Documentation](./TESTSPRITE_DOCUMENTATION.md)
- Contact the project maintainers
- Visit [TestSprite Support](https://testsprite.com/support)