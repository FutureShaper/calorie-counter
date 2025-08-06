import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    @Published var authorizationStatus: String = "Not Determined"
    
    init() {
        checkAuthorizationStatus()
    }
    
    // Check if HealthKit is available on the device
    func isHealthKitAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    // Request authorization to read and write nutrition data
    func requestAuthorization() async {
        guard isHealthKitAvailable() else {
            await updateAuthorizationStatus("HealthKit not available")
            return
        }
        
        // Define the types we want to read and write
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFiber)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFiber)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            await checkAuthorizationStatus()
        } catch {
            await updateAuthorizationStatus("Authorization failed: \(error.localizedDescription)")
        }
    }
    
    // Save nutrition data to HealthKit
    func saveNutritionData(_ nutritionData: NutritionData) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        let samples = createHealthKitSamples(from: nutritionData)
        
        try await saveSamples(samples)
    }
    
    // Helper to save multiple samples using async/await
    private func saveSamples(_ samples: [HKSample]) async throws {
        try await withCheckedThrowingContinuation { continuation in
            healthStore.save(samples) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitError.dataNotAvailable)
                }
            }
        }
    }
    
    // Create HealthKit samples from nutrition data
    private func createHealthKitSamples(from nutritionData: NutritionData) -> [HKQuantitySample] {
        var samples: [HKQuantitySample] = []
        
        // Calories
        if let caloriesType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            let caloriesQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: nutritionData.calories)
            let caloriesSample = HKQuantitySample(
                type: caloriesType,
                quantity: caloriesQuantity,
                start: nutritionData.timestamp,
                end: nutritionData.timestamp
            )
            samples.append(caloriesSample)
        }
        
        // Protein
        if let proteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) {
            let proteinQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: nutritionData.protein)
            let proteinSample = HKQuantitySample(
                type: proteinType,
                quantity: proteinQuantity,
                start: nutritionData.timestamp,
                end: nutritionData.timestamp
            )
            samples.append(proteinSample)
        }
        
        // Carbohydrates
        if let carbsType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) {
            let carbsQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: nutritionData.carbohydrates)
            let carbsSample = HKQuantitySample(
                type: carbsType,
                quantity: carbsQuantity,
                start: nutritionData.timestamp,
                end: nutritionData.timestamp
            )
            samples.append(carbsSample)
        }
        
        // Fats
        if let fatsType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) {
            let fatsQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: nutritionData.fats)
            let fatsSample = HKQuantitySample(
                type: fatsType,
                quantity: fatsQuantity,
                start: nutritionData.timestamp,
                end: nutritionData.timestamp
            )
            samples.append(fatsSample)
        }
        
        // Fiber
        if let fiberType = HKQuantityType.quantityType(forIdentifier: .dietaryFiber) {
            let fiberQuantity = HKQuantity(unit: HKUnit.gram(), doubleValue: nutritionData.fiber)
            let fiberSample = HKQuantitySample(
                type: fiberType,
                quantity: fiberQuantity,
                start: nutritionData.timestamp,
                end: nutritionData.timestamp
            )
            samples.append(fiberSample)
        }
        
        return samples
    }
    
    private func checkAuthorizationStatus() {
        Task { @MainActor in
            guard isHealthKitAvailable() else {
                authorizationStatus = "HealthKit not available"
                isAuthorized = false
                return
            }
            
            // Check authorization for each nutrition type
            let nutritionTypes: [HKQuantityTypeIdentifier] = [
                .dietaryEnergyConsumed,
                .dietaryProtein,
                .dietaryCarbohydrates,
                .dietaryFatTotal,
                .dietaryFiber
            ]
            
            let allAuthorized = nutritionTypes.allSatisfy { identifier in
                guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return false }
                return healthStore.authorizationStatus(for: type) == .sharingAuthorized
            }
            
            if allAuthorized {
                authorizationStatus = "Authorized"
                isAuthorized = true
            } else {
                authorizationStatus = "Not Authorized"
                isAuthorized = false
            }
        }
    }
    
    @MainActor
    private func updateAuthorizationStatus(_ status: String) {
        authorizationStatus = status
        isAuthorized = status == "Authorized"
    }
}

enum HealthKitError: Error, LocalizedError {
    case notAuthorized
    case dataNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "HealthKit access not authorized"
        case .dataNotAvailable:
            return "HealthKit data not available"
        }
    }
}