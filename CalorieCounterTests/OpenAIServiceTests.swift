import XCTest
@testable import CalorieCounter

/// Unit tests for OpenAI service integration
final class OpenAIServiceTests: XCTestCase {
    
    func testOpenAIServiceInitialization() {
        // Test that OpenAI service can be initialized with an API key
        let service = OpenAIService(apiKey: "test-key")
        XCTAssertNotNil(service)
    }
    
    func testMLModelManagerInitialization() {
        // Test that MLModelManager can be initialized
        let manager = MLModelManager()
        XCTAssertNotNil(manager)
        XCTAssertFalse(manager.isProcessing)
        XCTAssertNil(manager.lastResult)
        XCTAssertNil(manager.errorMessage)
    }
    
    func testFallbackToSimulationWhenNoAPIKey() async {
        // Test that MLModelManager falls back to simulation when no API key is configured
        let manager = MLModelManager()
        
        // Create a small test image
        let testImage = createTestImage()
        
        let result = await manager.analyzeFood(image: testImage)
        
        XCTAssertNotNil(result)
        XCTAssertNotNil(result?.nutritionData)
        XCTAssertGreaterThan(result?.confidence ?? 0, 0)
    }
    
    func testNutritionDataCalculation() {
        // Test that nutrition data calculates calories correctly
        let nutritionData = NutritionData(
            protein: 20.0,      // 20g * PROTEIN_CALORIES_PER_GRAM = 80 cal
            carbohydrates: 30.0, // 30g * CARBOHYDRATE_CALORIES_PER_GRAM = 120 cal
            fats: 10.0,         // 10g * FAT_CALORIES_PER_GRAM = 90 cal
            fiber: 5.0,         // 5g * FIBER_CALORIES_PER_GRAM = 10 cal
            foodName: "Test Food"
        )
        
        // Total expected calories: (20 * PROTEIN_CALORIES_PER_GRAM) + (30 * CARBOHYDRATE_CALORIES_PER_GRAM) + (10 * FAT_CALORIES_PER_GRAM) + (5 * FIBER_CALORIES_PER_GRAM)
        let expectedCalories = (20.0 * PROTEIN_CALORIES_PER_GRAM)
                            + (30.0 * CARBOHYDRATE_CALORIES_PER_GRAM)
                            + (10.0 * FAT_CALORIES_PER_GRAM)
                            + (5.0 * FIBER_CALORIES_PER_GRAM)
        XCTAssertEqual(nutritionData.calories, expectedCalories, accuracy: 0.1)
        XCTAssertEqual(nutritionData.protein, 20.0)
        XCTAssertEqual(nutritionData.carbohydrates, 30.0)
        XCTAssertEqual(nutritionData.fats, 10.0)
        XCTAssertEqual(nutritionData.fiber, 5.0)
        XCTAssertEqual(nutritionData.foodName, "Test Food")
    }
    
    func testOpenAIErrorDescriptions() {
        // Test that all OpenAI errors have descriptive messages
        let errors: [OpenAIError] = [
            .imageProcessingError,
            .invalidURL,
            .serializationError,
            .networkError,
            .apiError(statusCode: 401),
            .decodingError,
            .emptyResponse,
            .invalidJSONResponse,
            .nutritionParsingError
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
        }
    }
    
    private func createTestImage() -> UIImage {
        // Create a simple 1x1 pixel image for testing
        let size = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.red.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
}