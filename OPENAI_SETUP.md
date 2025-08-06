# OpenAI API Configuration

This project now uses OpenAI's GPT-4 Vision model to analyze food images and extract macro nutrient information. To use this feature, you need to configure your OpenAI API key.

## Setup Methods

### Method 1: Environment Variable (Recommended for Development)
Set the `OPENAI_API_KEY` environment variable:

```bash
export OPENAI_API_KEY="your-api-key-here"
```

### Method 2: Xcode Build Configuration
1. In Xcode, select your project target
2. Go to Build Settings
3. Add a User-Defined Setting: `OPENAI_API_KEY = your-api-key-here`
4. The Info.plist is configured to read from `$(OPENAI_API_KEY)`

### Method 3: Direct Configuration (Development Only)
For quick testing, you can temporarily hardcode your API key in `MLModelManager.swift`:

```swift
// In getOpenAIAPIKey() method, uncomment and modify:
// return "your-api-key-here"
```

**⚠️ WARNING: Never commit real API keys to version control!**

## Getting an OpenAI API Key

1. Visit [OpenAI Platform](https://platform.openai.com/)
2. Sign up or log in to your account
3. Navigate to API Keys section
4. Create a new API key
5. Copy the key and configure it using one of the methods above

## API Usage and Costs

- The app uses GPT-4 Vision model (`gpt-4-vision-preview`)
- Each image analysis costs approximately $0.01-0.03 depending on image size
- Monitor your usage in the OpenAI dashboard
- Consider implementing rate limiting for production apps

## Fallback Behavior

If no API key is configured or the API call fails:
- The app will display a warning message
- It will fallback to the original simulated nutrition data
- Users can still use the app with mock data

## Privacy and Security

- API keys should be stored securely
- Images are sent to OpenAI for analysis
- Consider implementing local caching to reduce API calls
- Review OpenAI's data usage policy for production deployments