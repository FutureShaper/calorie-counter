# Calorie Counter iOS App

An iPhone iOS app that uses machine learning to analyze food photos and track macro nutrients in the Apple Health app.

## Features

- 📸 **Photo Capture**: Take pictures of food dishes using the camera or select from photo library
- 🧠 **ML-Powered Analysis**: Analyze food images to estimate macro nutrients (protein, carbohydrates, fats, fiber)
- 💾 **HealthKit Integration**: Automatically save nutrition data to Apple Health app
- 🔐 **Secure Configuration**: In-app secure storage for OpenAI API keys using iOS Keychain
- 📱 **Native iOS**: Built with SwiftUI for modern iOS devices (iOS 17.0+)

## Technical Stack

- **Framework**: SwiftUI + UIKit
- **Machine Learning**: OpenAI GPT-4 Vision API (with Core ML fallback support)
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
├── OpenAIService.swift          # OpenAI API integration
├── SecureCredentialsManager.swift # Secure credential storage
├── SettingsManager.swift        # App settings coordination
├── SettingsView.swift           # Settings UI configuration
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

3. Configure OpenAI API key:
   
   **Option A: In-App Configuration (Recommended for Production)**
   - Build and run the app
   - Tap the Settings gear icon (⚙️) in the top-right
   - Follow the in-app instructions to securely store your API key
   
   **Option B: Development Configuration**
   ```bash
   export OPENAI_API_KEY="your-api-key-here"
   ```
   
   See [SECURE_CONFIGURATION.md](SECURE_CONFIGURATION.md) for detailed setup options.

4. Build and run the app:
   - Select your target device or simulator
   - Press Cmd+R to build and run

## Detailed Xcode Import and Setup Guide

### Step-by-Step Xcode Setup

#### 1. Import Project into Xcode

**Option A: Using Xcode Welcome Screen**
1. Launch Xcode from Applications or Spotlight
2. If the Welcome screen appears, click "Open a project or file"
3. Navigate to your cloned repository folder
4. Select `CalorieCounter.xcodeproj` and click "Open"

**Option B: Using Xcode File Menu**
1. Open Xcode
2. Go to File → Open...
3. Navigate to the project directory
4. Select `CalorieCounter.xcodeproj` and click "Open"

**Option C: Using Finder**
1. In Finder, navigate to the cloned repository
2. Double-click on `CalorieCounter.xcodeproj`
3. Xcode will automatically launch and open the project

#### 2. Project Configuration

Once the project opens in Xcode:

1. **Select the Project Target**:
   - In the Project Navigator (left panel), click on "CalorieCounter" (the top-level project)
   - Select the "CalorieCounter" target under "TARGETS"

2. **Configure Signing & Capabilities**:
   - Click on the "Signing & Capabilities" tab
   - Select your development team from the "Team" dropdown
   - Ensure "Automatically manage signing" is checked
   - Your Bundle Identifier should be unique (e.g., `com.yourname.CalorieCounter`)

3. **Verify Deployment Target**:
   - In "General" tab, ensure "Deployment Target" is set to iOS 17.0 or later
   - Check that the iOS version matches your target device/simulator

#### 3. API Key Configuration

Choose one of these methods to configure your OpenAI API key:

**Method A: Environment Variable (Recommended)**
1. In Xcode, go to Product → Scheme → Edit Scheme...
2. Select "Run" in the left panel
3. Click on "Arguments" tab
4. Under "Environment Variables", click "+"
5. Set Name: `OPENAI_API_KEY` and Value: `your-actual-api-key`

**Method B: Build Settings**
1. Select your project target
2. Go to "Build Settings" tab
3. Click "+" and choose "Add User-Defined Setting"
4. Name: `OPENAI_API_KEY`, Value: `your-actual-api-key`

**Method C: Xcode Configuration File** (Advanced)
1. Create a new file: File → New → File...
2. Choose "Configuration Settings File" under iOS
3. Name it `Config.xcconfig`
4. Add: `OPENAI_API_KEY = your-actual-api-key`
5. Link it to your target in Build Settings

#### 4. Build and Run

1. **Select Target Device**:
   - Click the device/simulator selector next to the stop button
   - Choose either:
     - A connected iOS device (requires Apple Developer account)
     - An iOS Simulator (iPhone 15, iPad, etc.)

2. **Build the Project**:
   - Press Cmd+B to build
   - Wait for build to complete (check for any errors in the Issue Navigator)

3. **Run the App**:
   - Press Cmd+R to build and run
   - Or click the Play button (▶️) in the toolbar

#### 5. First Launch Setup

When the app first launches:

1. **Grant Camera Permission**:
   - Tap "Allow" when prompted for camera access
   - Required for taking food photos

2. **Grant HealthKit Permission**:
   - Tap "Allow All" for nutrition data access
   - Required for saving macro nutrients to Apple Health

3. **Test the App**:
   - Tap the camera button to take a photo
   - Verify API integration is working
   - Check that nutrition data appears after analysis

### Troubleshooting Common Issues

#### Build Errors

**"No such module 'UIKit'" or similar**:
- Ensure iOS Deployment Target is set correctly (iOS 17.0+)
- Clean build folder: Product → Clean Build Folder (Cmd+Shift+K)

**Code Signing Issues**:
- Verify your Apple ID is added: Xcode → Preferences → Accounts
- Select your development team in Signing & Capabilities
- Try changing Bundle Identifier to something unique

**API Key Not Working**:
- Verify the API key is set correctly in your chosen configuration method
- Check the OpenAI API key is valid in your OpenAI dashboard
- Ensure you have sufficient API credits

#### Simulator Issues

**Simulator Not Starting**:
- Restart Xcode and try again
- Reset Simulator: Device → Erase All Content and Settings
- Try a different simulator device

**Camera Not Available in Simulator**:
- The camera functionality requires a physical device
- Use photo library option instead for testing in simulator

#### Device Deployment Issues

**"App installation failed"**:
- Ensure device is connected and trusted
- Verify your Apple Developer account has device provisioning
- Check that iOS version on device matches deployment target

**"Untrusted Developer"**:
- On device: Settings → General → VPN & Device Management
- Trust your developer certificate

### Additional Xcode Tips

- **Use Simulator for Initial Testing**: Test basic functionality without needing a physical device
- **Enable Automatic Signing**: Simplifies certificate management for development
- **Check Console Output**: Use Xcode's console to debug API calls and app behavior
- **Breakpoint Debugging**: Set breakpoints in Swift code to step through logic
- **Preview in Xcode**: Use SwiftUI previews for rapid UI development

### Permissions

The app requires the following permissions:
- **Camera Access**: To take photos of food
- **HealthKit Access**: To read/write nutrition data

## Current Implementation

### OpenAI Vision Integration
The app now uses OpenAI's GPT-4 Vision model to analyze food images and extract macro nutrient information:
- Sends food photos to OpenAI's vision API
- Uses an optimized prompt to extract protein, carbohydrates, fats, and fiber amounts
- Receives structured JSON responses with nutrition data
- Falls back to simulated data if API is unavailable

### API Configuration
- **Secure In-App Configuration**: Users can configure API keys through a native settings interface
- **iOS Keychain Integration**: Credentials stored securely using iOS Keychain Services
- **Multiple Configuration Methods**: Supports Keychain, environment variables, and build settings
- **Graceful Fallback**: Falls back to simulated data when API is not available
- See [SECURE_CONFIGURATION.md](SECURE_CONFIGURATION.md) for complete setup guide

### Legacy ML Support (Available for Extension)
The `MLModelManager` is designed to be easily extended with Core ML models:
1. Add a trained Core ML model file to the project
2. Update `loadCoreMLModel()` to load your model
3. Implement local inference alongside OpenAI integration

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