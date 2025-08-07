import Foundation
import Combine

/// Manager for app settings and configuration
@MainActor
class SettingsManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isOpenAIConfigured: Bool = false
    @Published var openAIKeyStatus: String = "Not configured"
    @Published var errorMessage: String?
    
    // MARK: - Initialization
    
    init() {
        updateConfigurationStatus()
    }
    
    // MARK: - OpenAI Configuration
    
    /// Saves the OpenAI API key securely
    /// - Parameter apiKey: The API key to save
    func saveOpenAIAPIKey(_ apiKey: String) {
        do {
            let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Validate API key format (basic validation)
            guard !trimmedKey.isEmpty else {
                errorMessage = "API key cannot be empty"
                return
            }
            
            guard trimmedKey.hasPrefix("sk-") && trimmedKey.count >= 20 else {
                errorMessage = "Invalid API key format. OpenAI keys should start with 'sk-' and be at least 20 characters long."
                return
            }
            
            try SecureCredentialsManager.storeOpenAIAPIKey(trimmedKey)
            updateConfigurationStatus()
            errorMessage = nil
            
        } catch {
            errorMessage = "Failed to save API key: \(error.localizedDescription)"
        }
    }
    
    /// Retrieves the stored OpenAI API key
    /// - Returns: The API key if available, nil otherwise
    func getOpenAIAPIKey() -> String? {
        do {
            return try SecureCredentialsManager.getOpenAIAPIKey()
        } catch {
            errorMessage = "Failed to retrieve API key: \(error.localizedDescription)"
            return nil
        }
    }
    
    /// Deletes the stored OpenAI API key
    func deleteOpenAIAPIKey() {
        do {
            try SecureCredentialsManager.deleteOpenAIAPIKey()
            updateConfigurationStatus()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to delete API key: \(error.localizedDescription)"
        }
    }
    
    /// Returns a masked version of the API key for display purposes
    /// - Returns: Masked API key string or status message
    func getMaskedAPIKey() -> String {
        guard let apiKey = getOpenAIAPIKey() else {
            return "Not configured"
        }
        
        // Show first 7 characters and last 4 characters with asterisks in between
        if apiKey.count > 15 {
            let start = String(apiKey.prefix(7))
            let end = String(apiKey.suffix(4))
            return "\(start)***..***\(end)"
        } else {
            return String(repeating: "*", count: apiKey.count)
        }
    }
    
    // MARK: - Configuration Status
    
    /// Updates the configuration status properties
    private func updateConfigurationStatus() {
        isOpenAIConfigured = SecureCredentialsManager.hasOpenAIAPIKey()
        openAIKeyStatus = isOpenAIConfigured ? "Configured ✓" : "Not configured"
    }
    
    /// Validates the current OpenAI configuration
    /// - Returns: true if configuration is valid, false otherwise
    func validateConfiguration() -> Bool {
        guard isOpenAIConfigured else {
            return false
        }
        
        guard let apiKey = getOpenAIAPIKey() else {
            return false
        }
        
        // Basic validation
        return !apiKey.isEmpty && apiKey.hasPrefix("sk-") && apiKey.count >= 20
    }
    
    // MARK: - Configuration Export/Import (Future Enhancement)
    
    /// Exports configuration for backup (excludes sensitive data)
    /// - Returns: Configuration dictionary
    func exportConfiguration() -> [String: Any] {
        return [
            "version": "1.0",
            "hasOpenAIKey": isOpenAIConfigured,
            "exportDate": ISO8601DateFormatter().string(from: Date())
        ]
    }
    
    /// Clears all stored configuration
    func clearAllConfiguration() {
        do {
            try SecureCredentialsManager.deleteOpenAIAPIKey()
            updateConfigurationStatus()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to clear configuration: \(error.localizedDescription)"
        }
    }
}