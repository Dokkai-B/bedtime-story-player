const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const path = require('path');
require('dotenv').config();

// AWS SDK v3 imports
const { S3Client } = require('@aws-sdk/client-s3');
const { Upload } = require('@aws-sdk/lib-storage');

// Logger setup
const logger = require('./utils/logger');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());

// CORS configuration
app.use(cors({
    origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : ['http://localhost:3000'],
    credentials: true
}));

// Body parsing middleware
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// AWS S3 Client configuration
const s3Client = new S3Client({
    region: process.env.AWS_REGION,
    credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    },
});

// Multer configuration for file uploads
const storage = multer.memoryStorage();
const upload = multer({
    storage: storage,
    limits: {
        fileSize: 100 * 1024 * 1024, // 100MB limit
    },
    fileFilter: (req, file, cb) => {
        // Allowed file types for stories
        const allowedTypes = [
            'text/plain',
            'text/markdown',
            'application/pdf',
            'audio/mpeg',
            'audio/mp3',
            'audio/wav',
            'audio/m4a',
            'audio/aac'
        ];
        
        if (allowedTypes.includes(file.mimetype)) {
            cb(null, true);
        } else {
            logger.warn(`File upload rejected - invalid type: ${file.mimetype}`);
            cb(new Error('Invalid file type. Only text files and audio files are allowed.'), false);
        }
    }
});

// Helper function to generate S3 key
const generateS3Key = (originalName, fileType) => {
    const timestamp = new Date().toISOString().split('T')[0];
    const uniqueId = uuidv4();
    const extension = path.extname(originalName);
    const baseName = path.basename(originalName, extension);
    
    // Organize files by type and date
    const folder = fileType.startsWith('audio/') ? 'audio' : 'text';
    return `stories/${folder}/${timestamp}/${uniqueId}-${baseName}${extension}`;
};

// Upload file to S3
const uploadToS3 = async (file, key) => {
    try {
        const upload = new Upload({
            client: s3Client,
            params: {
                Bucket: process.env.AWS_S3_BUCKET_NAME,
                Key: key,
                Body: file.buffer,
                ContentType: file.mimetype,
                Metadata: {
                    originalName: file.originalname,
                    uploadedAt: new Date().toISOString(),
                }
            },
        });

        const result = await upload.done();
        logger.info(`File uploaded successfully to S3: ${key}`);
        return result;
    } catch (error) {
        logger.error(`S3 upload failed for key ${key}:`, error);
        throw error;
    }
};

// Routes

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'OK',
        timestamp: new Date().toISOString(),
        service: 'Bedtime Story Player Backend'
    });
});

// File upload endpoint
app.post('/upload', upload.single('story'), async (req, res) => {
    try {
        // Validate environment variables
        if (!process.env.AWS_S3_BUCKET_NAME || !process.env.AWS_REGION || 
            !process.env.AWS_ACCESS_KEY_ID || !process.env.AWS_SECRET_ACCESS_KEY) {
            logger.error('Missing required AWS configuration');
            return res.status(500).json({
                error: 'Server configuration error',
                message: 'AWS configuration is incomplete'
            });
        }

        // Check if file was uploaded
        if (!req.file) {
            logger.warn('Upload attempt without file');
            return res.status(400).json({
                error: 'No file uploaded',
                message: 'Please select a file to upload'
            });
        }

        const file = req.file;
        logger.info(`Processing upload: ${file.originalname} (${file.mimetype}, ${file.size} bytes)`);

        // Generate S3 key
        const s3Key = generateS3Key(file.originalname, file.mimetype);

        // Upload to S3
        const uploadResult = await uploadToS3(file, s3Key);

        // Response
        const response = {
            success: true,
            message: 'File uploaded successfully',
            data: {
                fileName: file.originalname,
                fileSize: file.size,
                fileType: file.mimetype,
                s3Key: s3Key,
                s3Location: uploadResult.Location,
                uploadedAt: new Date().toISOString()
            }
        };

        logger.info(`Upload completed successfully: ${file.originalname}`);
        res.status(200).json(response);

    } catch (error) {
        logger.error('Upload error:', error);
        
        // Handle specific errors
        if (error.message.includes('Invalid file type')) {
            return res.status(400).json({
                error: 'Invalid file type',
                message: error.message
            });
        }

        if (error.name === 'MulterError') {
            return res.status(400).json({
                error: 'Upload error',
                message: error.message
            });
        }

        // Generic server error
        res.status(500).json({
            error: 'Upload failed',
            message: 'An error occurred while uploading the file'
        });
    }
});

// Get uploaded stories (optional endpoint for listing files)
app.get('/stories', async (req, res) => {
    try {
        // This is a basic implementation - you might want to store metadata in a database
        // For now, we'll return a simple response
        res.status(200).json({
            message: 'Stories endpoint - implement based on your needs',
            suggestion: 'Consider storing file metadata in a database for better querying'
        });
    } catch (error) {
        logger.error('Error fetching stories:', error);
        res.status(500).json({
            error: 'Failed to fetch stories',
            message: error.message
        });
    }
});

// Error handling middleware
app.use((error, req, res, next) => {
    logger.error('Unhandled error:', error);
    
    if (error instanceof multer.MulterError) {
        if (error.code === 'LIMIT_FILE_SIZE') {
            return res.status(400).json({
                error: 'File too large',
                message: 'File size must be less than 100MB'
            });
        }
    }

    res.status(500).json({
        error: 'Internal server error',
        message: 'Something went wrong'
    });
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({
        error: 'Not found',
        message: 'The requested endpoint does not exist'
    });
});

// Start server
app.listen(PORT, () => {
    logger.info(`🚀 Bedtime Story Player Backend running on port ${PORT}`);
    logger.info(`📁 Environment: ${process.env.NODE_ENV || 'development'}`);
    logger.info(`🌍 Health check: http://localhost:${PORT}/health`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    logger.info('SIGTERM received, shutting down gracefully');
    process.exit(0);
});

process.on('SIGINT', () => {
    logger.info('SIGINT received, shutting down gracefully');
    process.exit(0);
});

module.exports = app;
