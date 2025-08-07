import Foundation
import UIKit

/// Service for interacting with OpenAI's Vision API to extract nutrition information from food images
class OpenAIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    /// Response structure from OpenAI API
    private struct OpenAIResponse: Codable {
        let choices: [Choice]
        
        struct Choice: Codable {
            let message: Message
            
            struct Message: Codable {
                let content: String
            }
        }
    }
    
    /// Expected JSON structure for nutrition data from OpenAI
    private struct OpenAINutritionResponse: Codable {
        let protein: Double
        let carbohydrates: Double
        let fats: Double
        let fiber: Double
        let foodName: String
        let confidence: Double
    }
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    /// Analyzes a food image using OpenAI's vision model and extracts macro nutrients
    /// - Parameter image: The food image to analyze
    /// - Returns: FoodRecognitionResult with extracted nutrition data
    func analyzeFood(image: UIImage) async throws -> FoodRecognitionResult {
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw OpenAIError.imageProcessingError
        }
        
        let base64Image = imageData.base64EncodedString()
        
        // Create the request payload
        let payload = createRequestPayload(base64Image: base64Image)
        
        // Make API request
        let response = try await makeAPIRequest(payload: payload)
        
        // Parse the response
        return try parseNutritionResponse(response)
    }
    
    private func createRequestPayload(base64Image: String) -> [String: Any] {
        let prompt = """
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
        
        return [
            "model": "gpt-4-vision-preview",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 300,
            "temperature": 0.1
        ]
    }
    
    private func makeAPIRequest(payload: [String: Any]) async throws -> OpenAIResponse {
        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            throw OpenAIError.serializationError
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OpenAIError.apiError(statusCode: httpResponse.statusCode)
        }
        
        do {
            return try JSONDecoder().decode(OpenAIResponse.self, from: data)
        } catch {
            throw OpenAIError.decodingError
        }
    }
    
    private func parseNutritionResponse(_ response: OpenAIResponse) throws -> FoodRecognitionResult {
        guard let content = response.choices.first?.message.content else {
            throw OpenAIError.emptyResponse
        }
        
        // Try to extract and validate JSON from the response
        let jsonString = extractJSON(from: content)
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw OpenAIError.invalidJSONResponse
        }
        
        do {
            let nutritionResponse = try JSONDecoder().decode(OpenAINutritionResponse.self, from: jsonData)
            
            // Additional validation of decoded values
            try validateNutritionValues(nutritionResponse)
            
            let nutritionData = NutritionData(
                protein: nutritionResponse.protein,
                carbohydrates: nutritionResponse.carbohydrates,
                fats: nutritionResponse.fats,
                fiber: nutritionResponse.fiber,
                foodName: nutritionResponse.foodName
            )
            
            return FoodRecognitionResult(
                confidence: nutritionResponse.confidence,
                nutritionData: nutritionData,
                recognizedFoodName: nutritionResponse.foodName
            )
        } catch let decodingError {
            // Provide more specific error information
            throw OpenAIError.nutritionParsingError(details: "Failed to decode nutrition JSON: \(decodingError.localizedDescription)")
        }
    }
    
    /// Validates that nutrition values are reasonable and within expected ranges
    private func validateNutritionValues(_ nutrition: OpenAINutritionResponse) throws {
        // Check for negative values
        guard nutrition.protein >= 0,
              nutrition.carbohydrates >= 0,
              nutrition.fats >= 0,
              nutrition.fiber >= 0 else {
            throw OpenAIError.nutritionParsingError(details: "Nutrition values cannot be negative")
        }
        
        // Check for unreasonably high values (per 1000g serving)
        guard nutrition.protein <= 1000,
              nutrition.carbohydrates <= 1000,
              nutrition.fats <= 1000,
              nutrition.fiber <= 1000 else {
            throw OpenAIError.nutritionParsingError(details: "Nutrition values exceed reasonable limits")
        }
        
        // Validate confidence range
        guard nutrition.confidence >= 0.0 && nutrition.confidence <= 1.0 else {
            throw OpenAIError.nutritionParsingError(details: "Confidence must be between 0.0 and 1.0")
        }
        
        // Validate food name is not empty
        guard !nutrition.foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OpenAIError.nutritionParsingError(details: "Food name cannot be empty")
        }
    }
    
    /// Attempts to extract and validate JSON from OpenAI response text.
    /// This method tries multiple approaches to find valid nutrition JSON:
    /// 1. Parse entire response as JSON
    /// 2. Find JSON-like patterns and validate them
    /// 3. Ensure extracted JSON has required nutrition fields
    private func extractJSON(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to parse the entire text as JSON first
        if isValidNutritionJSON(trimmed) {
            return trimmed
        }
        
        // If that fails, look for JSON patterns within the text
        let jsonCandidates = findJSONPatterns(in: text)
        
        // Validate each candidate and return the first valid one
        for candidate in jsonCandidates {
            if isValidNutritionJSON(candidate) {
                return candidate
            }
        }
        
        // Fallback: return the trimmed text and let downstream parsing handle the error
        return trimmed
    }
    
    /// Finds potential JSON patterns in text by looking for balanced braces
    /// Returns array of candidate JSON strings ordered by likelihood
    private func findJSONPatterns(in text: String) -> [String] {
        var candidates: [String] = []
        var braceCount = 0
        var startIndex: String.Index? = nil
        
        for (i, char) in text.enumerated() {
            let idx = text.index(text.startIndex, offsetBy: i)
            
            if char == "{" {
                if braceCount == 0 {
                    startIndex = idx
                }
                braceCount += 1
            } else if char == "}" {
                braceCount -= 1
                if braceCount == 0, let start = startIndex {
                    let candidate = String(text[start...idx])
                    candidates.append(candidate)
                    startIndex = nil
                }
            }
        }
        
        return candidates
    }
    
    /// Validates that a JSON string contains the expected nutrition data structure
    private func isValidNutritionJSON(_ jsonString: String) -> Bool {
        guard let jsonData = jsonString.data(using: .utf8) else {
            return false
        }
        
        do {
            // Try to parse as JSON object
            guard let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                return false
            }
            
            // Validate required fields exist and are of correct type
            let requiredFields = ["protein", "carbohydrates", "fats", "fiber", "foodName", "confidence"]
            
            for field in requiredFields {
                guard jsonObject[field] != nil else {
                    return false
                }
            }
            
            // Validate numeric fields are actually numbers
            let numericFields = ["protein", "carbohydrates", "fats", "fiber", "confidence"]
            for field in numericFields {
                guard let value = jsonObject[field], 
                      (value is Double || value is Int || value is NSNumber) else {
                    return false
                }
            }
            
            // Validate foodName is a string
            guard jsonObject["foodName"] is String else {
                return false
            }
            
            // Validate confidence is in valid range (0.0 to 1.0)
            if let confidence = jsonObject["confidence"] as? Double {
                guard confidence >= 0.0 && confidence <= 1.0 else {
                    return false
                }
            }
            
            // Additional validation: try to decode with our expected structure
            _ = try JSONDecoder().decode(OpenAINutritionResponse.self, from: jsonData)
            return true
            
        } catch {
            return false
        }
    }
}

/// Errors that can occur during OpenAI API interaction
enum OpenAIError: LocalizedError {
    case imageProcessingError
    case invalidURL
    case serializationError
    case networkError
    case apiError(statusCode: Int)
    case decodingError
    case emptyResponse
    case invalidJSONResponse
    case nutritionParsingError(details: String)
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingError:
            return "Failed to process the image"
        case .invalidURL:
            return "Invalid API URL"
        case .serializationError:
            return "Failed to serialize request data"
        case .networkError:
            return "Network request failed"
        case .apiError(let statusCode):
            return "API request failed with status code: \(statusCode)"
        case .decodingError:
            return "Failed to decode API response"
        case .emptyResponse:
            return "Received empty response from API"
        case .invalidJSONResponse:
            return "Invalid JSON response format"
        case .nutritionParsingError(let details):
            return "Failed to parse nutrition data: \(details)"
        }
    }
}