#!/usr/bin/env swift

// Demo script to test OpenAI integration
// Usage: ./demo.swift [path-to-food-image]

import Foundation

// Mock classes for testing outside of Xcode
struct MockNutritionData {
    let protein: Double
    let carbohydrates: Double
    let fats: Double
    let fiber: Double
    let calories: Double
    let foodName: String?
    
    // Caloric values per gram (kcal/g) for each macronutrient
    private static let proteinCaloriesPerGram = 4.0      // Protein: 4 kcal/g
    private static let carbohydrateCaloriesPerGram = 4.0 // Carbohydrates: 4 kcal/g
    private static let fatCaloriesPerGram = 9.0          // Fats: 9 kcal/g
    private static let fiberCaloriesPerGram = 2.0        // Fiber: 2 kcal/g
    
    init(protein: Double, carbohydrates: Double, fats: Double, fiber: Double, foodName: String? = nil) {
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fats = fats
        self.fiber = fiber
        self.foodName = foodName
        self.calories =
            (protein * MockNutritionData.proteinCaloriesPerGram) +
            (carbohydrates * MockNutritionData.carbohydrateCaloriesPerGram) +
            (fats * MockNutritionData.fatCaloriesPerGram) +
            (fiber * MockNutritionData.fiberCaloriesPerGram)
    }
}

struct MockFoodRecognitionResult {
    let confidence: Double
    let nutritionData: MockNutritionData
    let recognizedFoodName: String
}

print("🍎 CalorieCounter OpenAI Integration Demo")
print("========================================")

// Test the prompt structure
let samplePrompt = """
Analyze this food image and extract the macro nutrient information. Return ONLY a valid JSON object with the following structure:

{
  "protein": <grams_of_protein_as_number>,
  "carbohydrates": <grams_of_carbohydrates_as_number>,
  "fats": <grams_of_fats_as_number>,
  "fiber": <grams_of_fiber_as_number>,
  "foodName": "<identified_food_name>",
  "confidence": <confidence_score_between_0_and_1>
}

Estimate the portion size based on visual cues in the image. Provide realistic macro nutrient values in grams for the visible portion. If you cannot clearly identify the food or estimate nutrition, return confidence < 0.5. Do not include any text outside of the JSON object.
"""

print("📝 OpenAI Prompt Structure:")
print(samplePrompt)
print("\n" + String(repeating: "=", count: 50) + "\n")

// Test JSON parsing
let sampleJSON = """
{
  "protein": 25.4,
  "carbohydrates": 0.0,
  "fats": 12.4,
  "fiber": 0.0,
  "foodName": "Grilled Salmon Fillet",
  "confidence": 0.89
}
"""

print("🧪 Testing JSON Parsing:")
print("Sample JSON Response:")
print(sampleJSON)

if let jsonData = sampleJSON.data(using: .utf8) {
    do {
        if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            let protein = json["protein"] as? Double ?? 0
            let carbs = json["carbohydrates"] as? Double ?? 0
            let fats = json["fats"] as? Double ?? 0
            let fiber = json["fiber"] as? Double ?? 0
            let foodName = json["foodName"] as? String ?? "Unknown"
            let confidence = json["confidence"] as? Double ?? 0
            
            let nutrition = MockNutritionData(
                protein: protein,
                carbohydrates: carbs,
                fats: fats,
                fiber: fiber,
                foodName: foodName
            )
            
            let result = MockFoodRecognitionResult(
                confidence: confidence,
                nutritionData: nutrition,
                recognizedFoodName: foodName
            )
            
            print("\n✅ Successfully parsed nutrition data:")
            print("   Food: \(result.recognizedFoodName)")
            print("   Confidence: \(Int(result.confidence * 100))%")
            print("   Protein: \(result.nutritionData.protein)g")
            print("   Carbohydrates: \(result.nutritionData.carbohydrates)g")
            print("   Fats: \(result.nutritionData.fats)g")
            print("   Fiber: \(result.nutritionData.fiber)g")
            print("   Calories: \(result.nutritionData.calories) kcal")
        }
    } catch {
        print("❌ JSON parsing failed: \(error)")
    }
} else {
    print("❌ Failed to convert string to data")
}

print("\n" + String(repeating: "=", count: 50))
print("🚀 Integration Complete!")
print("📚 See OPENAI_SETUP.md for API key configuration")
print("🔧 Build and run the iOS app to test with real images")