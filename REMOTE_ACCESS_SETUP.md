# Remote Access Setup Guide - Long Distance Couples

## 🌍 What We've Done:
- **Configured app for remote access** using your public IP: `112.202.133.117`
- **Updated backend CORS** to allow remote connections
- **Built new APK** with remote access enabled
- **Your girlfriend can now use the app from anywhere in the world!**

## 🔧 Router Setup Required:

### Step 1: Port Forwarding (Critical!)
You MUST set up port forwarding on your router for this to work:

1. **Access Router Admin Panel**:
   - Open browser, go to: `192.168.68.1` or `192.168.1.1`
   - Login with admin username/password (often on router sticker)

2. **Find Port Forwarding Section**:
   - Look for: "Port Forwarding", "Virtual Server", "NAT", or "Applications & Gaming"

3. **Add This Rule**:
   ```
   Service Name: Bedtime Story Backend
   External/WAN Port: 3000
   Internal/LAN IP: 192.168.68.109
   Internal/LAN Port: 3000
   Protocol: TCP
   Status: Enabled
   ```

4. **Save and Restart Router**

### Step 2: Test Remote Access
After port forwarding setup:
1. **Ask your girlfriend to open browser**
2. **Go to**: `http://112.202.133.117:3000/health`
3. **Should see**: `{"status":"OK",...}`
4. **If successful**: Remote access works!

## 📱 APK Files:
- **Remote Access APK**: `build/app/outputs/flutter-apk/app-release.apk` (NEW - for your girlfriend)
- **Local APK**: Previous versions (for when you're on same network)

## ⚠️ Important Notes:

### Security Considerations:
- **Your stories are now accessible from internet** (only with direct IP knowledge)
- **Consider adding authentication** for production use
- **Only share APK with trusted people**

### Dynamic IP Warning:
- Your public IP `112.202.133.117` might change
- If it changes, you'll need to:
  1. Get new IP: `https://whatismyipaddress.com/`
  2. Update `app_config.dart` with new IP
  3. Rebuild APK

### Router Compatibility:
- **Most home routers support port forwarding**
- **Some ISPs block port forwarding** (rare)
- **Corporate/university networks** won't work

### Bandwidth Usage:
- **Audio streaming will use internet data**
- **Both yours and hers** (especially on mobile data)
- **WiFi recommended for large files**

## 🚀 How to Send to Your Girlfriend:

1. **Send her the APK**: `build/app/outputs/flutter-apk/app-release.apk`
2. **She installs it** (allow unknown sources)
3. **You set up port forwarding** on your router
4. **She opens the app** - should work from anywhere!

## 🔄 Switching Between Local/Remote:

If you want to switch back to local network mode:
1. **Edit** `lib/config/app_config.dart`
2. **Change** `useRemoteAccess = false`
3. **Rebuild APK**

## 📞 Troubleshooting:

### If Remote Access Doesn't Work:
1. **Double-check port forwarding** setup
2. **Restart router** after setup
3. **Check if ISP blocks port 3000** (try port 8080 instead)
4. **Verify your PC firewall** allows port 3000
5. **Confirm backend is running** with `start-test-mode.bat`

### Alternative Ports:
If port 3000 is blocked:
1. **Change backend port** in `.env`: `PORT=8080`
2. **Update router port forwarding** to 8080
3. **Update app config** to use port 8080
4. **Rebuild APK**

## 🔐 Future Security Improvements:
- Add user authentication
- Use HTTPS with SSL certificates
- Add rate limiting
- Implement user accounts

---

**Current Configuration:**
- **Your Public IP**: 112.202.133.117
- **Backend Port**: 3000
- **Remote Access**: Enabled
- **Test URL**: http://112.202.133.117:3000/health

**Status**: ✅ App ready for worldwide access after port forwarding setup!
