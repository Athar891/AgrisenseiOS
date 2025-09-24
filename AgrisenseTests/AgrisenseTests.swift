//
//  AgrisenseTests.swift
//  AgrisenseTests
//
//  Created by Athar Reza on 09/08/25.
//

import Testing
@testable import Agrisense

struct AgrisenseTests {
    
    @Test func testUserManagerInitialization() async throws {
        let userManager = UserManager()
        #expect(userManager.currentUser == nil)
        #expect(!userManager.isAuthenticated)
    }
    
    @Test func testAppStateInitialization() async throws {
        let appState = AppState()
        #expect(!appState.isDarkMode)
    }
}
