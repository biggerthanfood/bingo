#!/bin/sh
# check_firebase_config.sh
# Check if GoogleService-Info.plist exists and create a placeholder if it doesn't

FIREBASE_CONFIG_PATH="Runner/GoogleService-Info.plist"
FIREBASE_CONFIG_FULL_PATH="/Volumes/workspace/repository/ios/${FIREBASE_CONFIG_PATH}"

echo "🔍 Checking for Firebase configuration at: ${FIREBASE_CONFIG_FULL_PATH}"

if [ -f "${FIREBASE_CONFIG_FULL_PATH}" ]; then
  echo "✅ Firebase configuration file exists"
else
  echo "⚠️ Firebase configuration file not found, creating placeholder..."
  
  # Create directory if it doesn't exist
  mkdir -p "$(dirname "${FIREBASE_CONFIG_FULL_PATH}")"
  
  # Create a placeholder plist file that won't cause build errors
  cat > "${FIREBASE_CONFIG_FULL_PATH}" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CLIENT_ID</key>
  <string>placeholder-client-id</string>
  <key>REVERSED_CLIENT_ID</key>
  <string>placeholder.reversed.client.id</string>
  <key>API_KEY</key>
  <string>placeholder-api-key</string>
  <key>GCM_SENDER_ID</key>
  <string>placeholder-gcm-sender-id</string>
  <key>PLIST_VERSION</key>
  <string>1</string>
  <key>BUNDLE_ID</key>
  <string>com.example.placeholder</string>
  <key>PROJECT_ID</key>
  <string>placeholder-project-id</string>
  <key>STORAGE_BUCKET</key>
  <string>placeholder-storage-bucket</string>
  <key>IS_ADS_ENABLED</key>
  <false/>
  <key>IS_ANALYTICS_ENABLED</key>
  <false/>
  <key>IS_APPINVITE_ENABLED</key>
  <false/>
  <key>IS_GCM_ENABLED</key>
  <false/>
  <key>IS_SIGNIN_ENABLED</key>
  <false/>
  <key>GOOGLE_APP_ID</key>
  <string>placeholder-app-id</string>
</dict>
</plist>
EOF

  echo "✅ Created placeholder Firebase configuration file"
  
  # Make sure the file has the right permissions
  chmod 644 "${FIREBASE_CONFIG_FULL_PATH}"
fi

# Show the file's info for debugging
ls -la "${FIREBASE_CONFIG_FULL_PATH}"
echo "📄 Firebase configuration file contents:"
cat "${FIREBASE_CONFIG_FULL_PATH}" | grep -v "API_KEY\|CLIENT_ID" # Hide sensitive info in logs 