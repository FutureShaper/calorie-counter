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
        
        // Try to extract JSON from the response
        let jsonString = extractJSON(from: content)
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw OpenAIError.invalidJSONResponse
        }
        
        do {
            let nutritionResponse = try JSONDecoder().decode(OpenAINutritionResponse.self, from: jsonData)
            
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
        } catch {
            throw OpenAIError.nutritionParsingError
        }
    }
    
    private func extractJSON(from text: String) -> String {
        // Look for JSON object between braces
        let pattern = #"\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}"#
        
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            return String(text[Range(match.range, in: text)!])
        }
        
        // Fallback: return the entire text and hope it's valid JSON
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
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
    case nutritionParsingError
    
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
        case .nutritionParsingError:
            return "Failed to parse nutrition data"
        }
    }
}