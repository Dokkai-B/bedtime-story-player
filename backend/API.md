# API Documentation - Bedtime Story Player Backend

## Base URL
```
http://localhost:3000
```

## Authentication
Currently, no authentication is required. In production, consider implementing API keys or JWT tokens.

## Endpoints

### Health Check

**GET** `/health`

Check if the server is running and healthy.

**Response:**
```json
{
  "status": "OK",
  "timestamp": "2025-06-29T10:30:00.000Z",
  "service": "Bedtime Story Player Backend"
}
```

**Status Codes:**
- `200 OK` - Server is healthy

---

### Upload Story File

**POST** `/upload`

Upload a story file (text or audio) to AWS S3.

**Content-Type:** `multipart/form-data`

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `story` | File | Yes | The story file to upload |

**Supported File Types:**
- **Text Files:** `.txt`, `.md`, `.pdf`
- **Audio Files:** `.mp3`, `.wav`, `.m4a`, `.aac`

**File Size Limit:** 100MB

**Example Request (cURL):**
```bash
curl -X POST \
  http://localhost:3000/upload \
  -F "story=@/path/to/your/story.mp3"
```

**Example Request (JavaScript):**
```javascript
const formData = new FormData();
formData.append('story', fileInput.files[0]);

fetch('http://localhost:3000/upload', {
  method: 'POST',
  body: formData,
})
.then(response => response.json())
.then(data => console.log(data));
```

**Example Request (Flutter/Dart):**
```dart
import 'package:http/http.dart' as http;

Future<void> uploadStory(String filePath) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://localhost:3000/upload'),
  );
  
  request.files.add(
    await http.MultipartFile.fromPath('story', filePath),
  );
  
  var response = await request.send();
  
  if (response.statusCode == 200) {
    var responseData = await response.stream.bytesToString();
    print('Upload successful: $responseData');
  } else {
    print('Upload failed: ${response.statusCode}');
  }
}
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "File uploaded successfully",
  "data": {
    "fileName": "bedtime-story.mp3",
    "fileSize": 1234567,
    "fileType": "audio/mpeg",
    "s3Key": "stories/audio/2025-06-29/a1b2c3d4-bedtime-story.mp3",
    "s3Location": "https://your-bucket.s3.us-east-1.amazonaws.com/stories/audio/2025-06-29/a1b2c3d4-bedtime-story.mp3",
    "uploadedAt": "2025-06-29T10:30:00.000Z"
  }
}
```

**Error Responses:**

**400 Bad Request - No File:**
```json
{
  "error": "No file uploaded",
  "message": "Please select a file to upload"
}
```

**400 Bad Request - Invalid File Type:**
```json
{
  "error": "Invalid file type",
  "message": "Invalid file type. Only text files and audio files are allowed."
}
```

**400 Bad Request - File Too Large:**
```json
{
  "error": "File too large",
  "message": "File size must be less than 100MB"
}
```

**500 Server Error - Configuration:**
```json
{
  "error": "Server configuration error",
  "message": "AWS configuration is incomplete"
}
```

**500 Server Error - Upload Failed:**
```json
{
  "error": "Upload failed",
  "message": "An error occurred while uploading the file"
}
```

---

### Get Stories (Placeholder)

**GET** `/stories`

Placeholder endpoint for retrieving uploaded stories. Currently returns a message about implementation.

**Response:**
```json
{
  "message": "Stories endpoint - implement based on your needs",
  "suggestion": "Consider storing file metadata in a database for better querying"
}
```

---

## S3 File Organization

Files are automatically organized in your S3 bucket with the following structure:

```
your-s3-bucket/
├── stories/
│   ├── audio/
│   │   ├── 2025-06-29/
│   │   │   ├── uuid1-story1.mp3
│   │   │   └── uuid2-story2.wav
│   │   └── 2025-06-30/
│   │       └── uuid3-story3.m4a
│   └── text/
│       ├── 2025-06-29/
│       │   ├── uuid4-story4.txt
│       │   └── uuid5-story5.md
│       └── 2025-06-30/
│           └── uuid6-story6.pdf
```

## Rate Limiting

Currently, no rate limiting is implemented. For production use, consider implementing rate limiting to prevent abuse.

## CORS

The server accepts requests from origins specified in the `ALLOWED_ORIGINS` environment variable. Default is `http://localhost:3000`.

## Logging

All requests and errors are logged using Winston with different log levels:
- `info` - General information
- `warn` - Warnings
- `error` - Errors

Logs are written to:
- Console (development)
- `logs/combined.log` (all logs)
- `logs/error.log` (errors only)

## Testing with Postman

1. **Import Collection:**
   Create a new collection in Postman with the following requests:

2. **Health Check:**
   - Method: GET
   - URL: `http://localhost:3000/health`

3. **Upload File:**
   - Method: POST
   - URL: `http://localhost:3000/upload`
   - Body: form-data
   - Key: `story` (File type)
   - Value: Select your test file

## Security Considerations

1. **File Validation:** Only specific file types are allowed
2. **File Size Limits:** Maximum 100MB per file
3. **Helmet:** Security headers are applied
4. **CORS:** Cross-origin requests are controlled
5. **Error Sanitization:** Sensitive server information is not exposed

## Future Enhancements

1. **Authentication:** Add API key or JWT authentication
2. **Database Integration:** Store file metadata in a database
3. **File Processing:** Add audio transcription or text processing
4. **Caching:** Implement Redis for caching
5. **Rate limiting:** Add request rate limiting
6. **Webhooks:** Notify clients when uploads complete
7. **Batch Uploads:** Support multiple file uploads
8. **File Versioning:** Handle file updates and versions
