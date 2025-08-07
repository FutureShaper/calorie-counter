import SwiftUI

struct ContentView: View {
    @StateObject private var mlModelManager = MLModelManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @State private var selectedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var showingResults = false
    @State private var showingHealthKitAlert = false
    @State private var showingSettings = false
    @State private var savedToHealthKit = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("📱 Calorie Counter")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                Text("Take a photo of your food to analyze its nutrition content")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showingSettings = true
                            }) {
                                Image(systemName: "gear")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Photo Picker Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("📸 Capture Food Photo")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        PhotoPickerView(selectedImage: $selectedImage)
                    }
                    .padding(.horizontal)
                    
                    // Analysis Button
                    if selectedImage != nil {
                        Button(action: analyzeFood) {
                            HStack {
                                if isAnalyzing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "brain.head.profile")
                                }
                                Text(isAnalyzing ? "Analyzing..." : "Analyze Nutrition")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .disabled(isAnalyzing)
                        .padding(.horizontal)
                    }
                    
                    // Results Section
                    if let result = mlModelManager.lastResult {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("🥗 Nutrition Analysis")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            NutritionResultCard(result: result)
                            
                            // HealthKit Integration
                            VStack(spacing: 12) {
                                Text("💾 Save to Health App")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                if !healthKitManager.isAuthorized {
                                    Button(action: {
                                        Task {
                                            await healthKitManager.requestAuthorization()
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "heart.fill")
                                            Text("Enable HealthKit")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.red)
                                        .cornerRadius(8)
                                    }
                                } else {
                                    Button(action: saveToHealthKit) {
                                        HStack {
                                            Image(systemName: savedToHealthKit ? "checkmark.circle.fill" : "plus.circle.fill")
                                            Text(savedToHealthKit ? "Saved to Health" : "Save to Health")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(savedToHealthKit ? Color.green : Color.red)
                                        .cornerRadius(8)
                                    }
                                    .disabled(savedToHealthKit)
                                }
                                
                                Text("Authorization: \(healthKitManager.authorizationStatus)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Error Message
                    if let errorMessage = mlModelManager.errorMessage {
                        Text("⚠️ \(errorMessage)")
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            // Request HealthKit authorization on launch
            Task {
                await healthKitManager.requestAuthorization()
            }
        }
        .alert("Saved to Health App", isPresented: $showingHealthKitAlert) {
            Button("OK") { }
        } message: {
            Text("Your nutrition data has been saved to the Health app successfully.")
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    private func analyzeFood() {
        guard let image = selectedImage else { return }
        
        isAnalyzing = true
        savedToHealthKit = false
        
        Task {
            await mlModelManager.analyzeFood(image: image)
            await MainActor.run {
                isAnalyzing = false
                showingResults = true
            }
        }
    }
    
    private func saveToHealthKit() {
        guard let result = mlModelManager.lastResult else { return }
        
        Task {
            do {
                try await healthKitManager.saveNutritionData(result.nutritionData)
                await MainActor.run {
                    savedToHealthKit = true
                    showingHealthKitAlert = true
                }
            } catch {
                await MainActor.run {
                    mlModelManager.errorMessage = "Failed to save to Health app: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct NutritionResultCard: View {
    let result: FoodRecognitionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Food Recognition
            HStack {
                VStack(alignment: .leading) {
                    Text("Detected Food:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(result.recognizedFoodName)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Confidence:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(result.confidence * 100))%")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            
            Divider()
            
            // Nutrition Grid
            let nutritionData = result.nutritionData
            
            VStack(spacing: 8) {
                Text("Nutrition Information (per serving)")
                    .font(.headline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    NutritionItem(label: "Calories", value: "\(Int(nutritionData.calories))", unit: "kcal", color: .orange)
                    NutritionItem(label: "Protein", value: String(format: "%.1f", nutritionData.protein), unit: "g", color: .red)
                    NutritionItem(label: "Carbs", value: String(format: "%.1f", nutritionData.carbohydrates), unit: "g", color: .yellow)
                    NutritionItem(label: "Fats", value: String(format: "%.1f", nutritionData.fats), unit: "g", color: .purple)
                    NutritionItem(label: "Fiber", value: String(format: "%.1f", nutritionData.fiber), unit: "g", color: .green)
                    NutritionItem(label: "Timestamp", value: DateFormatter.shortTime.string(from: nutritionData.timestamp), unit: "", color: .blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct NutritionItem: View {
    let label: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

extension DateFormatter {
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    ContentView()
}