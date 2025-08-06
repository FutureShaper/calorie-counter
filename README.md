# Calorie Counter iOS App

An iPhone iOS app that uses machine learning to analyze food photos and track macro nutrients in the Apple Health app.

## Features

- 📸 **Photo Capture**: Take pictures of food dishes using the camera or select from photo library
- 🧠 **ML-Powered Analysis**: Analyze food images to estimate macro nutrients (protein, carbohydrates, fats, fiber)
- 💾 **HealthKit Integration**: Automatically save nutrition data to Apple Health app
- 📱 **Native iOS**: Built with SwiftUI for modern iOS devices (iOS 17.0+)

## Technical Stack

- **Framework**: SwiftUI + UIKit
- **Machine Learning**: Core ML + Vision (currently using simulated data)
- **Health Integration**: HealthKit
- **Camera**: AVFoundation
- **Target**: iOS 17.0+, iPhone & iPad

## Project Structure

```
CalorieCounter/
├── CalorieCounterApp.swift      # Main app entry point
├── ContentView.swift            # Main UI view
├── CameraView.swift             # Camera and photo picker
├── NutritionModel.swift         # Data models for nutrition
├── MLModelManager.swift         # ML inference manager
├── HealthKitManager.swift       # HealthKit integration
├── Assets.xcassets/             # App icons and assets
└── Info.plist                  # App permissions and config
```

## Getting Started

### Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ device or simulator
- Apple Developer account (for device testing)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/FutureShaper/calorie-counter.git
   cd calorie-counter
   ```

2. Open the project in Xcode:
   ```bash
   open CalorieCounter.xcodeproj
   ```

3. Build and run the app:
   - Select your target device or simulator
   - Press Cmd+R to build and run

### Permissions

The app requires the following permissions:
- **Camera Access**: To take photos of food
- **HealthKit Access**: To read/write nutrition data

## Current Implementation

### ML Model (Simulated)
Currently uses simulated nutrition data for demonstration. The `MLModelManager` is designed to be easily replaceable with a real Core ML model.

To integrate a real model:
1. Train or obtain a food recognition Core ML model
2. Add the `.mlmodel` file to the project
3. Update `MLModelManager.loadCoreMLModel()` to load your model
4. Replace the simulation logic with actual inference

### Sample Nutrition Data
The app currently recognizes these sample foods:
- Grilled Chicken Breast
- Brown Rice Bowl
- Mixed Green Salad
- Salmon Fillet
- Quinoa Bowl
- Greek Yogurt
- Avocado Toast

## Architecture

### Core Components

1. **ContentView**: Main UI orchestrating photo capture, analysis, and health data saving
2. **PhotoPickerView**: Handles camera and photo library access
3. **MLModelManager**: Manages food recognition and nutrition estimation
4. **HealthKitManager**: Handles all HealthKit operations
5. **NutritionModel**: Data structures for nutrition information

### Data Flow

1. User takes/selects food photo
2. `MLModelManager` analyzes image → nutrition data
3. Results displayed in UI
4. User saves to Health app via `HealthKitManager`

## Future Enhancements

- [ ] Integration with real Core ML food recognition model
- [ ] Food database for improved nutrition accuracy
- [ ] Portion size estimation
- [ ] Meal tracking and history
- [ ] Nutritional goals and recommendations
- [ ] Barcode scanning for packaged foods
- [ ] Social sharing features

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on iOS devices
5. Submit a pull request

## License

This project is open source and available under the MIT License.