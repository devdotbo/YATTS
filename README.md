# YATTS - Yet Another Text-to-Speech iOS App


https://github.com/user-attachments/assets/1dcbace2-7fbd-416a-a9db-3f07bff890bd

https://github.com/user-attachments/assets/3ca0d8e7-0847-429a-ae60-35086b03e2c3

A SwiftUI iOS app that converts text to speech using OpenAI's TTS API with offline playback support.

## Features






- ✅ Convert text to speech using OpenAI's TTS API
- ✅ SwiftData for persistent storage
- ✅ Offline audio playback - files stored locally
- ✅ Resume playback from last position
- ✅ Background audio support
- ✅ 15-second skip forward/backward
- ✅ Swipe-to-delete with confirmation
- ✅ Multiple voice and model options
- ✅ Storage management

## Setup Instructions

### 1. Configure Minimum iOS Version

1. Select your project in the navigator
2. Select the YATTS target
3. Under "Minimum Deployments", set iOS to 17.0

### 2. Add Background Audio Capability

1. Select your project in the navigator
2. Select the YATTS target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability"
5. Add "Background Modes"
6. Check "Audio, AirPlay, and Picture in Picture"

### 3. Get OpenAI API Key

1. Go to https://platform.openai.com/api-keys
2. Create a new API key
3. Copy the key

### 4. Run the App

1. Build and run the app on your device or simulator
2. Go to Settings tab
3. Enter your OpenAI API key
4. Tap "Validate API Key" to verify it works
5. Go to Library tab
6. Tap "+" to add new text
7. Paste or type your text
8. Tap "Generate Audio"

## Usage

### Creating Audio
- Tap the "+" button in the Library
- Paste or type your text (supports large texts)
- Tap "Generate Audio"
- Audio will be saved locally for offline playback

### Playing Audio
- Tap any item in the library to play
- Use play/pause button
- Skip 15 seconds forward/backward
- Progress is automatically saved

### Managing Audio
- Swipe left on any item to delete
- Confirm deletion when prompted
- Check total storage in Settings

### Settings
- Configure OpenAI API key
- Choose voice (alloy, echo, fable, onyx, nova, shimmer)
- Select model (tts-1 or tts-1-hd)
- View total storage used
- Clear all data if needed

## Architecture

- **SwiftUI** for UI
- **SwiftData** for persistence
- **AVFoundation** for audio playback
- **MVVM** architecture pattern
- **URLSession** for OpenAI API integration

## Requirements

- iOS 17.0+
- Xcode 15.0+
- OpenAI API key with TTS access

## Notes

- Audio files are stored in the app's Documents directory
- Files persist across app launches
- Background audio playback is supported
- All data is stored locally on device
