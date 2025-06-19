# Audio Chunking Architecture

## Overview
To support texts longer than 4096 characters, we'll implement a chunking system that:
- Splits long texts into manageable chunks
- Downloads each chunk separately with progress tracking
- Stores multiple audio files per item
- Plays chunks seamlessly in sequence

## Architecture Changes

### 1. Data Models

#### AudioChunk (New Model)
```swift
@Model
final class AudioChunk {
    var id: UUID
    var index: Int  // 0-based chunk index
    var audioFilePath: String
    var duration: TimeInterval
    var isDownloaded: Bool
    var audioItem: AudioItem?  // Parent relationship
}
```

#### AudioItem (Updated)
```swift
@Model
final class AudioItem {
    // Existing properties...
    var chunks: [AudioChunk]  // New: array of chunks
    var totalChunks: Int      // New: total expected chunks
    var downloadedChunks: Int  // New: count of downloaded chunks
    
    var isFullyDownloaded: Bool {
        downloadedChunks == totalChunks
    }
}
```

### 2. Service Layer

#### Text Chunking Strategy
- Split at sentence boundaries when possible
- Respect 4096 character limit with 100 char buffer
- Preserve paragraph structure
- Add overlap context (last sentence of previous chunk)

#### OpenAIService Updates
- `splitTextIntoChunks(text: String) -> [String]`
- `convertChunkToSpeech(chunk: String, index: Int) async throws -> Data`

#### FileStorageService Updates
- Store chunks as: `{itemId}/chunk_{index}.mp3`
- Delete all chunks when item is deleted

#### AudioPlayerService Updates
- Track current chunk index
- Auto-advance to next chunk
- Handle seek across chunks
- Calculate total duration across all chunks

### 3. UI/UX Flow

#### Generation Flow
1. User enters long text
2. Show "Analyzing text..." 
3. Display "Will create X chunks"
4. Show progress: "Generating chunk 1 of X..."
5. Update progress bar for each chunk
6. Allow cancellation mid-process

#### Playback Flow
1. Show current chunk: "Playing chunk 2 of 5"
2. Progress bar shows total progress across all chunks
3. Skip forward/backward works across chunks
4. Seamless transition between chunks

### 4. Error Handling
- Retry failed chunks individually
- Allow partial playback if some chunks exist
- Resume download from last successful chunk
- Handle API rate limits with exponential backoff

## Implementation Plan

### Phase 1: Data Model Updates
- Create AudioChunk model
- Update AudioItem with chunk support
- Create migration strategy

### Phase 2: Chunking Logic
- Implement smart text splitting
- Add chunk validation
- Create chunk metadata

### Phase 3: Download System
- Parallel chunk downloads
- Progress tracking
- Error recovery

### Phase 4: Playback System
- Sequential playback
- Cross-chunk seeking
- Position persistence

### Phase 5: UI Updates
- Progress indicators
- Chunk status display
- Error states

## Testing Strategy
- Unit tests for text splitting
- Integration tests for download flow
- UI tests for progress tracking
- Performance tests with large texts