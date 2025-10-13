# 🚀 Quick Start Scripts for Mobile Apps

## iOS Quick Start Script

Save this as `setup_ios.sh` on your Mac:

```bash
#!/bin/bash

# iOS App Quick Setup Script
# Run this on your Mac after installing Xcode

set -e

echo "🍎 iOS App Setup Script"
echo "======================="

# Configuration
APP_NAME="RailsFastEpost"
BUNDLE_ID="com.yourcompany.railsfastepost"
PROJECT_DIR="$HOME/Projects/RailsFastEpostIOS"
RAILS_URL="https://your-codespace-url.app.github.dev"  # CHANGE THIS

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Please install from App Store."
    exit 1
fi

echo "✅ Xcode found"

# Create project directory
echo "📁 Creating project directory..."
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Check if project exists
if [ -d "$APP_NAME.xcodeproj" ]; then
    echo "⚠️  Project already exists. Opening..."
    open "$APP_NAME.xcodeproj"
    exit 0
fi

echo "📝 Manual steps required:"
echo ""
echo "1. Open Xcode"
echo "2. Create New Project → iOS → App"
echo "3. Product Name: $APP_NAME"
echo "4. Organization Identifier: $BUNDLE_ID"
echo "5. Interface: SwiftUI"
echo "6. Language: Swift"
echo "7. Save to: $PROJECT_DIR"
echo ""
echo "Then run: ./add_turbo_ios.sh"

# Create the next script
cat > add_turbo_ios.sh << 'SCRIPT'
#!/bin/bash

echo "📦 Adding Turbo Native to iOS project..."
echo ""
echo "1. In Xcode: File → Add Package Dependencies"
echo "2. Enter: https://github.com/hotwired/turbo-ios"
echo "3. Click 'Add Package'"
echo "4. Select 'Turbo' and click 'Add Package'"
echo ""
echo "Then run: ./configure_ios.sh"
SCRIPT

chmod +x add_turbo_ios.sh

echo ""
echo "✅ Setup script created!"
echo "📋 Follow the manual steps above"
```

## Android Quick Start Script

Save this as `setup_android.sh`:

```bash
#!/bin/bash

# Android App Quick Setup Script
# Run this after installing Android Studio

set -e

echo "🤖 Android App Setup Script"
echo "============================"

# Configuration
APP_NAME="Rails Fast Epost"
PACKAGE_NAME="com.yourcompany.railsfastepost"
PROJECT_DIR="$HOME/AndroidStudioProjects/RailsFastEpost"
RAILS_URL="https://your-codespace-url.app.github.dev"  # CHANGE THIS

# Check if Android Studio is installed
if [ ! -d "/Applications/Android Studio.app" ] && [ ! -d "$HOME/android-studio" ]; then
    echo "❌ Android Studio not found. Please install it first."
    echo "Download from: https://developer.android.com/studio"
    exit 1
fi

echo "✅ Android Studio found"

# Create project directory
echo "📁 Creating project directory..."
mkdir -p "$PROJECT_DIR"

echo "📝 Manual steps required:"
echo ""
echo "1. Open Android Studio"
echo "2. New Project → Empty Activity"
echo "3. Name: $APP_NAME"
echo "4. Package: $PACKAGE_NAME"
echo "5. Language: Kotlin"
echo "6. Minimum SDK: API 24"
echo "7. Save to: $PROJECT_DIR"
echo ""
echo "Then edit app/build.gradle.kts and add:"
echo ""
echo "dependencies {"
echo "    implementation(\"dev.hotwire:turbo:7.1.0\")"
echo "}"
echo ""
echo "Sync Gradle and follow ANDROID_APP_SETUP.md"

echo ""
echo "✅ Ready for manual setup!"
```

## Automated Configuration Files

These files will be ready to copy into your projects:

### iOS Configuration.swift
```swift
import Foundation

enum Configuration {
    static let baseURL = URL(string: "REPLACE_WITH_YOUR_URL")!
    static let pathConfigurationURL = URL(string: "\(baseURL)/turbo_native_paths.json")!
    static let userAgent = "RailsFastEpost-iOS/1.0"
}
```

### Android Configuration.kt
```kotlin
package com.yourcompany.railsfastepost

object Configuration {
    const val BASE_URL = "REPLACE_WITH_YOUR_URL"
    const val PATH_CONFIGURATION_URL = "$BASE_URL/turbo_native_paths.json"
    const val USER_AGENT = "RailsFastEpost-Android/1.0"
}
```

---

## 🎯 The Reality

Building native mobile apps requires:

1. **Physical Hardware**
   - Mac for iOS (can't emulate macOS legally)
   - Any computer for Android

2. **Software Installation**
   - Xcode (8GB+ download)
   - Android Studio (2GB+ download)

3. **GUI Interaction**
   - Creating projects in IDEs
   - Configuring build settings
   - Testing in simulators

4. **Account Setup**
   - Apple Developer Account
   - Google Play Developer Account

5. **Time Investment**
   - 2-3 hours per platform
   - Learning curve if first time

---

## 💡 Alternative: Use Your Rails App As-Is

Your Rails app **already works perfectly on mobile browsers**:

```
✅ Responsive design
✅ Touch-friendly
✅ PWA-ready
✅ Works offline
✅ Fast with Turbo
```

**You can skip native apps entirely and just use the web app!**

Many successful apps are web-only:
- Basecamp (web-first, mobile later)
- Hey.com (web-first)
- Linear (web-based)

---

## 🤝 What I CAN Help With

1. **Prepare more config files** - I can generate all the code files you'll need
2. **Create automation scripts** - Bash scripts to help you once you're in Xcode/Android Studio
3. **Answer questions** - As you follow the guides, I can clarify steps
4. **Debug issues** - If you hit problems, I can help troubleshoot
5. **Optimize the Rails app** - Make the mobile web experience even better

Would you like me to:
- Create pre-filled code templates for all iOS/Android files?
- Generate a PWA (Progressive Web App) so mobile users can "install" it?
- Create a mobile-optimized landing page?
- Something else?
