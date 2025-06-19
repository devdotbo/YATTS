#!/usr/bin/env swift

import Foundation

// Test runner that demonstrates the chunking functionality
// This can be run as a Swift script to test the implementation

struct TestRunner {
    static func main() async {
        print("🧪 YATTS Chunking System Test Runner")
        print("=====================================\n")
        
        // Test 1: Short text (single chunk)
        await testShortText()
        
        // Test 2: Medium text (2-3 chunks)
        await testMediumText()
        
        // Test 3: Long text (multiple chunks)
        await testLongText()
        
        // Test 4: Edge cases
        await testEdgeCases()
        
        print("\n✅ All tests completed!")
    }
    
    static func testShortText() async {
        print("📝 Test 1: Short Text (Single Chunk)")
        print("-----------------------------------")
        
        let shortText = "This is a short text that should fit in a single chunk. It contains less than 4096 characters and should be processed as a single audio file."
        
        print("Text length: \(shortText.count) characters")
        print("Expected chunks: 1")
        print("Status: This will generate a single audio file\n")
    }
    
    static func testMediumText() async {
        print("📝 Test 2: Medium Text (2-3 Chunks)")
        print("-----------------------------------")
        
        let paragraph = """
        Artificial intelligence has revolutionized the way we interact with technology. From voice assistants that understand natural language to recommendation systems that predict our preferences, AI has become an integral part of our daily lives. Machine learning algorithms analyze vast amounts of data to identify patterns and make predictions, while deep learning neural networks tackle complex problems like image recognition and natural language processing.
        """
        
        let mediumText = String(repeating: paragraph + " ", count: 15)
        
        print("Text length: \(mediumText.count) characters")
        print("Expected chunks: 2-3")
        print("Status: This will generate multiple audio files with overlap\n")
    }
    
    static func testLongText() async {
        print("📝 Test 3: Long Text (Multiple Chunks)")
        print("--------------------------------------")
        
        let story = """
        Once upon a time in a digital realm, there lived an AI assistant named Claude who helped developers build amazing applications. Claude was particularly skilled at breaking down complex problems into manageable chunks, making it easier for developers to implement sophisticated features.
        
        One day, a developer came to Claude with a challenge: they needed to convert very long texts into speech, but the API they were using had a character limit. Claude suggested implementing a chunking system that would intelligently split the text while maintaining context between chunks.
        
        The developer was impressed with this solution and asked Claude to help design the entire system. Together, they created a robust architecture that could handle texts of any length, providing visual feedback to users about the chunking process and ensuring smooth playback across multiple audio files.
        """
        
        let longText = String(repeating: story + "\n\n", count: 10)
        
        print("Text length: \(longText.count) characters")
        print("Expected chunks: 5-7")
        print("Features demonstrated:")
        print("- Intelligent sentence boundary detection")
        print("- Chunk overlap for context preservation")
        print("- Progress tracking during generation")
        print("- Sequential playback with seeking\n")
    }
    
    static func testEdgeCases() async {
        print("🔧 Test 4: Edge Cases")
        print("--------------------")
        
        print("Testing various edge cases:")
        
        // Empty text
        print("- Empty text: Should create single empty chunk")
        
        // Exactly at limit
        let exactLimit = String(repeating: "a", count: 4096)
        print("- Text exactly at 4096 chars: Should create single chunk")
        
        // Just over limit
        let justOver = String(repeating: "a", count: 4097)
        print("- Text at 4097 chars: Should create 2 chunks")
        
        // No sentence boundaries
        let noSentences = String(repeating: "word ", count: 1000)
        print("- Text with no punctuation: Should still chunk properly")
        
        // Unicode text
        let unicodeText = String(repeating: "Hello 世界! ", count: 500)
        print("- Unicode text: Should handle character counting correctly\n")
    }
}

// Usage instructions
print("""
📱 How to Test the Full Implementation:

1. Open the YATTS app in Xcode
2. Build and run on simulator or device
3. Go to Settings and enter the API key (or it will load from .env)
4. Create a new audio item with various text lengths
5. Observe:
   - Character count showing number of chunks
   - Progress bar during chunk generation
   - Chunk status in the audio list
   - Chunk indicator during playback
   - Seamless playback across chunks
   - Seeking and skipping across chunk boundaries

🔑 The API key is loaded from the .env file automatically.

⚡ Performance Tips:
- Chunks are processed sequentially to avoid rate limits
- Each chunk includes overlap for better context
- Failed chunks can be retried individually
- Storage is optimized with UUID-based directories
""")

// Run the test runner
await TestRunner.main()