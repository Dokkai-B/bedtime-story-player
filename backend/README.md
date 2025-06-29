# Bedtime Story Player - Backend Service

A Node.js + Express backend service for handling file uploads to AWS S3 for the Bedtime Story Player mobile application.

## Features

- 📁 **File Upload**: Secure file upload endpoint with validation
- 🏗️ **AWS S3 Integration**: Automatic upload to S3 with organized folder structure
- 🔒 **Security**: Helmet.js for security headers, CORS configuration, file type validation
- 📊 **Logging**: Comprehensive logging with Winston
- 🚀 **Scalable**: Built with modern Node.js best practices
- 📱 **Mobile Ready**: Optimized for Flutter mobile app integration

## Supported File Types

- **Text Files**: `.txt`, `.md`, `.pdf`
- **Audio Files**: `.mp3`, `.wav`, `.m4a`, `.aac`

## Prerequisites

- Node.js 18.0.0 or higher
- npm or yarn
- AWS Account with S3 access
- AWS IAM user with S3 permissions

## Installation

1. **Clone and navigate to the backend directory**:
   ```bash
   cd backend
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Set up environment variables**:
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` and fill in your AWS credentials and configuration.

4. **Create logs directory**:
   ```bash
   mkdir logs
   ```

## AWS Setup

### 1. Create S3 Bucket

1. Go to AWS S3 Console
2. Create a new bucket (e.g., `your-bedtime-stories-bucket`)
3. Configure bucket settings:
   - **Block Public Access**: Keep enabled for security
   - **Versioning**: Enable (optional)
   - **Encryption**: Enable server-side encryption

### 2. Create IAM User

1. Go to AWS IAM Console
2. Create a new user for the application
3. Attach the following policy (replace `your-bucket-name`):

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::your-bucket-name/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": "arn:aws:s3:::your-bucket-name"
        }
    ]
}
```

4. Generate Access Keys for the user
5. Add the keys to your `.env` file

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `3000` |
| `NODE_ENV` | Environment mode | `development` |
| `LOG_LEVEL` | Logging level | `info` |
| `ALLOWED_ORIGINS` | CORS allowed origins | `http://localhost:3000` |
| `AWS_ACCESS_KEY_ID` | AWS Access Key | **Required** |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key | **Required** |
| `AWS_REGION` | AWS Region | **Required** |
| `AWS_S3_BUCKET_NAME` | S3 Bucket Name | **Required** |

### File Upload Limits

- **Maximum file size**: 100MB
- **Allowed types**: Text files and audio files only
- **Storage structure**: Files are organized by type and date in S3

## Usage

### Development Mode

```bash
npm run dev
```

This runs the server with nodemon for auto-reloading.

### Production Mode

```bash
npm start
```

### Health Check

```bash
curl http://localhost:3000/health
```

## API Endpoints

### POST /upload

Upload a story file to S3.

**Request:**
- Method: `POST`
- Content-Type: `multipart/form-data`
- Body: Form data with `story` field containing the file

**Example using curl:**
```bash
curl -X POST \
  http://localhost:3000/upload \
  -F "story=@/path/to/your/story.mp3"
```

**Response:**
```json
{
  "success": true,
  "message": "File uploaded successfully",
  "data": {
    "fileName": "story.mp3",
    "fileSize": 1234567,
    "fileType": "audio/mpeg",
    "s3Key": "stories/audio/2025-06-29/uuid-story.mp3",
    "s3Location": "https://bucket.s3.region.amazonaws.com/stories/audio/2025-06-29/uuid-story.mp3",
    "uploadedAt": "2025-06-29T10:30:00.000Z"
  }
}
```

### GET /health

Check server health status.

**Response:**
```json
{
  "status": "OK",
  "timestamp": "2025-06-29T10:30:00.000Z",
  "service": "Bedtime Story Player Backend"
}
```

### GET /stories

Placeholder endpoint for listing uploaded stories.

## File Organization in S3

Files are automatically organized in S3 with the following structure:

```
your-bucket/
├── stories/
│   ├── audio/
│   │   └── 2025-06-29/
│   │       └── uuid-filename.mp3
│   └── text/
│       └── 2025-06-29/
│           └── uuid-filename.txt
```

## Error Handling

The API returns appropriate HTTP status codes and error messages:

- `400 Bad Request`: Invalid file type, missing file, or malformed request
- `413 Payload Too Large`: File exceeds size limit
- `500 Internal Server Error`: Server or AWS errors

## Logging

Logs are written to:
- `logs/combined.log` - All logs
- `logs/error.log` - Error logs only
- Console output (development mode)

## Security Features

- **Helmet.js**: Security headers
- **CORS**: Configurable cross-origin resource sharing
- **File validation**: Type and size checking
- **Error sanitization**: Sensitive information is not exposed in error responses

## Integration with Flutter

To integrate with your Flutter app, use the `http` or `dio` package to make multipart requests:

```dart
// Example Flutter integration
var request = http.MultipartRequest(
  'POST',
  Uri.parse('http://your-backend-url/upload'),
);
request.files.add(
  await http.MultipartFile.fromPath('story', filePath),
);
var response = await request.send();
```

## Deployment

### Heroku

1. Create a Heroku app
2. Set environment variables in Heroku dashboard
3. Deploy using Git or GitHub integration

### AWS ECS/EC2

1. Create an ECS cluster or EC2 instance
2. Set up environment variables
3. Deploy using Docker or direct deployment

### Environment Variables for Production

Make sure to set all required environment variables in your production environment and never commit the actual `.env` file to version control.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Support

For issues and questions, please create an issue in the repository or contact the development team.
