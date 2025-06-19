# YATTS Implementation Plan

## Phase 1: Project Setup & Core Models

### 1.1 Configure Xcode Project
- [ ] Set minimum iOS version to 17.0
- [ ] Enable SwiftData capability
- [ ] Add MacPaw/OpenAI package dependency
- [ ] Configure app capabilities for background audio

### 1.2 Create SwiftData Models
- [ ] Create `AudioItem` model with properties:
  - id: UUID
  - title: String
  - textContent: String
  - audioFilePath: String
  - duration: TimeInterval
  - lastPlaybackPosition: TimeInterval
  - createdAt: Date
  - fileSize: Int64
- [ ] Create `Settings` model with properties:
  - openAIAPIKey: String
  - selectedVoice: String (default: "alloy")
  - selectedModel: String (default: "tts-1")

## Phase 2: Service Layer Implementation

### 2.1 File Storage Service
- [ ] Implement `FileStorageService` class
- [ ] Create methods for:
  - saveAudioFile(data: Data, filename: String) -> URL
  - deleteAudioFile(at path: String)
  - getDocumentsDirectory() -> URL
  - calculateFileSize(at path: String) -> Int64

### 2.2 OpenAI Service
- [ ] Implement `OpenAIService` class
- [ ] Create text-to-speech method:
  - convertTextToSpeech(text: String, voice: String, model: String) async throws -> Data
- [ ] Add error handling for API failures
- [ ] Implement API key validation

### 2.3 Audio Player Service
- [ ] Implement `AudioPlayerService` class as ObservableObject
- [ ] Properties: currentItem, isPlaying, currentTime, duration
- [ ] Methods:
  - play(audioItem: AudioItem)
  - pause()
  - resume()
  - skip(seconds: Double)
  - seek(to time: TimeInterval)
- [ ] Configure AVAudioSession for background playback
- [ ] Add observers for playback interruptions

## Phase 3: ViewModels

### 3.1 AudioListViewModel
- [ ] Manage list of AudioItems
- [ ] Handle deletion with confirmation
- [ ] Sort items by creation date
- [ ] Calculate total storage used

### 3.2 AddItemViewModel
- [ ] Handle text input validation
- [ ] Show loading state during API call
- [ ] Generate title from first line of text
- [ ] Save audio file and create AudioItem

### 3.3 AudioPlayerViewModel
- [ ] Bridge between AudioPlayerService and UI
- [ ] Format time displays
- [ ] Handle play/pause state
- [ ] Save position on pause/background

## Phase 4: User Interface

### 4.1 Main Navigation Structure
- [ ] Create `ContentView` with TabView or NavigationStack
- [ ] Add navigation to settings

### 4.2 Audio List View
- [ ] Display list of AudioItems
- [ ] Show title, duration, and date
- [ ] Implement swipe-to-delete with confirmation alert
- [ ] Add empty state message
- [ ] Navigate to player on tap

### 4.3 Add Item View
- [ ] Large TextEditor for text input
- [ ] Character count display
- [ ] "Generate Audio" button
- [ ] Loading indicator during processing
- [ ] Error handling UI

### 4.4 Audio Player View
- [ ] Show current item title
- [ ] Play/pause button
- [ ] Progress slider
- [ ] Current time / total time labels
- [ ] 15-second skip button
- [ ] Volume control (optional)

### 4.5 Settings View
- [ ] SecureField for API key
- [ ] Voice selection picker
- [ ] Model selection picker
- [ ] Storage usage display
- [ ] Clear all data option

## Phase 5: App Lifecycle & Polish

### 5.1 Background Audio
- [ ] Configure Info.plist for background audio
- [ ] Handle scene phase changes
- [ ] Save playback position on background
- [ ] Resume from saved position

### 5.2 Error Handling
- [ ] Network error alerts
- [ ] API key validation
- [ ] Storage full warnings
- [ ] Graceful degradation

### 5.3 Performance Optimization
- [ ] Lazy loading of audio items
- [ ] Efficient file management
- [ ] Memory usage optimization

## Phase 6: Testing & Refinement

### 6.1 Unit Tests
- [ ] Test models
- [ ] Test services
- [ ] Test ViewModels

### 6.2 UI Tests
- [ ] Test main flows
- [ ] Test error states
- [ ] Test background behavior

### 6.3 Manual Testing Checklist
- [ ] Text input of various lengths
- [ ] API error handling
- [ ] Background playback
- [ ] App termination and restoration
- [ ] Storage management
- [ ] Settings persistence

## Technical Decisions

### Why MacPaw/OpenAI Package?
- Native Swift async/await support
- Proper error handling
- Well-maintained and documented
- Reduces boilerplate code
- Type-safe API

### Storage Strategy
- Documents directory for persistence across app updates
- UUID-based naming to avoid conflicts
- Automatic cleanup on item deletion
- Consider iCloud backup implications

### Audio Format
- MP3 for optimal size/quality balance
- Supported by AVAudioPlayer
- Good compression for speech

## Next Steps
1. Start with Phase 1.1 - Project setup
2. Implement models (Phase 1.2)
3. Build services bottom-up (Phase 2)
4. Create ViewModels with mock data (Phase 3)
5. Build UI incrementally (Phase 4)
6. Polish and test (Phase 5-6)