# Network Troubleshooting Guide for Girlfriend's Phone

## Issue: App shows "Failed to connect to server: TimeoutException"

## Step-by-Step Troubleshooting:

### Step 1: Verify Same Wi-Fi Network
1. **Check your Wi-Fi name** on her phone: Settings > Wi-Fi
2. **Compare with your phone/PC** - must be exactly the same network
3. **Not guest network** - some guest networks block device communication

### Step 2: Test Direct Connection
1. **Open web browser** on her phone (Chrome, Firefox, etc.)
2. **Type this URL**: `http://192.168.68.109:3000/health`
3. **Expected result**: Should see: `{"status":"OK","timestamp":"...","service":"Bedtime Story Player Backend"}`
4. **If timeout/error**: Network connectivity issue
5. **If successful**: Network is fine, app issue

### Step 3: Router Issues
If Step 2 fails, the router might be blocking communication:

#### Option A: Router Settings
1. **Access router admin** (usually `192.168.1.1` or `192.168.0.1`)
2. **Look for "AP Isolation" or "Client Isolation"**
3. **Disable it** if enabled
4. **Restart router**

#### Option B: Try Mobile Hotspot Test
1. **Create hotspot** on your phone
2. **Connect her phone** to your hotspot
3. **Update server IP** to your phone's hotspot IP
4. **Test app** - if it works, router is the problem

### Step 4: Alternative IP Addresses
Your PC might have multiple IP addresses. Try these in browser first:
- `http://192.168.1.109:3000/health`
- `http://192.168.0.109:3000/health`
- `http://10.0.0.109:3000/health`

### Step 5: Port Issues
Some networks block port 3000. Try changing backend port:
1. **Edit `backend/.env`**: Change `PORT=3000` to `PORT=8080`
2. **Restart backend**
3. **Test**: `http://192.168.68.109:8080/health`

## Quick Fixes to Try:

### Fix 1: Restart Everything
1. **Restart her phone**
2. **Restart your router** (unplug 30 seconds)
3. **Restart backend server**

### Fix 2: Forget and Reconnect Wi-Fi
1. **Settings > Wi-Fi** on her phone
2. **Tap your network name**
3. **"Forget Network"**
4. **Reconnect** with password

### Fix 3: Check Network Type
- **5GHz vs 2.4GHz**: Some routers separate these
- **Try connecting both phones to 2.4GHz** if available
- **Network name might be "NetworkName_5G" vs "NetworkName"**

## Advanced Troubleshooting:

### Check if Router Blocks Cross-Device Communication:
Many modern routers have security features that prevent devices from talking to each other.

### Corporate/School Networks:
If on work/school Wi-Fi, they often block device-to-device communication for security.

### Network Security Apps:
Some security apps on phones block local network connections.

## Last Resort:
If nothing works, set up a **mobile hotspot** from your phone and connect her phone to it. This bypasses router issues.

---

**Current Server Info:**
- **IP**: 192.168.68.109
- **Port**: 3000  
- **Health Check**: http://192.168.68.109:3000/health
