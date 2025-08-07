import Foundation

// Caloric values per gram (kcal/g) for each macronutrient
let PROTEIN_CALORIES_PER_GRAM = 4.0      // Protein: 4 kcal/g
let CARBOHYDRATE_CALORIES_PER_GRAM = 4.0 // Carbohydrates: 4 kcal/g
let FAT_CALORIES_PER_GRAM = 9.0          // Fats: 9 kcal/g
let FIBER_CALORIES_PER_GRAM = 2.0        // Fiber: 2 kcal/g

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
        
        // Calculate calories using defined constants
        self.calories = (protein * PROTEIN_CALORIES_PER_GRAM) +
                       (carbohydrates * CARBOHYDRATE_CALORIES_PER_GRAM) +
                       (fats * FAT_CALORIES_PER_GRAM) +
                       (fiber * FIBER_CALORIES_PER_GRAM)
    }
}

/// Represents the result of food recognition and nutrition estimation
struct FoodRecognitionResult {
    let confidence: Double
    let nutritionData: NutritionData
    let recognizedFoodName: String
}