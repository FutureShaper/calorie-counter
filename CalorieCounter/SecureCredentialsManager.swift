import Foundation
import Security

/// Manager for securely storing and retrieving credentials using iOS Keychain
class SecureCredentialsManager {
    
    // MARK: - Constants
    
    private static let serviceName = "CalorieCounterApp"
    private static let openAIAPIKeyAccount = "openai_api_key"
    
    // MARK: - Keychain Operations
    
    /// Stores the OpenAI API key securely in the Keychain
    /// - Parameter apiKey: The API key to store
    /// - Throws: KeychainError if the operation fails
    static func storeOpenAIAPIKey(_ apiKey: String) throws {
        try storeCredential(apiKey, account: openAIAPIKeyAccount)
    }
    
    /// Retrieves the OpenAI API key from the Keychain
    /// - Returns: The stored API key, or nil if not found
    /// - Throws: KeychainError if the operation fails
    static func getOpenAIAPIKey() throws -> String? {
        return try getCredential(account: openAIAPIKeyAccount)
    }
    
    /// Deletes the OpenAI API key from the Keychain
    /// - Throws: KeychainError if the operation fails
    static func deleteOpenAIAPIKey() throws {
        try deleteCredential(account: openAIAPIKeyAccount)
    }
    
    /// Checks if an OpenAI API key is stored in the Keychain
    /// - Returns: true if a key exists, false otherwise
    static func hasOpenAIAPIKey() -> Bool {
        do {
            return try getOpenAIAPIKey() != nil
        } catch {
            return false
        }
    }
    
    // MARK: - Generic Keychain Operations
    
    /// Stores a credential securely in the Keychain
    /// - Parameters:
    ///   - credential: The credential to store
    ///   - account: The account identifier
    /// - Throws: KeychainError if the operation fails
    private static func storeCredential(_ credential: String, account: String) throws {
        guard let data = credential.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        // First, try to update if the item already exists
        let updateQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
        
        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        
        if updateStatus == errSecSuccess {
            return // Successfully updated
        } else if updateStatus == errSecItemNotFound {
            // Item doesn't exist, so add it
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: account,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            
            if addStatus != errSecSuccess {
                throw KeychainError.storageError(addStatus)
            }
        } else {
            throw KeychainError.storageError(updateStatus)
        }
    }
    
    /// Retrieves a credential from the Keychain
    /// - Parameter account: The account identifier
    /// - Returns: The stored credential, or nil if not found
    /// - Throws: KeychainError if the operation fails
    private static func getCredential(account: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        } else if status == errSecSuccess {
            guard let data = result as? Data,
                  let credential = String(data: data, encoding: .utf8) else {
                throw KeychainError.invalidData
            }
            return credential
        } else {
            throw KeychainError.retrievalError(status)
        }
    }
    
    /// Deletes a credential from the Keychain
    /// - Parameter account: The account identifier
    /// - Throws: KeychainError if the operation fails
    private static func deleteCredential(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.deletionError(status)
        }
    }
}

/// Errors that can occur during Keychain operations
enum KeychainError: LocalizedError {
    case invalidData
    case storageError(OSStatus)
    case retrievalError(OSStatus)
    case deletionError(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data format for Keychain storage"
        case .storageError(let status):
            return "Failed to store credential in Keychain (status: \(status))"
        case .retrievalError(let status):
            return "Failed to retrieve credential from Keychain (status: \(status))"
        case .deletionError(let status):
            return "Failed to delete credential from Keychain (status: \(status))"
        }
    }
}