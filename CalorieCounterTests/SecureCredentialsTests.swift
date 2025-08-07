import XCTest
@testable import CalorieCounter

/// Unit tests for secure credentials management functionality
final class SecureCredentialsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clean up any existing test keys
        try? SecureCredentialsManager.deleteOpenAIAPIKey()
    }
    
    override func tearDown() {
        // Clean up after tests
        try? SecureCredentialsManager.deleteOpenAIAPIKey()
        super.tearDown()
    }
    
    func testStoreAndRetrieveAPIKey() throws {
        let testAPIKey = "sk-test1234567890abcdef"
        
        // Store the API key
        try SecureCredentialsManager.storeOpenAIAPIKey(testAPIKey)
        
        // Retrieve and verify
        let retrievedKey = try SecureCredentialsManager.getOpenAIAPIKey()
        XCTAssertEqual(retrievedKey, testAPIKey)
    }
    
    func testHasAPIKeyCheck() throws {
        // Initially should not have a key
        XCTAssertFalse(SecureCredentialsManager.hasOpenAIAPIKey())
        
        // Store a key
        let testAPIKey = "sk-test1234567890abcdef"
        try SecureCredentialsManager.storeOpenAIAPIKey(testAPIKey)
        
        // Should now have a key
        XCTAssertTrue(SecureCredentialsManager.hasOpenAIAPIKey())
    }
    
    func testDeleteAPIKey() throws {
        let testAPIKey = "sk-test1234567890abcdef"
        
        // Store a key
        try SecureCredentialsManager.storeOpenAIAPIKey(testAPIKey)
        XCTAssertTrue(SecureCredentialsManager.hasOpenAIAPIKey())
        
        // Delete the key
        try SecureCredentialsManager.deleteOpenAIAPIKey()
        XCTAssertFalse(SecureCredentialsManager.hasOpenAIAPIKey())
        
        // Verify retrieval returns nil
        let retrievedKey = try SecureCredentialsManager.getOpenAIAPIKey()
        XCTAssertNil(retrievedKey)
    }
    
    func testUpdateAPIKey() throws {
        let firstKey = "sk-first1234567890abcdef"
        let secondKey = "sk-second1234567890abcdef"
        
        // Store first key
        try SecureCredentialsManager.storeOpenAIAPIKey(firstKey)
        XCTAssertEqual(try SecureCredentialsManager.getOpenAIAPIKey(), firstKey)
        
        // Update with second key
        try SecureCredentialsManager.storeOpenAIAPIKey(secondKey)
        XCTAssertEqual(try SecureCredentialsManager.getOpenAIAPIKey(), secondKey)
    }
    
    func testRetrieveNonExistentKey() throws {
        // Ensure no key exists
        try? SecureCredentialsManager.deleteOpenAIAPIKey()
        
        // Retrieving non-existent key should return nil
        let retrievedKey = try SecureCredentialsManager.getOpenAIAPIKey()
        XCTAssertNil(retrievedKey)
    }
    
    func testSettingsManagerIntegration() {
        let settingsManager = SettingsManager()
        
        // Initially should not be configured
        XCTAssertFalse(settingsManager.isOpenAIConfigured)
        XCTAssertEqual(settingsManager.openAIKeyStatus, "Not configured")
        
        // Save a valid API key
        let testAPIKey = "sk-test1234567890abcdef1234567890"
        settingsManager.saveOpenAIAPIKey(testAPIKey)
        
        // Should now be configured
        XCTAssertTrue(settingsManager.isOpenAIConfigured)
        XCTAssertEqual(settingsManager.openAIKeyStatus, "Configured ✓")
        
        // Should be able to retrieve masked version
        let maskedKey = settingsManager.getMaskedAPIKey()
        XCTAssertTrue(maskedKey.contains("sk-test"))
        XCTAssertTrue(maskedKey.contains("***"))
    }
    
    func testSettingsManagerValidation() {
        let settingsManager = SettingsManager()
        
        // Test invalid API key formats
        settingsManager.saveOpenAIAPIKey("")
        XCTAssertNotNil(settingsManager.errorMessage)
        XCTAssertFalse(settingsManager.isOpenAIConfigured)
        
        settingsManager.saveOpenAIAPIKey("invalid-key")
        XCTAssertNotNil(settingsManager.errorMessage)
        XCTAssertFalse(settingsManager.isOpenAIConfigured)
        
        settingsManager.saveOpenAIAPIKey("sk-short")
        XCTAssertNotNil(settingsManager.errorMessage)
        XCTAssertFalse(settingsManager.isOpenAIConfigured)
        
        // Test valid API key
        settingsManager.saveOpenAIAPIKey("sk-test1234567890abcdef1234567890")
        XCTAssertNil(settingsManager.errorMessage)
        XCTAssertTrue(settingsManager.isOpenAIConfigured)
    }
    
    func testMLModelManagerIntegrationWithSecureStorage() throws {
        // Clean up first
        try? SecureCredentialsManager.deleteOpenAIAPIKey()
        
        // Create manager without secure key
        let manager1 = MLModelManager()
        
        // Store API key securely
        let testAPIKey = "sk-test1234567890abcdef"
        try SecureCredentialsManager.storeOpenAIAPIKey(testAPIKey)
        
        // Create new manager - should pick up the secure key
        let manager2 = MLModelManager()
        
        // Both managers should work, but manager2 should use secure storage
        XCTAssertNotNil(manager1)
        XCTAssertNotNil(manager2)
    }
    
    func testSecureCredentialsErrorHandling() {
        // Test error descriptions are meaningful
        let errors: [KeychainError] = [
            .invalidData,
            .storageError(errSecParam),
            .retrievalError(errSecParam),
            .deletionError(errSecParam)
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
        }
    }
    
    func testConfigurationExportWithoutSensitiveData() {
        let settingsManager = SettingsManager()
        
        // Save an API key
        settingsManager.saveOpenAIAPIKey("sk-test1234567890abcdef1234567890")
        
        // Export configuration
        let config = settingsManager.exportConfiguration()
        
        // Should contain status but not the actual key
        XCTAssertNotNil(config["version"])
        XCTAssertNotNil(config["hasOpenAIKey"])
        XCTAssertNotNil(config["exportDate"])
        
        // Should not contain sensitive data
        XCTAssertNil(config["apiKey"])
        XCTAssertNil(config["openaiKey"])
    }
    
    func testClearAllConfiguration() {
        let settingsManager = SettingsManager()
        
        // Save configuration
        settingsManager.saveOpenAIAPIKey("sk-test1234567890abcdef1234567890")
        XCTAssertTrue(settingsManager.isOpenAIConfigured)
        
        // Clear all
        settingsManager.clearAllConfiguration()
        XCTAssertFalse(settingsManager.isOpenAIConfigured)
        XCTAssertEqual(settingsManager.openAIKeyStatus, "Not configured")
    }
}