# TestSprite Integration for AgriSense iOS

*Documentation created: October 7, 2025*

## Overview

This document explains how to use TestSprite, an AI-powered automated testing tool, to test the AgriSense iOS application. TestSprite helps create and run comprehensive tests for your application, covering unit tests, UI tests, security validation, and performance analysis.

## Setup

### Prerequisites

- Xcode 16.0 or later
- macOS Sonoma or later
- Node.js 18+ (for TestSprite CLI)
- CocoaPods or Swift Package Manager

### Installation

1. Install TestSprite CLI:
   ```
   npm install -g testsprite-cli
   ```

2. Verify installation:
   ```
   testsprite --version
   ```

3. Configure TestSprite:
   ```
   testsprite configure
   ```
   
   When prompted, provide your TestSprite API key and select "iOS" as your platform.

## Test Configuration

The `testsprite_config.json` file in the project root defines all test configurations for your project. This file includes:

- Test suites and test cases
- Mock configurations
- CI integration settings
- Reporting preferences

You can modify this file to add or remove tests as needed.

## Running Tests

### Quick Run

To run all tests:

```
./run_testsprite.sh
```

This script will:
1. Install TestSprite CLI if needed
2. Clean previous test results
3. Run unit tests
4. Run UI tests
5. Generate coverage reports
6. Perform security validation
7. Run AI-powered tests
8. Analyze results

### Specific Test Suites

To run specific test suites, use:

```
testsprite run --suite=ModelTests
```

Replace `ModelTests` with the name of the test suite you want to run.

## Test Report Analysis

After running tests, analyze the results:

```
./analyze_testsprite_results.sh
```

This generates a comprehensive HTML report at `./test-reports/summary.html` that includes:

- Total test count and pass/fail statistics
- Unit test results
- UI test results
- Security analysis
- Performance metrics

## Continuous Integration

### GitHub Actions

The TestSprite configuration is compatible with GitHub Actions. Add this to your workflow file:

```yaml
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      - name: Install TestSprite
        run: npm install -g testsprite-cli
      - name: Run Tests
        run: ./run_testsprite.sh
      - name: Upload Test Results
        uses: actions/upload-artifact@v3
        with:
          name: test-reports
          path: ./test-reports
```

### Jenkins

For Jenkins CI, configure your pipeline to run:

```groovy
pipeline {
    agent { label 'macos' }
    stages {
        stage('Test') {
            steps {
                sh 'npm install -g testsprite-cli'
                sh './run_testsprite.sh'
            }
        }
        stage('Archive Reports') {
            steps {
                archiveArtifacts artifacts: 'test-reports/**/*', fingerprint: true
            }
        }
    }
}
```

## Creating New Tests

### Unit Tests

1. Create a new Swift file in `AgrisenseTests/` following the naming convention `*Tests.swift`
2. Use the Testing framework for modern tests or XCTest for traditional tests
3. Add the test to the appropriate test suite in `testsprite_config.json`

Example:

```swift
import Testing
@testable import Agrisense

struct NewFeatureTests {
    
    @Test func testFeatureInitialization() async throws {
        // Test code here
        #expect(true)
    }
}
```

### UI Tests

1. Create a new Swift file in `AgrisenseUITests/` following the naming convention `*UITests.swift`
2. Use XCTest and XCUITest for UI testing
3. Add the test to the UI test suite in `testsprite_config.json`

Example:

```swift
import XCTest

final class NewFeatureUITests: XCTestCase {
    func testFeatureUI() throws {
        let app = XCUIApplication()
        app.launch()
        
        // UI test code here
        XCTAssertTrue(app.buttons["Login"].exists)
    }
}
```

## Mocking with TestSprite

TestSprite provides AI-powered mocking capabilities. Configure mocks in the `mockConfig` section of `testsprite_config.json`:

```json
"mockConfig": {
  "enabled": true,
  "services": [
    {
      "name": "WeatherService",
      "mockResponses": [
        {
          "request": "getCurrentWeather",
          "response": {
            "status": "success",
            "data": {
              "temperature": 25.5,
              "humidity": 60,
              "conditions": "Partly Cloudy"
            }
          }
        }
      ]
    }
  ]
}
```

## Best Practices

1. **Run tests regularly**: Schedule daily or weekly test runs
2. **Update tests with features**: Add tests when adding new features
3. **Monitor test coverage**: Aim for >80% code coverage
4. **Test edge cases**: Include tests for error conditions
5. **Separate unit and UI tests**: Keep test types in their respective directories
6. **Use descriptive test names**: Name tests based on what they're testing
7. **Security first**: Always run security validation

## Troubleshooting

### Common Issues

1. **TestSprite CLI not found**:
   - Ensure Node.js is installed
   - Run `npm install -g testsprite-cli` manually

2. **Tests failing unexpectedly**:
   - Check the test logs in `./test-reports/`
   - Verify your API keys and credentials
   - Ensure Xcode Simulator is available

3. **Security validation warnings**:
   - Review the warnings in the security report
   - Fix any potential security issues before deploying

### Support

For TestSprite support:
- Documentation: https://testsprite.com/docs
- Community forum: https://community.testsprite.com
- Email support: support@testsprite.com

## Future Enhancements

1. Integrate performance profiling
2. Add accessibility testing
3. Implement A/B testing for UI flows
4. Expand security testing for API endpoints

---

*Note: TestSprite is an AI-powered tool, and results should always be reviewed by a developer before making critical decisions.*