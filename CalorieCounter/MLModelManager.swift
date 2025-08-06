import Foundation
import UIKit
import CoreML
import Vision

class MLModelManager: ObservableObject {
    @Published var isProcessing = false
    @Published var lastResult: FoodRecognitionResult?
    @Published var errorMessage: String?
    
    private var openAIService: OpenAIService?
    
    init() {
        // Initialize OpenAI service with API key
        if let apiKey = getOpenAIAPIKey() {
            openAIService = OpenAIService(apiKey: apiKey)
        }
    }
    
    func analyzeFood(image: UIImage) async -> FoodRecognitionResult? {
        await MainActor.run {
            isProcessing = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isProcessing = false
            }
        }
        
        // Try OpenAI service first, fallback to simulation if not available
        if let service = openAIService {
            do {
                let result = try await service.analyzeFood(image: image)
                await MainActor.run {
                    lastResult = result
                }
                return result
            } catch {
                await MainActor.run {
                    errorMessage = "OpenAI analysis failed: \(error.localizedDescription)"
                }
                // Fallback to simulation
                return await fallbackToSimulation()
            }
        } else {
            await MainActor.run {
                errorMessage = "OpenAI API key not configured. Using simulated data."
            }
            return await fallbackToSimulation()
        }
    }
    
    private func fallbackToSimulation() async -> FoodRecognitionResult {
        // Simulate processing time
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let simulatedResult = generateSimulatedNutritionData()
        
        await MainActor.run {
            lastResult = simulatedResult
        }
        
        return simulatedResult
    }
    
    private func getOpenAIAPIKey() -> String? {
        // Priority order for API key:
        // 1. Environment variable
        // 2. Info.plist
        // 3. Hardcoded (for development only - not recommended for production)
        
        // Check environment variable
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // Check Info.plist
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let apiKey = plist["OpenAI_API_Key"] as? String, !apiKey.isEmpty {
            return apiKey
        }
        
        // For development/testing, you can temporarily hardcode your API key here
        // WARNING: Never commit real API keys to version control
        // return "your-api-key-here"
        
        return nil
    }
    
    private func generateSimulatedNutritionData() -> FoodRecognitionResult {
        // Simulate different food types with realistic nutrition values
        let foodTypes = [
            ("Grilled Chicken Breast", NutritionData(protein: 31.0, carbohydrates: 0.0, fats: 3.6, fiber: 0.0, foodName: "Grilled Chicken Breast")),
            ("Brown Rice Bowl", NutritionData(protein: 5.0, carbohydrates: 45.0, fats: 1.8, fiber: 3.5, foodName: "Brown Rice Bowl")),
            ("Mixed Green Salad", NutritionData(protein: 2.9, carbohydrates: 6.0, fats: 0.2, fiber: 2.0, foodName: "Mixed Green Salad")),
            ("Salmon Fillet", NutritionData(protein: 25.4, carbohydrates: 0.0, fats: 12.4, fiber: 0.0, foodName: "Salmon Fillet")),
            ("Quinoa Bowl", NutritionData(protein: 8.1, carbohydrates: 39.4, fats: 3.6, fiber: 5.2, foodName: "Quinoa Bowl")),
            ("Greek Yogurt", NutritionData(protein: 10.0, carbohydrates: 6.0, fats: 0.4, fiber: 0.0, foodName: "Greek Yogurt")),
            ("Avocado Toast", NutritionData(protein: 6.0, carbohydrates: 24.0, fats: 15.0, fiber: 10.0, foodName: "Avocado Toast"))
        ]
        
        let randomFood = foodTypes.randomElement()!
        let confidence = Double.random(in: 0.75...0.95) // Simulate model confidence
        
        return FoodRecognitionResult(
            confidence: confidence,
            nutritionData: randomFood.1,
            recognizedFoodName: randomFood.0
        )
    }
    
    // Method to load and use a real Core ML model (placeholder for future implementation)
    private func loadCoreMLModel() -> VNCoreMLModel? {
        // In a real implementation, you would:
        // 1. Add a trained Core ML model (.mlmodel file) to your project
        // 2. Load it here and return the VNCoreMLModel
        // 3. Use it in Vision requests to analyze food images
        
        // Example code (commented out as we don't have a real model):
        /*
        guard let model = try? YourFoodModel(configuration: MLModelConfiguration()) else {
            return nil
        }
        
        return try? VNCoreMLModel(for: model.model)
        */
        
        return nil
    }
}