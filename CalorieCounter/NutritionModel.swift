import Foundation

/// Represents nutritional information for a food item
struct NutritionData: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let protein: Double // grams
    let carbohydrates: Double // grams
    let fats: Double // grams
    let fiber: Double // grams
    let calories: Double
    let foodName: String?
    
    init(protein: Double, carbohydrates: Double, fats: Double, fiber: Double, foodName: String? = nil) {
        self.timestamp = Date()
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fats = fats
        self.fiber = fiber
        self.foodName = foodName
        
        // Calculate calories: 4 cal/g for protein and carbs, 9 cal/g for fats, 2 cal/g for fiber
        self.calories = (protein * 4) + (carbohydrates * 4) + (fats * 9) + (fiber * 2)
    }
}

/// Represents the result of food recognition and nutrition estimation
struct FoodRecognitionResult {
    let confidence: Double
    let nutritionData: NutritionData
    let recognizedFoodName: String
}