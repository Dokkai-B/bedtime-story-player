const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const path = require('path');
require('dotenv').config();

// AWS SDK v3 imports
const { S3Client, ListObjectsV2Command } = require('@aws-sdk/client-s3');
const { Upload } = require('@aws-sdk/lib-storage');

// Logger setup
const logger = require('./utils/logger');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());

// CORS configuration - Updated for mobile device access
app.use(cors({
    origin: '*', // Just for development
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
            'audio/aac',
            'application/octet-stream' // Allow octet-stream and check extension
        ];
        
        // Get file extension from original name
        const fileExtension = file.originalname.split('.').pop()?.toLowerCase();
        const allowedExtensions = ['txt', 'md', 'pdf', 'mp3', 'wav', 'm4a', 'aac'];
        
        // Check if file type is allowed OR if extension is allowed (for octet-stream files)
        const isValidType = allowedTypes.includes(file.mimetype);
        const isValidExtension = allowedExtensions.includes(fileExtension || '');
        
        if (isValidType || isValidExtension) {
            // For octet-stream files, try to correct the MIME type based on extension
            if (file.mimetype === 'application/octet-stream' && fileExtension) {
                switch (fileExtension) {
                    case 'mp3':
                        file.mimetype = 'audio/mpeg';
                        break;
                    case 'wav':
                        file.mimetype = 'audio/wav';
                        break;
                    case 'm4a':
                        file.mimetype = 'audio/m4a';
                        break;
                    case 'aac':
                        file.mimetype = 'audio/aac';
                        break;
                    case 'txt':
                        file.mimetype = 'text/plain';
                        break;
                    case 'md':
                        file.mimetype = 'text/markdown';
                        break;
                    case 'pdf':
                        file.mimetype = 'application/pdf';
                        break;
                }
            }
            cb(null, true);
        } else {
            logger.warn(`File upload rejected - invalid type: ${file.mimetype}, extension: ${fileExtension}`);
            cb(new Error(`Invalid file type. Only text files and audio files are allowed. (Received: ${file.mimetype}, Extension: ${fileExtension})`), false);
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

        // TEST MODE: Skip AWS upload if in development and AWS not configured
        const isTestMode = process.env.NODE_ENV !== 'production' && (
            !process.env.AWS_S3_BUCKET_NAME || 
            !process.env.AWS_REGION || 
            !process.env.AWS_ACCESS_KEY_ID || 
            !process.env.AWS_SECRET_ACCESS_KEY ||
            process.env.TEST_MODE === 'true'
        );

        let uploadResult;
        
        if (isTestMode) {
            // In test mode, save file to local test/samples directory
            logger.info('Running in TEST MODE - saving file locally');
            
            const fs = require('fs');
            const testSamplesDir = path.join(__dirname, 'test', 'samples');
            
            // Ensure the samples directory exists
            if (!fs.existsSync(testSamplesDir)) {
                fs.mkdirSync(testSamplesDir, { recursive: true });
            }
            
            // Save the file with original name (check if already exists and append number if needed)
            let fileName = file.originalname;
            let localFilePath = path.join(testSamplesDir, fileName);
            let counter = 1;
            
            // If file exists, append a number
            while (fs.existsSync(localFilePath)) {
                const extension = path.extname(file.originalname);
                const baseName = path.basename(file.originalname, extension);
                fileName = `${baseName}_${counter}${extension}`;
                localFilePath = path.join(testSamplesDir, fileName);
                counter++;
            }
            
            // Write file to local directory
            fs.writeFileSync(localFilePath, file.buffer);
            
            uploadResult = {
                Location: `http://192.168.68.109:${PORT}/file/${encodeURIComponent(fileName)}`,
                Key: `stories/test/${fileName}`, // Use clean filename for consistency
                Bucket: 'test-bucket'
            };
        } else {
            // Validate environment variables for production
            if (!process.env.AWS_S3_BUCKET_NAME || !process.env.AWS_REGION || 
                !process.env.AWS_ACCESS_KEY_ID || !process.env.AWS_SECRET_ACCESS_KEY) {
                logger.error('Missing required AWS configuration');
                return res.status(500).json({
                    error: 'Server configuration error',
                    message: 'AWS configuration is incomplete'
                });
            }
            
            // Upload to S3
            uploadResult = await uploadToS3(file, s3Key);
        }

        // Response
        const response = {
            success: true,
            message: `File uploaded successfully${isTestMode ? ' (TEST MODE)' : ''}`,
            data: {
                fileName: file.originalname,
                fileSize: file.size,
                fileType: file.mimetype,
                s3Key: s3Key,
                s3Location: uploadResult.Location,
                uploadedAt: new Date().toISOString(),
                testMode: isTestMode
            }
        };

        logger.info(`Upload completed successfully: ${file.originalname}${isTestMode ? ' (TEST MODE)' : ''}`);
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

// Update `/stories` endpoint to include uploaded files in test mode
app.get('/stories', async (req, res) => {
    try {
        const isTestMode = process.env.NODE_ENV !== 'production' && (
            !process.env.AWS_S3_BUCKET_NAME || 
            !process.env.AWS_REGION || 
            !process.env.AWS_ACCESS_KEY_ID || 
            !process.env.AWS_SECRET_ACCESS_KEY ||
            process.env.TEST_MODE === 'true'
        );

        if (isTestMode) {
            const fs = require('fs');
            const testSamplesDir = path.join(__dirname, 'test', 'samples');
            
            // Dynamic base URL - use the request host (supports tunnels like ngrok/localtunnel)
            const forwardedProto = req.headers['x-forwarded-proto'];
            const host = req.headers['x-forwarded-host'] || req.headers.host || `192.168.68.109:${PORT}`;
            
            // Determine protocol - if host contains .loca.lt or other tunnel services, use https
            let protocol;
            if (host.includes('.loca.lt') || host.includes('.ngrok.io') || host.includes('.serveo.net')) {
                protocol = 'https';
            } else if (forwardedProto && typeof forwardedProto === 'string') {
                protocol = forwardedProto.split(',')[0].trim(); // Take first protocol if multiple
            } else {
                protocol = req.connection.encrypted ? 'https' : 'http';
            }
            
            const baseUrl = `${protocol}://${host}`;

            // Read files from the test samples directory
            const files = fs.readdirSync(testSamplesDir).map(fileName => {
                const filePath = path.join(testSamplesDir, fileName);
                const stat = fs.statSync(filePath);
                const extension = fileName.split('.').pop()?.toLowerCase();
                let fileType = 'application/octet-stream';

                if (['mp3', 'wav', 'm4a', 'aac'].includes(extension)) {
                    fileType = `audio/${extension}`;
                } else if (['txt', 'md', 'pdf'].includes(extension)) {
                    fileType = extension === 'txt' ? 'text/plain' : extension === 'md' ? 'text/markdown' : 'application/pdf';
                }

                return {
                    fileName: fileName, // Use actual filename as display name
                    fileSize: stat.size,
                    fileType,
                    s3Key: `stories/test/${fileName}`,
                    s3Location: `${baseUrl}/file/${encodeURIComponent(fileName)}`, // URL encode for safety
                    uploadedAt: stat.mtime.toISOString(),
                    category: fileType.startsWith('audio') ? 'audio' : 'text'
                };
            });

            return res.status(200).json({
                success: true,
                stories: files,
                totalCount: files.length,
                testMode: true
            });
        }

        // Validate environment variables for S3 access
        if (!process.env.AWS_S3_BUCKET_NAME || !process.env.AWS_REGION || 
            !process.env.AWS_ACCESS_KEY_ID || !process.env.AWS_SECRET_ACCESS_KEY) {
            logger.error('Missing required AWS configuration for stories listing');
            return res.status(500).json({
                error: 'Server configuration error',
                message: 'AWS configuration is incomplete'
            });
        }

        // List objects from S3 with 'stories/' prefix
        const listCommand = new ListObjectsV2Command({
            Bucket: process.env.AWS_S3_BUCKET_NAME,
            Prefix: 'stories/',
            MaxKeys: 100 // Limit for now, can add pagination later
        });

        const result = await s3Client.send(listCommand);
        
        if (!result.Contents || result.Contents.length === 0) {
            return res.status(200).json({
                success: true,
                stories: [],
                totalCount: 0,
                message: 'No stories found'
            });
        }

        // Process and format the S3 objects
        const stories = result.Contents
            .filter(obj => obj.Key && obj.Key !== 'stories/') // Filter out folder entries
            .map(obj => {
                // Extract info from S3 key: stories/audio/2025-06-29/uuid-filename.mp3
                const keyParts = obj.Key.split('/');
                const category = keyParts[1]; // 'audio' or 'text'
                const fileName = keyParts[3]?.split('-').slice(1).join('-') || obj.Key.split('/').pop();
                
                // Generate S3 URL
                const s3Location = `https://${process.env.AWS_S3_BUCKET_NAME}.s3.${process.env.AWS_REGION}.amazonaws.com/${obj.Key}`;
                
                // Determine file type from category and extension
                const extension = fileName?.split('.').pop()?.toLowerCase();
                let fileType = 'application/octet-stream';
                
                if (category === 'audio') {
                    switch (extension) {
                        case 'mp3': fileType = 'audio/mpeg'; break;
                        case 'wav': fileType = 'audio/wav'; break;
                        case 'm4a': fileType = 'audio/m4a'; break;
                        case 'aac': fileType = 'audio/aac'; break;
                    }
                } else if (category === 'text') {
                    switch (extension) {
                        case 'txt': fileType = 'text/plain'; break;
                        case 'md': fileType = 'text/markdown'; break;
                        case 'pdf': fileType = 'application/pdf'; break;
                    }
                }

                return {
                    fileName: fileName || 'Unknown',
                    fileSize: obj.Size || 0,
                    fileType: fileType,
                    s3Key: obj.Key,
                    s3Location: s3Location,
                    uploadedAt: obj.LastModified?.toISOString() || new Date().toISOString(),
                    category: category || 'unknown'
                };
            })
            .sort((a, b) => new Date(b.uploadedAt).getTime() - new Date(a.uploadedAt).getTime()); // Sort by upload date, newest first

        logger.info(`Retrieved ${stories.length} stories from S3`);
        
        res.status(200).json({
            success: true,
            stories: stories,
            totalCount: stories.length,
            testMode: false
        });

    } catch (error) {
        logger.error('Error fetching stories:', error);
        res.status(500).json({
            error: 'Failed to fetch stories',
            message: error.message
        });
    }
});

// File serving endpoint for test mode
app.get('/file/:storyId', async (req, res) => {
    try {
        const { storyId } = req.params;
        
        // Decode URL-encoded filename
        const decodedStoryId = decodeURIComponent(storyId);
        
        logger.info(`File request: ${storyId} -> ${decodedStoryId}`);
        
        // Check if we're in test mode
        const isTestMode = process.env.NODE_ENV !== 'production' && (
            !process.env.AWS_S3_BUCKET_NAME || 
            !process.env.AWS_REGION || 
            !process.env.AWS_ACCESS_KEY_ID || 
            !process.env.AWS_SECRET_ACCESS_KEY ||
            process.env.TEST_MODE === 'true'
        );

        if (isTestMode) {
            // For test mode, serve files from test/samples directory
            const fs = require('fs');
            const samplesDir = path.join(__dirname, 'test', 'samples');
            const requestedFilePath = path.join(samplesDir, decodedStoryId);
            
            // Security check: ensure file is within samples directory
            const normalizedPath = path.normalize(requestedFilePath);
            const normalizedSamplesDir = path.normalize(samplesDir);
            if (!normalizedPath.startsWith(normalizedSamplesDir)) {
                logger.warn(`Path traversal attempt blocked: ${decodedStoryId}`);
                return res.status(403).json({
                    error: 'Access denied',
                    message: 'Invalid file path'
                });
            }
            
            // Check if requested file exists
            if (fs.existsSync(requestedFilePath)) {
                const stat = fs.statSync(requestedFilePath);
                const fileSize = stat.size;
                const range = req.headers.range;
                
                // Determine content type based on file extension
                const extension = path.extname(decodedStoryId).toLowerCase();
                let contentType = 'application/octet-stream';
                
                switch (extension) {
                    case '.mp3':
                        contentType = 'audio/mpeg';
                        break;
                    case '.wav':
                        contentType = 'audio/wav';
                        break;
                    case '.m4a':
                        contentType = 'audio/m4a';
                        break;
                    case '.aac':
                        contentType = 'audio/aac';
                        break;
                    case '.txt':
                        contentType = 'text/plain';
                        break;
                    case '.md':
                        contentType = 'text/markdown';
                        break;
                    case '.pdf':
                        contentType = 'application/pdf';
                        break;
                }

                // Set CORS headers for audio access
                res.set({
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
                    'Access-Control-Allow-Headers': 'Range, Content-Range',
                    'Access-Control-Expose-Headers': 'Content-Range, Accept-Ranges, Content-Length'
                });

                if (range) {
                    // Support range requests for audio streaming
                    const parts = range.replace(/bytes=/, "").split("-");
                    const start = parseInt(parts[0], 10);
                    const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;
                    
                    // Ensure we don't exceed file bounds
                    const validStart = Math.max(0, Math.min(start, fileSize - 1));
                    const validEnd = Math.max(validStart, Math.min(end, fileSize - 1));
                    const chunksize = (validEnd - validStart) + 1;
                    
                    // Create read stream with high water mark for better buffering
                    const file = fs.createReadStream(requestedFilePath, { 
                        start: validStart, 
                        end: validEnd,
                        highWaterMark: 64 * 1024 // 64KB chunks for smoother streaming
                    });
                    
                    const head = {
                        'Content-Range': `bytes ${validStart}-${validEnd}/${fileSize}`,
                        'Accept-Ranges': 'bytes',
                        'Content-Length': chunksize,
                        'Content-Type': contentType,
                        'Cache-Control': 'public, max-age=3600', // Allow caching for 1 hour
                    };
                    res.writeHead(206, head);
                    file.pipe(res);
                } else {
                    // Serve entire file with optimized streaming
                    const head = {
                        'Content-Length': fileSize,
                        'Content-Type': contentType,
                        'Accept-Ranges': 'bytes',
                        'Cache-Control': 'public, max-age=3600', // Allow caching for 1 hour
                    };
                    res.writeHead(200, head);
                    const fileStream = fs.createReadStream(requestedFilePath, {
                        highWaterMark: 64 * 1024 // 64KB chunks
                    });
                    fileStream.pipe(res);
                }
                
                logger.info(`Serving file: ${decodedStoryId}`);
                return;
            } else {
                logger.warn(`File not found: ${decodedStoryId}`);
                return res.status(404).json({
                    error: 'File not found',
                    message: 'Requested file not available'
                });
            }
        } else {
            // In production, redirect to S3 URL or serve from S3
            // This would require implementing S3 file streaming
            return res.status(501).json({
                error: 'Not implemented',
                message: 'Production file serving not yet implemented'
            });
        }

    } catch (error) {
        logger.error('Error serving file:', error);
        res.status(500).json({
            error: 'Failed to serve file',
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
app.listen(PORT, '0.0.0.0', () => {
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
