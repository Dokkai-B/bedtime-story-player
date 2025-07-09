# APK Testing Instructions

## Prerequisites for Testing the Bedtime Story Player APK

### 1. Network Setup
Both devices (your computer running the backend and the phone) must be on the **same Wi-Fi network**.

### 2. Backend Server
Make sure the backend server is running on your computer:

**Quick Start (Recommended):**
- Double-click `backend/start-test-mode.bat` to start in test mode

**Manual Start:**
```bash
cd backend
node server.js
```

**Important:** The backend must run in TEST MODE (`TEST_MODE=true` in `.env` file) for proper functionality. After PC restart, the backend might default to S3 mode - use the batch file to ensure test mode.

The server should show: `🚀 Bedtime Story Player Backend running on port 3000`

### 3. Check Your Computer's IP Address
Your current IP: **192.168.68.109**

To verify or update if network changes:
- Windows: `ipconfig` (look for IPv4 Address)
- Mac/Linux: `ifconfig` (look for inet address)

### 4. Update IP if Needed
If your IP changes, update in `lib/config/app_config.dart`:
```dart
static const String serverHost = 'YOUR_NEW_IP_HERE';
```

## For Your Girlfriend's Phone

### 1. Allow Unknown Sources
Go to Settings > Security > Allow installation from unknown sources
(Location may vary by Android version)

### 2. Install the APK
Transfer the APK file and tap to install

### 3. Connect to Same Wi-Fi
Make sure her phone is on the same Wi-Fi network as your computer

### 4. Test Connectivity
Open the app and try:
1. Go to Library tab - should load existing stories
2. Go to Add Story tab - try uploading a file
3. Play any audio story - test mini and expanded player

## Troubleshooting

### If Stories Don't Load:
- Check Wi-Fi connection (same network)
- Verify backend is running
- Check IP address matches

### If Upload Fails:
- Check network connection
- Ensure backend shows "Running in TEST MODE" (check `TEST_MODE=true` in `.env`)
- Try smaller file first
- If files upload but don't play, restart backend in test mode

### If Audio Won't Play:
- Check if story appears in library first
- Verify backend is in test mode (not S3 mode)
- Try tapping the story again
- Check volume settings

## Network Security
The app is configured to allow HTTP connections to:
- 192.168.68.109 (your current IP)
- Common local network ranges
- Development domains

## Current Features Working:
✅ File upload (audio/text files)
✅ Story library listing
✅ Audio playback with mini player
✅ Expandable player with controls
✅ Smooth scrubbing and seek controls
✅ Multiple file format support (MP3, WAV, etc.)
