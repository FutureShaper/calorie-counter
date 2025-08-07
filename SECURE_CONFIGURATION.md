# Secure Configuration Guide

This guide explains how to use the secure in-app configuration feature for managing OpenAI API keys and other credentials in production deployments.

## Overview

The Calorie Counter app now includes a secure configuration system that allows users to enter and manage their OpenAI API keys directly within the app. This eliminates the need for manual configuration files or environment variables in production deployments.

## Features

### 🔐 Secure Storage
- **iOS Keychain Integration**: All credentials are stored using iOS Keychain Services
- **Device-Only Access**: Keys are restricted to `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- **No Plain Text Storage**: Credentials never stored in UserDefaults, files, or logs

### ⚙️ User-Friendly Configuration
- **Native Settings UI**: Clean SwiftUI interface for credential management
- **Visual Status Indicators**: Clear indication of configuration status
- **Masked Display**: API keys shown as `sk-abc***..***xyz` for security
- **Input Validation**: Format validation for OpenAI API keys

### 🎯 Flexible Priority System
The app checks for API keys in this order:
1. **iOS Keychain** (primary for production)
2. **Environment Variables** (development/CI)
3. **Info.plist** (legacy support) 
4. **Hardcoded Values** (development only)

## User Guide

### Accessing Settings

1. **Open the App**: Launch the Calorie Counter app
2. **Tap Settings**: Look for the gear icon (⚙️) in the top-right of the main screen
3. **Settings Sheet**: The settings view will slide up from the bottom

### Configuring OpenAI API Key

#### Adding Your First API Key

1. **Open Settings**: Tap the gear icon in the main app
2. **Find OpenAI Section**: Look for "🤖 OpenAI Configuration"
3. **Check Status**: You'll see "Not configured" with an orange warning icon
4. **Tap "Add Key"**: This opens the API key input screen
5. **Enter Your Key**: Paste your OpenAI API key (starts with `sk-`)
6. **Save**: Tap "Save API Key" to store it securely
7. **Confirmation**: You'll see a success message

#### Getting an OpenAI API Key

1. Visit [platform.openai.com](https://platform.openai.com/)
2. Sign in to your account
3. Go to the API Keys section
4. Create a new API key
5. Copy the key and paste it in the app

#### Updating Your API Key

1. **Open Settings**: Tap the gear icon
2. **Current Status**: You'll see "Configured ✓" with a green checkmark
3. **View Masked Key**: Your key appears as `sk-abc***..***xyz`
4. **Tap "Update Key"**: Opens the input screen with your current key
5. **Enter New Key**: Replace with your new API key
6. **Save**: Tap "Save API Key" to update

#### Removing Your API Key

1. **Open Settings**: Tap the gear icon
2. **Tap "Remove"**: Red button next to "Update Key"
3. **Confirm**: Tap "Remove" in the confirmation dialog
4. **Status Reset**: Status returns to "Not configured"

### Configuration Status

The settings screen shows clear status indicators:

- **🟢 Configured ✓**: API key is stored and ready to use
- **🟠 Not configured**: No API key found
- **❌ Error**: Invalid key format or storage issue

## Developer Guide

### Architecture

#### SecureCredentialsManager
```swift
// Store API key securely
try SecureCredentialsManager.storeOpenAIAPIKey(apiKey)

// Retrieve API key
let apiKey = try SecureCredentialsManager.getOpenAIAPIKey()

// Check if key exists
let hasKey = SecureCredentialsManager.hasOpenAIAPIKey()

// Delete API key
try SecureCredentialsManager.deleteOpenAIAPIKey()
```

#### SettingsManager
```swift
@StateObject private var settingsManager = SettingsManager()

// Save with validation
settingsManager.saveOpenAIAPIKey(userInput)

// Get masked display version
let maskedKey = settingsManager.getMaskedAPIKey()

// Check configuration status
let isConfigured = settingsManager.isOpenAIConfigured
```

#### Integration with MLModelManager
```swift
// Updated priority order in getOpenAIAPIKey()
private func getOpenAIAPIKey() -> String? {
    // 1. Check Keychain (production)
    if let keychainKey = try? SecureCredentialsManager.getOpenAIAPIKey() {
        return keychainKey
    }
    
    // 2. Check environment variables (development)
    if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
        return envKey
    }
    
    // 3. Check Info.plist (legacy)
    // ... existing code
}
```

### Security Considerations

#### What's Protected
- ✅ API keys stored in iOS Keychain
- ✅ Keys restricted to device-only access
- ✅ No sensitive data in logs
- ✅ No sensitive data in configuration exports
- ✅ Input validation prevents malformed keys

#### What's Not Covered
- ⚠️ Network transmission security (handled by URLSession)
- ⚠️ API key rotation (manual process)
- ⚠️ Multi-device sync (future enhancement)

### Testing

#### Unit Tests
```swift
// Test secure storage
func testStoreAndRetrieveAPIKey() throws {
    let testKey = "sk-test1234567890abcdef"
    try SecureCredentialsManager.storeOpenAIAPIKey(testKey)
    let retrieved = try SecureCredentialsManager.getOpenAIAPIKey()
    XCTAssertEqual(retrieved, testKey)
}

// Test validation
func testSettingsManagerValidation() {
    let manager = SettingsManager()
    manager.saveOpenAIAPIKey("invalid-key")
    XCTAssertNotNil(manager.errorMessage)
    XCTAssertFalse(manager.isOpenAIConfigured)
}
```

#### Manual Testing
1. **Fresh Install**: Verify "Not configured" status
2. **Add Key**: Test adding valid OpenAI API key
3. **App Restart**: Verify key persists across launches
4. **Update Key**: Test updating to new key
5. **Remove Key**: Test deletion and status reset
6. **Invalid Input**: Test validation with malformed keys

## Migration Guide

### From Environment Variables
If you currently use environment variables:

1. **Keep Current Setup**: Environment variables still work
2. **Optional Migration**: Users can move to in-app config
3. **Priority Order**: Keychain takes precedence over environment variables

### From Info.plist Configuration
If you currently use Info.plist:

1. **Legacy Support**: Info.plist configuration still works
2. **Lower Priority**: Keychain and environment variables take precedence
3. **User Migration**: Users can configure in-app to override

## Troubleshooting

### Common Issues

#### "Failed to save API key"
- **Cause**: Keychain access denied or device locked
- **Solution**: Ensure device is unlocked and try again

#### "Invalid API key format"
- **Cause**: Key doesn't start with "sk-" or is too short
- **Solution**: Verify key copied correctly from OpenAI platform

#### "Not configured" despite adding key
- **Cause**: Key may not have saved properly
- **Solution**: Try removing and re-adding the key

### Debug Information

The app provides debug information through:
- SettingsManager error messages
- Console logging (development builds)
- Configuration export (excludes sensitive data)

## Future Enhancements

### Planned Features
- 🔮 **Custom API Endpoints**: Configure alternative API endpoints
- 🔮 **Biometric Authentication**: Require Face ID/Touch ID for sensitive operations
- 🔮 **Cloud Sync**: Sync settings across devices securely
- 🔮 **Multiple Credentials**: Support for additional API providers
- 🔮 **Automatic Key Rotation**: Scheduled key updates

### Contributing
To add new credential types:

1. Extend `SecureCredentialsManager` with new methods
2. Add validation to `SettingsManager`
3. Update `SettingsView` with new UI sections
4. Add corresponding unit tests

## Security Best Practices

### For Users
- 🔐 Keep your API keys confidential
- 🔄 Rotate keys regularly
- 📱 Use device lock screen protection
- ⚠️ Don't share screenshots of settings

### For Developers
- 🚫 Never commit real API keys to version control
- 🧪 Use test keys in development
- 🔍 Review Keychain access patterns
- 📊 Monitor API usage in OpenAI dashboard