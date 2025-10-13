# Android Turbo Native App Setup

This guide walks you through creating an Android app using Turbo Native for Rails Fast Epost.

## 📱 What You'll Build

A native Android app that wraps your Rails app with:
- ✅ Native navigation (back button, action bar)
- ✅ Native bottom navigation
- ✅ Push notifications (Firebase Cloud Messaging)
- ✅ Camera & photo access (optional)
- ✅ GPS location services (optional)
- ✅ Offline mode (optional)
- ✅ 95% code reuse from web app

## 🛠️ Prerequisites

### Required
- Java Development Kit (JDK) 17+
- Android Studio (latest version)
- Android SDK 24+ (Android 7.0+)
- Gradle 8.0+
- Active development server or deployed Rails app

### Optional (for distribution)
- Google Play Developer Account ($25 one-time)
- Physical Android device (for testing)

## 🚀 Step-by-Step Setup

### Step 1: Install Android Studio

```bash
# Download from: https://developer.android.com/studio
# Or on Ubuntu/Debian:
sudo snap install android-studio --classic

# On macOS with Homebrew:
brew install --cask android-studio
```

### Step 2: Install Android SDK

1. Open Android Studio
2. Welcome screen → More Actions → SDK Manager
3. Install:
   - Android SDK Platform 34 (Android 14)
   - Android SDK Build-Tools 34
   - Android Emulator
   - Intel x86 Emulator Accelerator (HAXM)

### Step 3: Create New Android Project

1. Android Studio → New Project
2. Choose: **Empty Activity**
3. Configure:
   - **Name**: `Rails Fast Epost`
   - **Package name**: `com.yourcompany.railsfastepost`
   - **Save location**: `~/AndroidProjects/RailsFastEpost`
   - **Language**: Kotlin
   - **Minimum SDK**: API 24 (Android 7.0)
   - **Build configuration**: Kotlin DSL (build.gradle.kts)

4. Click "Finish"

### Step 4: Add Turbo Native Dependency

Edit `app/build.gradle.kts`:
```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.yourcompany.railsfastepost"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.yourcompany.railsfastepost"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isDebuggable = true
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        viewBinding = true
    }
}

dependencies {
    // Turbo Native
    implementation("dev.hotwire:turbo:7.1.0")
    
    // AndroidX
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    implementation("androidx.navigation:navigation-fragment-ktx:2.7.6")
    implementation("androidx.navigation:navigation-ui-ktx:2.7.6")
    
    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    
    // Testing
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}
```

Sync Gradle: File → Sync Project with Gradle Files

### Step 5: Configure Base URLs

Create `Configuration.kt`:
```kotlin
// app/src/main/java/com/yourcompany/railsfastepost/Configuration.kt
package com.yourcompany.railsfastepost

object Configuration {
    // Production URL
    const val PRODUCTION_URL = "https://your-app.com"
    
    // Development URL (Codespace or local)
    const val DEVELOPMENT_URL = "https://laughing-space-barnacle-4wvqrgrg4653pw5x-3000.app.github.dev"
    
    // Current base URL (automatically switches)
    val BASE_URL: String
        get() = if (BuildConfig.DEBUG) DEVELOPMENT_URL else PRODUCTION_URL
    
    // Path configuration JSON
    val PATH_CONFIGURATION_URL: String
        get() = "$BASE_URL/turbo_native_paths.json"
    
    // User-Agent for native app
    const val USER_AGENT = "RailsFastEpost-Android/1.0"
}
```

**Replace the development URL with your Codespace URL or local server:**
- Codespace: Copy from "Ports" tab in VS Code
- Local: Use `http://10.0.2.2:3000` (Android emulator alias for localhost)

### Step 6: Create Main Navigation Activity

Create `MainActivity.kt`:
```kotlin
// app/src/main/java/com/yourcompany/railsfastepost/MainActivity.kt
package com.yourcompany.railsfastepost

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import com.google.android.material.bottomnavigation.BottomNavigationView
import dev.hotwire.turbo.config.TurboPathConfiguration
import dev.hotwire.turbo.session.TurboSessionNavHostFragment

class MainActivity : AppCompatActivity() {
    private lateinit var bottomNav: BottomNavigationView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // Setup bottom navigation
        bottomNav = findViewById(R.id.bottom_navigation)
        bottomNav.setOnItemSelectedListener { item ->
            when (item.itemId) {
                R.id.nav_home -> navigateToUrl(Configuration.BASE_URL)
                R.id.nav_tasks -> navigateToUrl("${Configuration.BASE_URL}/tasks")
                R.id.nav_customers -> navigateToUrl("${Configuration.BASE_URL}/customers")
            }
            true
        }

        // Load initial fragment
        if (savedInstanceState == null) {
            loadInitialFragment()
        }
    }

    private fun loadInitialFragment() {
        val fragment = TurboSessionNavHostFragment.newInstance(Configuration.BASE_URL)
        supportFragmentManager
            .beginTransaction()
            .replace(R.id.nav_host_container, fragment)
            .commit()
    }

    private fun navigateToUrl(url: String) {
        val fragment = currentNavHostFragment() ?: return
        fragment.session.visit(
            location = url,
            options = TurboVisitOptions(action = TurboVisitAction.ADVANCE)
        )
    }

    private fun currentNavHostFragment(): TurboSessionNavHostFragment? {
        return supportFragmentManager
            .findFragmentById(R.id.nav_host_container) as? TurboSessionNavHostFragment
    }

    override fun onBackPressed() {
        if (!currentNavHostFragment()?.onBackPressed()!!) {
            super.onBackPressed()
        }
    }
}
```

### Step 7: Create Layout Files

Create `res/layout/activity_main.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <FrameLayout
        android:id="@+id/nav_host_container"
        android:layout_width="0dp"
        android:layout_height="0dp"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintBottom_toTopOf="@id/bottom_navigation"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent" />

    <com.google.android.material.bottomnavigation.BottomNavigationView
        android:id="@+id/bottom_navigation"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:background="?android:attr/windowBackground"
        app:menu="@menu/bottom_navigation_menu"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent" />

</androidx.constraintlayout.widget.ConstraintLayout>
```

Create `res/menu/bottom_navigation_menu.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android">
    <item
        android:id="@+id/nav_home"
        android:icon="@android:drawable/ic_menu_home"
        android:title="Home" />
    <item
        android:id="@+id/nav_tasks"
        android:icon="@android:drawable/ic_menu_agenda"
        android:title="Tasks" />
    <item
        android:id="@+id/nav_customers"
        android:icon="@android:drawable/ic_menu_myplaces"
        android:title="Customers" />
</menu>
```

### Step 8: Create Web Fragment

Create `WebFragment.kt`:
```kotlin
// app/src/main/java/com/yourcompany/railsfastepost/WebFragment.kt
package com.yourcompany.railsfastepost

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.webkit.WebView
import dev.hotwire.turbo.fragments.TurboWebFragment
import dev.hotwire.turbo.nav.TurboNavGraphDestination

@TurboNavGraphDestination(uri = "turbo://fragment/web")
class WebFragment : TurboWebFragment() {
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_web, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        // Configure WebView
        configureWebView()
    }

    private fun configureWebView() {
        session.webView.apply {
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            settings.userAgentString = Configuration.USER_AGENT
        }
    }

    override fun onWebViewAttached(webView: WebView) {
        super.onWebViewAttached(webView)
        // WebView is ready
    }

    override fun onWebViewDetached(webView: WebView) {
        super.onWebViewDetached(webView)
        // Clean up if needed
    }
}
```

Create `res/layout/fragment_web.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <ProgressBar
        android:id="@+id/progress_bar"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_gravity="center"
        android:visibility="gone" />

</FrameLayout>
```

### Step 9: Configure AndroidManifest.xml

Update `app/src/main/AndroidManifest.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <!-- Required permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- Optional permissions -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <!-- Camera feature (optional, not required) -->
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    <uses-feature android:name="android.hardware.location.gps" android:required="false" />

    <application
        android:name=".App"
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.RailsFastEpost"
        android:usesCleartextTraffic="true"
        tools:targetApi="31">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.RailsFastEpost"
            android:configChanges="orientation|screenSize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
            
            <!-- Deep links -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="https" android:host="your-app.com" />
            </intent-filter>
        </activity>

    </application>

</manifest>
```

### Step 10: Create Application Class

Create `App.kt`:
```kotlin
// app/src/main/java/com/yourcompany/railsfastepost/App.kt
package com.yourcompany.railsfastepost

import android.app.Application
import dev.hotwire.turbo.config.Turbo
import dev.hotwire.turbo.config.TurboPathConfiguration

class App : Application() {
    override fun onCreate() {
        super.onCreate()
        
        // Configure Turbo
        Turbo.config.apply {
            pathConfiguration = TurboPathConfiguration.load(
                context = this@App,
                location = TurboPathConfiguration.Location.Remote(
                    url = Configuration.PATH_CONFIGURATION_URL
                )
            )
            
            userAgent = Configuration.USER_AGENT
            debugLoggingEnabled = BuildConfig.DEBUG
        }
    }
}
```

### Step 11: Add App Icons

1. Right-click `res` → New → Image Asset
2. Configure:
   - **Icon Type**: Launcher Icons (Adaptive and Legacy)
   - **Name**: ic_launcher
   - **Foreground Layer**: Upload your logo (512x512 PNG)
   - **Background Layer**: Choose color or image
3. Click "Next" → "Finish"

### Step 12: Configure Colors & Theme

Edit `res/values/themes.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.RailsFastEpost" parent="Theme.Material3.Light.NoActionBar">
        <!-- Primary brand color -->
        <item name="colorPrimary">@color/blue_500</item>
        <item name="colorPrimaryVariant">@color/blue_700</item>
        <item name="colorOnPrimary">@color/white</item>
        
        <!-- Secondary brand color -->
        <item name="colorSecondary">@color/teal_200</item>
        <item name="colorSecondaryVariant">@color/teal_700</item>
        <item name="colorOnSecondary">@color/black</item>
        
        <!-- Status bar -->
        <item name="android:statusBarColor">@color/blue_700</item>
    </style>
</resources>
```

Add `res/values/colors.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="blue_500">#3b82f6</color>
    <color name="blue_700">#1d4ed8</color>
    <color name="teal_200">#80CBC4</color>
    <color name="teal_700">#00796B</color>
    <color name="white">#FFFFFF</color>
    <color name="black">#000000</color>
</resources>
```

### Step 13: Test in Emulator

1. **Create emulator:**
   - Tools → Device Manager → Create Device
   - Choose: Pixel 6
   - System Image: Android 14 (API 34)
   - Click "Finish"

2. **Run app:**
   ```bash
   # In Android Studio: Run → Run 'app' (Shift+F10)
   # Or from command line:
   ./gradlew installDebug
   ```

3. **Debug:**
   - Chrome: `chrome://inspect`
   - Select your app's WebView
   - Open DevTools

### Step 14: Test on Real Device

1. **Enable Developer Options:**
   - Settings → About phone
   - Tap "Build number" 7 times

2. **Enable USB Debugging:**
   - Settings → System → Developer options
   - Enable "USB debugging"

3. **Connect device:**
   - Plug in via USB
   - Allow USB debugging prompt
   - Run app from Android Studio

## 🎨 Advanced Features

### Add Pull to Refresh

```kotlin
class WebFragment : TurboWebFragment() {
    private lateinit var swipeRefreshLayout: SwipeRefreshLayout

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        swipeRefreshLayout = view.findViewById(R.id.swipe_refresh)
        swipeRefreshLayout.setOnRefreshListener {
            session.reload()
            swipeRefreshLayout.isRefreshing = false
        }
    }
}
```

### Add Push Notifications (Firebase)

1. **Add Firebase:**
   - Tools → Firebase → Cloud Messaging
   - Connect to Firebase
   - Add FCM to your app

2. **Handle notifications:**
```kotlin
class MyFirebaseMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        // Show notification
        val notification = NotificationCompat.Builder(this, "default")
            .setContentTitle(remoteMessage.notification?.title)
            .setContentText(remoteMessage.notification?.body)
            .setSmallIcon(R.drawable.ic_notification)
            .build()
        
        NotificationManagerCompat.from(this).notify(0, notification)
    }
}
```

### Add Camera Access

```kotlin
class MainActivity : AppCompatActivity() {
    private val cameraPermission = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) {
            openCamera()
        }
    }

    fun requestCamera() {
        cameraPermission.launch(Manifest.permission.CAMERA)
    }
}
```

## 🚀 Deployment

### Generate Signed APK

1. **Create keystore:**
   ```bash
   keytool -genkey -v -keystore rails-fast-epost.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000
   ```

2. **Add to app/build.gradle.kts:**
   ```kotlin
   android {
       signingConfigs {
           create("release") {
               storeFile = file("../rails-fast-epost.keystore")
               storePassword = "your_password"
               keyAlias = "release"
               keyPassword = "your_password"
           }
       }
       
       buildTypes {
           release {
               signingConfig = signingConfigs.getByName("release")
           }
       }
   }
   ```

3. **Build:**
   ```bash
   ./gradlew assembleRelease
   # Output: app/build/outputs/apk/release/app-release.apk
   ```

### Generate AAB (App Bundle)

```bash
# For Google Play (recommended)
./gradlew bundleRelease
# Output: app/build/outputs/bundle/release/app-release.aab
```

### Google Play Console

1. **Create account:**
   - https://play.google.com/console
   - Pay $25 one-time fee

2. **Create app:**
   - Create app → Fill details
   - Upload icon, screenshots
   - Add description, privacy policy

3. **Upload AAB:**
   - Production → Create new release
   - Upload app-release.aab
   - Fill release notes
   - Review and rollout

4. **Wait 1-3 days** for review

## 📊 Analytics

### Add Firebase Analytics

```kotlin
// In App.kt
class App : Application() {
    override fun onCreate() {
        super.onCreate()
        FirebaseAnalytics.getInstance(this)
    }
}

// Track events
FirebaseAnalytics.getInstance(context).logEvent("page_view") {
    param("page_name", location)
}
```

## ✅ Testing Checklist

- [ ] App launches successfully
- [ ] Bottom navigation works
- [ ] Back button works correctly
- [ ] Forms submit correctly
- [ ] Authentication works
- [ ] Dark mode matches web
- [ ] RTL layout works (Arabic/Hebrew)
- [ ] Offline page appears
- [ ] Pull to refresh works
- [ ] Deep links work
- [ ] Push notifications work
- [ ] Camera works (if implemented)
- [ ] App icon displays
- [ ] Splash screen shows
- [ ] No crashes
- [ ] Smooth 60fps performance

## 📚 Resources

- **Turbo Android**: https://github.com/hotwired/turbo-android
- **Kotlin Docs**: https://kotlinlang.org/docs/home.html
- **Android Developers**: https://developer.android.com
- **Material Design**: https://material.io/develop/android

## 🎉 Success!

You now have a native Android app! 🎊

**Next steps:**
1. Test on multiple devices
2. Submit to Google Play
3. Celebrate! 🚀
