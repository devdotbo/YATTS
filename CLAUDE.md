# YATTS (Yet Another Text-to-Speech) iOS App

## Project Overview
A SwiftUI iOS app that converts text to speech using OpenAI's TTS API. Users can create, manage, and play audio files generated from text input.

## Key Features
- SwiftData for persistent storage
- Text-to-speech conversion via OpenAI API
- Audio playback with position tracking
- Swipe-to-delete with confirmation
- Large text input support
- 15-second skip forward
- Background playback support
- Settings for API key management

## Tech Stack
- SwiftUI
- SwiftData
- AVFoundation for audio playback
- MacPaw/OpenAI Swift package
- iOS 17.0+ minimum deployment target

## Dependencies
Add to Package.swift:
```
https://github.com/MacPaw/OpenAI.git
```

## Testing Commands
```bash
# Build the project
xcodebuild -scheme YATTS -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run SwiftLint (if installed)
swiftlint

# Run tests
xcodebuild test -scheme YATTS -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Project Structure
```
YATTS/
├── Models/
│   ├── AudioItem.swift
│   └── Settings.swift
├── Views/
│   ├── ContentView.swift
│   ├── AudioListView.swift
│   ├── AddItemView.swift
│   ├── AudioPlayerView.swift
│   └── SettingsView.swift
├── ViewModels/
│   ├── AudioListViewModel.swift
│   ├── AddItemViewModel.swift
│   └── AudioPlayerViewModel.swift
├── Services/
│   ├── OpenAIService.swift
│   ├── AudioPlayerService.swift
│   └── FileStorageService.swift
└── YATTSApp.swift
```

## Important Implementation Notes
- Store audio files in Documents directory
- Use UUID for unique file naming
- Save playback position in SwiftData
- Configure AVAudioSession for background playback
- Handle API key securely (never commit to repo)
- Implement proper error handling for network requests
- Clean up audio files when items are deleted

## API Configuration
- OpenAI TTS endpoint: https://api.openai.com/v1/audio/speech
- Default model: tts-1
- Default voice: alloy
- Output format: mp3