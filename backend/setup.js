#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🚀 Setting up Bedtime Story Player Backend...');

// Create required directories
const directories = [
    'logs',
    'test/samples'
];

directories.forEach(dir => {
    const fullPath = path.join(__dirname, dir);
    if (!fs.existsSync(fullPath)) {
        fs.mkdirSync(fullPath, { recursive: true });
        console.log(`✅ Created directory: ${dir}`);
    } else {
        console.log(`📁 Directory already exists: ${dir}`);
    }
});

// Check if .env exists
const envPath = path.join(__dirname, '.env');
const envExamplePath = path.join(__dirname, '.env.example');

if (!fs.existsSync(envPath)) {
    if (fs.existsSync(envExamplePath)) {
        fs.copyFileSync(envExamplePath, envPath);
        console.log('📝 Created .env file from .env.example');
        console.log('⚠️  Please edit .env file with your AWS credentials');
    } else {
        console.log('❌ .env.example not found');
    }
} else {
    console.log('📄 .env file already exists');
}

// Create sample test files
try {
    require('./test/create-samples.js');
} catch (error) {
    console.log('⚠️  Could not create sample files:', error.message);
}

console.log('');
console.log('🎉 Setup complete!');
console.log('');
console.log('Next steps:');
console.log('1. Edit .env file with your AWS credentials');
console.log('2. Run: npm install');
console.log('3. Run: npm run dev');
console.log('4. Test with: curl -X POST http://localhost:3000/upload -F "story=@test/samples/sample-story.txt"');
