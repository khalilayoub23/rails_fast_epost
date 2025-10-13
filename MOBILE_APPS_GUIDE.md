# Hotwire Native Mobile Apps Guide

## 🎯 Overview

This Rails Fast Epost application supports **native iOS and Android apps** using **Turbo Native** (Hotwire). This means your existing Rails views work in native mobile apps with minimal additional code.

---

## 📱 Architecture

```
┌────────────────────────────────────────────────────────────┐
│                                                            │
│  Rails Backend (This App)                                 │
│  ├── Views (HTML + Turbo + Stimulus)                     │
│  ├── Controllers                                          │
│  └── Models & Business Logic                             │
│                                                            │
│  Served to all platforms via HTTP                         │
│                                                            │
└────────────────────────────────────────────────────────────┘
                          ↓
        ┌─────────────────┴─────────────────┐
        ↓                                   ↓
┌───────────────┐                   ┌───────────────┐
│  iOS App      │                   │  Android App  │
│  (Swift)      │                   │  (Kotlin)     │
│               │                   │               │
│  Turbo Native │                   │  Turbo Native │
│  WebView      │                   │  WebView      │
└───────────────┘                   └───────────────┘
```

---

## ✅ What's Already Done

Your Rails app is now ready for Turbo Native:

### 1. Mobile Meta Tags ✅
- Viewport configured for mobile
- PWA-ready
- iOS status bar styling
- Theme color set

### 2. Turbo Native Helpers ✅
- `turbo_native_app?` - Detect native app requests
- `turbo_native_ios?` - Detect iOS app
- `turbo_native_android?` - Detect Android app

### 3. Path Configuration ✅
- `public/turbo_native_paths.json` - Defines navigation behavior
- Modal vs default presentation
- Context switching

### 4. Controller Support ✅
- `TurboNativeSupport` concern included
- Native bridge actions
- Platform-specific headers

---

## 🍎 iOS App Setup

### Prerequisites
- macOS with Xcode 15+
- CocoaPods or Swift Package Manager
- Apple Developer account (for App Store)

### Quick Start

1. **Create iOS Project**
   ```bash
   # Clone the Turbo iOS demo
   git clone https://github.com/hotwired/turbo-ios
   cd turbo-ios/Demo
   ```

2. **Configure Base URL**
   
   Edit `Demo/SceneDelegate.swift`:
   ```swift
   private let baseURL = URL(string: "https://your-domain.com")!
   // For development: http://localhost:3000 or your Codespace URL
   ```

3. **Update Path Configuration URL**
   
   In `Demo/PathConfiguration.swift`:
   ```swift
   let pathConfigurationURL = URL(string: "https://your-domain.com/turbo_native_paths.json")!
   ```

4. **Customize App**
   - Update bundle identifier
   - Add your app icon
   - Configure navigation bar style
   - Set up tab bar (if needed)

5. **Run in Simulator**
   ```bash
   open Demo.xcodeproj
   # Press Cmd+R in Xcode
   ```

### Key Files to Customize

```
Demo/
├── SceneDelegate.swift       # Base URL, initial navigation
├── PathConfiguration.swift   # Path rules from Rails
├── Assets.xcassets/          # App icon, images
├── Info.plist                # App configuration
└── ViewController.swift      # Custom native screens (optional)
```

---

## 🤖 Android App Setup

### Prerequisites
- Android Studio Hedgehog+
- JDK 17+
- Android SDK
- Google Play Developer account (for Play Store)

### Quick Start

1. **Create Android Project**
   ```bash
   # Clone the Turbo Android demo
   git clone https://github.com/hotwired/turbo-android
   cd turbo-android/demo
   ```

2. **Configure Base URL**
   
   Edit `demo/src/main/kotlin/dev/hotwire/turbo/demo/main/MainActivity.kt`:
   ```kotlin
   private const val BASE_URL = "https://your-domain.com"
   // For development: http://10.0.2.2:3000 (Android emulator)
   ```

3. **Update Path Configuration URL**
   
   In path configuration:
   ```kotlin
   private const val PATH_CONFIGURATION_URL = "https://your-domain.com/turbo_native_paths.json"
   ```

4. **Customize App**
   - Update `build.gradle` (applicationId, version)
   - Add launcher icon
   - Configure theme colors
   - Set up bottom navigation (if needed)

5. **Run in Emulator**
   ```bash
   # In Android Studio, click Run button or
   ./gradlew installDebug
   ```

### Key Files to Customize

```
app/
├── src/main/kotlin/
│   └── MainActivity.kt           # Base URL, navigation
├── src/main/res/
│   ├── values/colors.xml         # Theme colors
│   ├── values/strings.xml        # App name
│   └── mipmap/ic_launcher/       # App icon
└── build.gradle                  # App configuration
```

---

## 🔧 Development Workflow

### 1. Develop in Rails

```bash
# Start Rails server
bin/dev

# Your app is now available at:
# - Web: http://localhost:3000
# - iOS Simulator: http://localhost:3000 (or Codespace URL)
# - Android Emulator: http://10.0.2.2:3000
```

### 2. Test in Browser First

All features should work in a regular web browser before testing in native apps.

### 3. Test in iOS Simulator

```bash
# Make sure Rails is running
bin/dev

# In Xcode, run the iOS app
# It will load your Rails views
```

### 4. Test in Android Emulator

```bash
# Make sure Rails is running
bin/dev

# In Android Studio, run the Android app
# It will load your Rails views
```

### 5. Deploy Changes

```bash
# Deploy Rails app
kamal deploy

# Native apps automatically get updates!
# No need to rebuild or resubmit to stores for content changes
```

---

## 📲 Native Features Integration

### Camera Access

**Rails View:**
```erb
<%= button_to "Take Photo", "#", 
    data: { 
      turbo_native_action: "camera",
      turbo_native_message: "{ \"action\": \"capturePhoto\" }" 
    } %>
```

**iOS (Swift):**
```swift
func capturePhoto() {
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    present(picker, animated: true)
}
```

### GPS/Location

**Rails View:**
```erb
<%= button_to "Get Location", "#",
    data: { 
      turbo_native_action: "location",
      turbo_native_message: "{ \"action\": \"getCurrentLocation\" }"
    } %>
```

### Push Notifications

Configure in native apps using FCM (Firebase Cloud Messaging) for both platforms.

---

## 🎨 UI Optimization Tips

### 1. Hide Sidebar on Mobile

```erb
<% unless turbo_native_app? %>
  <%= render "shared/sidebar" %>
<% end %>
```

### 2. Show Native Navigation

```erb
<% if turbo_native_app? %>
  <!-- Native app handles navigation -->
<% else %>
  <%= render "shared/top_nav" %>
<% end %>
```

### 3. Platform-Specific Styles

```erb
<div class="<%= turbo_native_ios? ? 'ios-style' : 'android-style' %>">
  <!-- Content -->
</div>
```

---

## 🚀 Deployment Checklist

### Rails Backend

- [ ] Deploy to production (Kamal)
- [ ] Ensure HTTPS is enabled
- [ ] Configure CORS if needed
- [ ] Test all endpoints work
- [ ] Verify `turbo_native_paths.json` is accessible

### iOS App

- [ ] Update bundle identifier
- [ ] Set production base URL
- [ ] Add app icon (all sizes)
- [ ] Configure app capabilities (camera, location, etc.)
- [ ] Test on real device
- [ ] Create App Store screenshots
- [ ] Submit to App Store Connect
- [ ] Fill app information
- [ ] Submit for review

### Android App

- [ ] Update applicationId
- [ ] Set production base URL
- [ ] Add launcher icon (all densities)
- [ ] Configure permissions (camera, location, etc.)
- [ ] Generate signed APK/AAB
- [ ] Test on real device
- [ ] Create Play Store screenshots
- [ ] Create Play Store listing
- [ ] Submit to Google Play Console
- [ ] Submit for review

---

## 📊 Path Configuration Guide

The `turbo_native_paths.json` file controls how URLs are presented in the app.

### Presentation Types

**default**: Standard navigation (push onto stack)
```json
{
  "patterns": ["/tasks"],
  "properties": {
    "presentation": "default"
  }
}
```

**modal**: Show as modal (can dismiss)
```json
{
  "patterns": ["/tasks/new"],
  "properties": {
    "presentation": "modal"
  }
}
```

**replace**: Replace current screen
```json
{
  "patterns": ["/login"],
  "properties": {
    "presentation": "replace"
  }
}
```

### Context Types

**default**: Main flow
**modal**: Modal flow (separate navigation stack)

---

## 🐛 Troubleshooting

### iOS: "Cannot connect to server"

1. Check Rails server is running
2. Use correct URL (not localhost if on device)
3. Check Info.plist allows HTTP (for development)

### Android: "ERR_CONNECTION_REFUSED"

1. Use `10.0.2.2:3000` for emulator (not localhost)
2. Check firewall allows connections
3. Verify Rails server is running

### Content not updating

1. Kill and restart native app
2. Clear app cache
3. Redeploy Rails app
4. Check path configuration JSON

---

## 📚 Resources

- [Turbo Native iOS Documentation](https://github.com/hotwired/turbo-ios)
- [Turbo Native Android Documentation](https://github.com/hotwired/turbo-android)
- [Hotwire Handbook](https://turbo.hotwired.dev/handbook/native)
- [Native Bridges Guide](https://masilotti.com/turbo-native/)

---

## 🎯 Next Steps

1. **Week 1**: Set up iOS project, test basic navigation
2. **Week 2**: Set up Android project, test basic navigation
3. **Week 3**: Add native features (camera, GPS, push notifications)
4. **Week 4**: Polish UI, test on devices, submit to stores

---

**Ready to build mobile apps? Let's go!** 🚀
