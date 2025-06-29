const fs = require('fs');
const path = require('path');

// Create a sample text file for testing uploads
const sampleTextContent = `The Sleepy Moon Adventure

Once upon a time, in a land far away, there lived a little rabbit named Luna who loved to look at the moon every night.

Luna would sit by her window and wonder what it would be like to visit the moon. One magical evening, as she was gazing at the bright full moon, something extraordinary happened.

A gentle silver beam of light stretched down from the moon to her window, creating a shimmering bridge of starlight.

"Come, Luna," whispered a soft voice from the moon. "Come and see the wonders of the night sky."

Luna carefully stepped onto the moonbeam bridge and found herself floating gently upward, carried by the magical light.

As she reached the moon, she discovered it was covered in the softest silver sand and populated by friendly moon rabbits who welcomed her with warm smiles.

The moon rabbits showed Luna their beautiful garden of crystal flowers that sparkled like diamonds in the starlight.

They shared stories of the stars and sang gentle lullabies that could be heard by children all over the world as they fell asleep.

When it was time for Luna to return home, the moon rabbits gave her a small crystal flower to remember her adventure.

As she traveled back down the moonbeam bridge, Luna felt grateful for the magical night and the new friends she had made.

From that night on, whenever Luna looked at the moon, she could see her moon rabbit friends waving back at her, and she knew that adventure was never far away for those who believe in magic.

And so Luna learned that the most wonderful adventures often begin with simply looking up at the night sky and dreaming.

The End.

Sweet dreams! 🌙✨`;

// Create sample files directory
const samplesDir = path.join(__dirname, 'samples');
if (!fs.existsSync(samplesDir)) {
    fs.mkdirSync(samplesDir);
}

// Create sample text file
fs.writeFileSync(
    path.join(samplesDir, 'sample-story.txt'),
    sampleTextContent
);

console.log('✅ Sample test files created in test/samples/');
console.log('📝 sample-story.txt - A sample bedtime story for testing');
console.log('');
console.log('To test the upload endpoint, run:');
console.log('curl -X POST http://localhost:3000/upload -F "story=@test/samples/sample-story.txt"');
