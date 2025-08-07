import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsManager = SettingsManager()
    @State private var apiKeyInput: String = ""
    @State private var showingAPIKeyInput = false
    @State private var showingDeleteConfirmation = false
    @State private var showingSuccessMessage = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "gear")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Settings")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Configure your API credentials and app preferences")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    
                    // OpenAI Configuration Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(
                            title: "🤖 OpenAI Configuration",
                            subtitle: "Configure your OpenAI API key for food analysis"
                        )
                        
                        ConfigurationCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("API Key Status")
                                            .font(.headline)
                                            .fontWeight(.medium)
                                        
                                        Text(settingsManager.openAIKeyStatus)
                                            .font(.subheadline)
                                            .foregroundColor(settingsManager.isOpenAIConfigured ? .green : .orange)
                                    }
                                    
                                    Spacer()
                                    
                                    StatusIndicator(isConfigured: settingsManager.isOpenAIConfigured)
                                }
                                
                                if settingsManager.isOpenAIConfigured {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Current Key:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text(settingsManager.getMaskedAPIKey())
                                            .font(.system(.body, design: .monospaced))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                }
                                
                                // Action buttons
                                HStack(spacing: 12) {
                                    Button(action: {
                                        showingAPIKeyInput = true
                                    }) {
                                        HStack {
                                            Image(systemName: settingsManager.isOpenAIConfigured ? "pencil" : "plus")
                                            Text(settingsManager.isOpenAIConfigured ? "Update Key" : "Add Key")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                    }
                                    
                                    if settingsManager.isOpenAIConfigured {
                                        Button(action: {
                                            showingDeleteConfirmation = true
                                        }) {
                                            HStack {
                                                Image(systemName: "trash")
                                                Text("Remove")
                                            }
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.red)
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Instructions
                        InstructionCard(
                            title: "How to get your OpenAI API Key",
                            steps: [
                                "Visit platform.openai.com",
                                "Sign in to your account",
                                "Go to API Keys section",
                                "Create a new API key",
                                "Copy and paste it here"
                            ]
                        )
                    }
                    .padding(.horizontal)
                    
                    // Future Configuration Sections
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(
                            title: "🔮 Future Enhancements",
                            subtitle: "Additional configuration options coming soon"
                        )
                        
                        ConfigurationCard {
                            VStack(alignment: .leading, spacing: 12) {
                                FeatureComingSoon(
                                    icon: "server.rack",
                                    title: "Custom API Endpoints",
                                    description: "Configure custom API endpoints for enhanced flexibility"
                                )
                                
                                Divider()
                                
                                FeatureComingSoon(
                                    icon: "lock.shield",
                                    title: "Additional Security",
                                    description: "Biometric authentication for sensitive operations"
                                )
                                
                                Divider()
                                
                                FeatureComingSoon(
                                    icon: "cloud",
                                    title: "Cloud Sync",
                                    description: "Sync settings across your devices securely"
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Error Message
                    if let errorMessage = settingsManager.errorMessage {
                        ErrorCard(message: errorMessage) {
                            settingsManager.errorMessage = nil
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAPIKeyInput) {
            APIKeyInputView(
                currentKey: settingsManager.getOpenAIAPIKey() ?? "",
                onSave: { newKey in
                    settingsManager.saveOpenAIAPIKey(newKey)
                    if settingsManager.errorMessage == nil {
                        showingSuccessMessage = true
                    }
                }
            )
        }
        .alert("Remove API Key", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                settingsManager.deleteOpenAIAPIKey()
            }
        } message: {
            Text("Are you sure you want to remove your OpenAI API key? You'll need to enter it again to use AI-powered analysis.")
        }
        .alert("Success", isPresented: $showingSuccessMessage) {
            Button("OK") { }
        } message: {
            Text("Your API key has been saved securely.")
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ConfigurationCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct StatusIndicator: View {
    let isConfigured: Bool
    
    var body: some View {
        Image(systemName: isConfigured ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
            .foregroundColor(isConfigured ? .green : .orange)
            .font(.title2)
    }
}

struct InstructionCard: View {
    let title: String
    let steps: [String]
    
    var body: some View {
        ConfigurationCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                            
                            Text(step)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.leading, 8)
            }
        }
    }
}

struct FeatureComingSoon: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.gray)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("Soon")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(4)
        }
    }
}

struct ErrorCard: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .foregroundColor(.red)
                .font(.subheadline)
            
            Spacer()
            
            Button("Dismiss") {
                onDismiss()
            }
            .foregroundColor(.red)
            .font(.caption)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

struct APIKeyInputView: View {
    let currentKey: String
    let onSave: (String) -> Void
    
    @State private var apiKey: String = ""
    @State private var isSecure: Bool = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("OpenAI API Key")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your OpenAI API key to enable AI-powered food analysis")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("API Key")
                        .font(.headline)
                    
                    HStack {
                        Group {
                            if isSecure {
                                SecureField("sk-...", text: $apiKey)
                            } else {
                                TextField("sk-...", text: $apiKey)
                            }
                        }
                        .font(.system(.body, design: .monospaced))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: {
                            isSecure.toggle()
                        }) {
                            Image(systemName: isSecure ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Text("Your API key will be stored securely in the iOS Keychain")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    onSave(apiKey)
                    dismiss()
                }) {
                    Text("Save API Key")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(apiKey.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(apiKey.isEmpty)
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            apiKey = currentKey
        }
    }
}

#Preview {
    SettingsView()
}