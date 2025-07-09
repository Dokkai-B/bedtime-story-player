class AppConfig {
  // Network Configuration
  // For local network (same WiFi): use local IP
  // For remote access: use tunneling service (LocalTunnel/Ngrok)
  
  // LOCAL NETWORK ACCESS (when on same WiFi)
  static const String localServerHost = '192.168.68.109';
  
  // REMOTE ACCESS (for long distance - using Render hosting)
  // Stable cloud deployment - no need to restart tunnels!
  static const String remoteServerHost = 'bedtime-story-player.onrender.com';
  
  // CURRENT MODE: Change this to switch between local/remote
  static const bool useRemoteAccess = true; // Set to false for local network
  
  static const String localServerPort = '3000';
  static const String remoteServerPort = '443'; // HTTPS for LocalTunnel
  
  // Automatically select the right host and port based on mode
  static String get serverHost => useRemoteAccess ? remoteServerHost : localServerHost;
  static String get serverPort => useRemoteAccess ? remoteServerPort : localServerPort;
  static String get serverProtocol => useRemoteAccess ? 'https' : 'http';
  static String get baseUrl => '$serverProtocol://$serverHost${useRemoteAccess ? '' : ':$serverPort'}';
  
  // App Configuration
  static const String appName = 'Bedtime Story Player';
  static const String version = '1.0.0';
  
  // Network timeouts (in seconds)
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 60;
  
  // File upload limits
  static const int maxFileSizeMB = 100;
  
  // Supported file types
  static const List<String> supportedAudioTypes = [
    'audio/mpeg',
    'audio/mp3', 
    'audio/wav',
    'audio/m4a',
    'audio/aac'
  ];
  
  static const List<String> supportedTextTypes = [
    'text/plain',
    'text/markdown',
    'application/pdf'
  ];
}
