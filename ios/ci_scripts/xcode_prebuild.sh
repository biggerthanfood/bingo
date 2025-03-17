#!/bin/sh

# xcode_prebuild.sh
# Script to fix the missing GeneratedPluginRegistrant.h issue in Xcode Cloud builds

echo "🛠️ Running Xcode pre-build script to fix missing headers..."

# Create GeneratedPluginRegistrant.h directly in the Runner directory
RUNNER_DIR="${SRCROOT}/Runner"
HEADER_PATH="${RUNNER_DIR}/GeneratedPluginRegistrant.h"
IMPL_PATH="${RUNNER_DIR}/GeneratedPluginRegistrant.m"

# Ensure the directory exists
mkdir -p "${RUNNER_DIR}"

# Create the header file
cat > "${HEADER_PATH}" << 'EOF'
//
// Generated file. Do not edit.
//

// clang-format off
#ifndef GeneratedPluginRegistrant_h
#define GeneratedPluginRegistrant_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FlutterPluginRegistry;

@interface GeneratedPluginRegistrant : NSObject
+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry;
@end

NS_ASSUME_NONNULL_END
#endif /* GeneratedPluginRegistrant_h */
EOF

echo "✅ Created GeneratedPluginRegistrant.h"

# Create the implementation file
cat > "${IMPL_PATH}" << 'EOF'
//
// Generated file. Do not edit.
//

// clang-format off
#import "GeneratedPluginRegistrant.h"

// No plugins to register

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  // No plugins to register
}

@end
EOF

echo "✅ Created GeneratedPluginRegistrant.m"

# Copy the header to DerivedSources (exact path from the error message)
if [ -n "$OBJROOT" ]; then
  DERIVED_SOURCES="${OBJROOT}/DerivedSources"
  mkdir -p "${DERIVED_SOURCES}"
  cp "${HEADER_PATH}" "${DERIVED_SOURCES}/"
  echo "✅ Copied header to ${DERIVED_SOURCES}"
  
  # Also copy to more specific directories if they exist
  for ARCH in arm64 x86_64; do
    ARCH_DIR="${OBJROOT}/DerivedSources-normal/${ARCH}"
    if [ -d "${OBJROOT}" ]; then
      mkdir -p "${ARCH_DIR}"
      cp "${HEADER_PATH}" "${ARCH_DIR}/"
      echo "✅ Copied header to ${ARCH_DIR}"
    fi
  done
fi

# Also create a basic Flutter.h if needed
FLUTTER_DIRS=(
  "${SRCROOT}/Flutter/Flutter.framework/Headers"
  "${SRCROOT}/.symlinks/flutter/ios/Flutter.framework/Headers"
)

for DIR in "${FLUTTER_DIRS[@]}"; do
  mkdir -p "${DIR}"
  cat > "${DIR}/Flutter.h" << 'EOF'
// Minimal Flutter.h for bridging header compatibility
#ifndef FLUTTER_FLUTTER_H_
#define FLUTTER_FLUTTER_H_

#import <Foundation/Foundation.h>

@protocol FlutterPluginRegistry;
@class NSObject;

// Flutter plugin registry protocol
@protocol FlutterPluginRegistry <NSObject>
- (id)registrarForPlugin:(NSString*)pluginKey;
@end

#endif  // FLUTTER_FLUTTER_H_
EOF
  echo "✅ Created Flutter.h in ${DIR}"
done

# Create a .xcconfig file to add header search paths
HEADER_SEARCH_CONFIG="${SRCROOT}/Flutter/GeneratedHeaderPaths.xcconfig"
cat > "${HEADER_SEARCH_CONFIG}" << 'EOF'
// Additional header search paths for GeneratedPluginRegistrant.h
HEADER_SEARCH_PATHS = $(inherited) "$(SRCROOT)/Runner" "$(OBJROOT)/DerivedSources"
SWIFT_INCLUDE_PATHS = $(inherited) "$(SRCROOT)/Runner"
USE_HEADERMAP = YES
EOF

echo "✅ Created GeneratedHeaderPaths.xcconfig"

# Add an #include to the main xcconfig files
for CONFIG in Debug Release Profile; do
  CONFIG_PATH="${SRCROOT}/Flutter/${CONFIG}.xcconfig"
  if [ -f "${CONFIG_PATH}" ]; then
    if ! grep -q "GeneratedHeaderPaths.xcconfig" "${CONFIG_PATH}"; then
      echo "" >> "${CONFIG_PATH}"
      echo "#include \"GeneratedHeaderPaths.xcconfig\"" >> "${CONFIG_PATH}"
      echo "✅ Updated ${CONFIG}.xcconfig"
    fi
  fi
done

echo "🎉 Pre-build script completed successfully" 