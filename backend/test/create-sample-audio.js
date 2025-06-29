const fs = require('fs');
const path = require('path');

// Create a simple test audio file (sine wave)
// This creates a minimal MP3-like file for testing
function createTestAudioFile() {
    const samplePath = path.join(__dirname, 'samples', 'sample-audio.mp3');
    
    // Create a minimal MP3 header (this is just for testing - not a real MP3)
    const mp3Header = Buffer.from([
        0xFF, 0xFB, 0x90, 0x00, // MP3 sync word and header
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    ]);
    
    // Create some dummy audio data (silence)
    const audioData = Buffer.alloc(1024 * 100, 0); // 100KB of silence
    
    // Combine header and data
    const testFile = Buffer.concat([mp3Header, audioData]);
    
    fs.writeFileSync(samplePath, testFile);
    console.log(`Created test audio file: ${samplePath}`);
    console.log(`File size: ${testFile.length} bytes`);
}

// Create the test file
createTestAudioFile();
