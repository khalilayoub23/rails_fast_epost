# iOS Turbo Native App Setup

This guide walks you through creating an iOS app using Turbo Native for Rails Fast Epost.

## 📱 What You'll Build

A native iOS app that wraps your Rails app with:
- ✅ Native navigation (back/forward buttons)
- ✅ Native tab bar
- ✅ Push notifications support (optional)
- ✅ Camera & photo access (optional)
- ✅ GPS location services (optional)
- ✅ Offline mode (optional)
- ✅ 95% code reuse from web app

## 🛠️ Prerequisites

### Required
- macOS computer (required for iOS development)
- Xcode 15+ (free from App Store)
- Swift 5.9+ (included with Xcode)
- CocoaPods or SPM (package manager)
- Active development server or deployed Rails app

### Optional (for distribution)
- Apple Developer Account ($99/year)
- Physical iOS device (for testing on real hardware)

## 🚀 Step-by-Step Setup

### Step 1: Install Xcode
```bash
# Download from App Store or:
xcode-select --install
```

### Step 2: Clone Turbo iOS
```bash
cd ~/Projects  # Or your preferred directory
git clone https://github.com/hotwired/turbo-ios.git
cd turbo-ios
```

### Step 3: Create New iOS Project

1. Open Xcode
2. Click "Create a new Xcode project"
3. Choose "iOS" → "App"
4. Fill in:
   - **Product Name**: `RailsFastEpost`
   - **Team**: Your Apple ID or None
   - **Organization Identifier**: `com.yourcompany.railsfastepost`
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Storage**: None
   - **Testing**: Include Tests (optional)

5. Save to: `~/Projects/RailsFastEpostIOS`

### Step 4: Install Turbo Native

#### Option A: Swift Package Manager (Recommended)
1. In Xcode: File → Add Package Dependencies
2. Enter URL: `https://github.com/hotwired/turbo-ios`
3. Version: Up to Next Major (2.0.0 or latest)
4. Click "Add Package"
5. Select "Turbo" and click "Add Package"

#### Option B: CocoaPods
```bash
cd ~/Projects/RailsFastEpostIOS

# Create Podfile
cat > Podfile <<'EOF'
platform :ios, '14.0'
use_frameworks!

target 'RailsFastEpost' do
  pod 'Turbo', '~> 7.0'
end
EOF

# Install
pod install

# Open workspace (not xcodeproj)
open RailsFastEpost.xcworkspace
```

### Step 5: Configure Base URL

Create `Configuration.swift`:
```swift
// Configuration.swift
import Foundation

enum Configuration {
    // MARK: - Server URLs
    
    /// Production server URL
    static let productionURL = URL(string: "https://your-app.com")!
    
    /// Development server URL (Codespace or local)
    static let developmentURL = URL(string: "https://laughing-space-barnacle-4wvqrgrg4653pw5x-3000.app.github.dev")!
    
    /// Current base URL (switch between dev/prod)
    static var baseURL: URL {
        #if DEBUG
        return developmentURL
        #else
        return productionURL
        #endif
    }
    
    // MARK: - Path Configuration
    
    /// Path configuration JSON URL
    static var pathConfigurationURL: URL {
        return baseURL.appendingPathComponent("/turbo_native_paths.json")
    }
    
    /// User-Agent string for native app
    static let userAgent = "RailsFastEpost-iOS/1.0"
}
```

**Replace the development URL with your Codespace URL or local server:**
- Codespace: Copy from "Ports" tab in VS Code
- Local: `http://localhost:3000` (requires ngrok for HTTPS)

### Step 6: Create Main Navigation

Create `NavigationController.swift`:
```swift
// NavigationController.swift
import UIKit
import Turbo
import WebKit

class NavigationController: UINavigationController {
    private lazy var session = Session()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure session
        session.delegate = self
        session.pathConfiguration = PathConfiguration(sources: [
            .server(Configuration.pathConfigurationURL)
        ])
        
        // Set custom User-Agent
        session.webView.customUserAgent = Configuration.userAgent
        
        // Visit root URL
        visit(url: Configuration.baseURL)
    }
    
    private func visit(url: URL, action: VisitAction = .advance) {
        let viewController = VisitableViewController(url: url)
        session.visit(viewController, action: action)
        
        if action == .advance {
            pushViewController(viewController, animated: true)
        } else {
            replaceViewController(viewController)
        }
    }
    
    private func replaceViewController(_ viewController: UIViewController) {
        var viewControllers = self.viewControllers
        viewControllers[viewControllers.count - 1] = viewController
        setViewControllers(viewControllers, animated: false)
    }
}

// MARK: - SessionDelegate
extension NavigationController: SessionDelegate {
    func session(_ session: Session, didProposeVisit proposal: VisitProposal) {
        visit(url: proposal.url, action: proposal.options.action)
    }
    
    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func sessionWebViewProcessDidTerminate(_ session: Session) {
        session.reload()
    }
}
```

### Step 7: Update App Entry Point

#### For SwiftUI App:
Update `RailsFastEpostApp.swift`:
```swift
import SwiftUI

@main
struct RailsFastEpostApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView()
        }
    }
}

struct NavigationView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> NavigationController {
        return NavigationController()
    }
    
    func updateUIViewController(_ uiViewController: NavigationController, context: Context) {
        // No updates needed
    }
}
```

#### For UIKit App:
Update `SceneDelegate.swift`:
```swift
func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }
    
    window = UIWindow(windowScene: windowScene)
    window?.rootViewController = NavigationController()
    window?.makeKeyAndVisible()
}
```

### Step 8: Configure Info.plist

Add these keys to `Info.plist`:

```xml
<!-- Allow HTTP connections in development -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <!-- Or specific domains -->
    <key>NSExceptionDomains</key>
    <dict>
        <key>localhost</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
        <key>app.github.dev</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
        </dict>
    </dict>
</dict>

<!-- Camera access (optional) -->
<key>NSCameraUsageDescription</key>
<string>We need camera access to take photos for documents.</string>

<!-- Photo library access (optional) -->
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to select images.</string>

<!-- Location access (optional) -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby carriers.</string>
```

### Step 9: Add App Icon

1. Generate app icons: Use https://appicon.co
2. Upload a 1024x1024 PNG logo
3. Download iOS icons
4. In Xcode: Assets.xcassets → AppIcon
5. Drag all sizes into their slots

### Step 10: Configure Launch Screen

Edit `LaunchScreen.storyboard`:
```swift
// Or create LaunchScreen.swift for SwiftUI
struct LaunchScreen: View {
    var body: some View {
        ZStack {
            Color.blue
            VStack {
                Image(systemName: "doc.text")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                Text("Rails Fast Epost")
                    .font(.title)
                    .foregroundColor(.white)
            }
        }
        .ignoresSafeArea()
    }
}
```

### Step 11: Test in Simulator

```bash
# Build and run
# In Xcode: Product → Run (Cmd+R)
# Or from command line:
xcodebuild -scheme RailsFastEpost -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' build
```

**Simulator shortcuts:**
- `Cmd+R` - Build and run
- `Cmd+.` - Stop
- `Hardware → Shake` - Open dev menu
- `Device → Rotate Left/Right` - Test rotation

### Step 12: Test on Real Device

1. Connect iPhone via USB
2. In Xcode: Window → Devices and Simulators
3. Select your device
4. Top toolbar: Select your iPhone
5. Click Run (Cmd+R)
6. On phone: Settings → General → Device Management
7. Trust developer certificate

## 🎨 Advanced Features

### Add Tab Bar Navigation

Create `TabBarController.swift`:
```swift
import UIKit

class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let homeNav = NavigationController()
        homeNav.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        
        let tasksNav = NavigationController()
        tasksNav.visit(url: Configuration.baseURL.appendingPathComponent("/tasks"))
        tasksNav.tabBarItem = UITabBarItem(
            title: "Tasks",
            image: UIImage(systemName: "checklist"),
            selectedImage: UIImage(systemName: "checklist")
        )
        
        let customersNav = NavigationController()
        customersNav.visit(url: Configuration.baseURL.appendingPathComponent("/customers"))
        customersNav.tabBarItem = UITabBarItem(
            title: "Customers",
            image: UIImage(systemName: "person.2"),
            selectedImage: UIImage(systemName: "person.2.fill")
        )
        
        viewControllers = [homeNav, tasksNav, customersNav]
    }
}
```

### Add Pull to Refresh

```swift
extension NavigationController {
    func setupPullToRefresh() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        session.webView.scrollView.refreshControl = refreshControl
    }
    
    @objc func handleRefresh(_ sender: UIRefreshControl) {
        session.reload()
        sender.endRefreshing()
    }
}
```

### Add Push Notifications

1. Enable capability: Signing & Capabilities → Push Notifications
2. Create `NotificationService.swift`:
```swift
import UserNotifications

class NotificationService {
    static func register() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
}
```

3. Update `AppDelegate.swift`:
```swift
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("Device Token: \(token)")
    // Send token to Rails backend
}
```

## 🚀 Deployment

### TestFlight (Beta Testing)

1. **Create App in App Store Connect:**
   - https://appstoreconnect.apple.com
   - My Apps → + → New App
   - Fill in app details

2. **Archive the app:**
   ```bash
   # In Xcode
   Product → Archive
   # Wait for build to complete
   # Window → Organizer → Distribute App
   ```

3. **Upload to TestFlight:**
   - Select "App Store Connect"
   - Choose "Upload"
   - Wait for processing (15-30 min)
   - Add beta testers via email

4. **Share TestFlight link:**
   - App Store Connect → TestFlight
   - External Testing → Add Testers
   - Send invite link

### App Store Release

1. **Prepare metadata:**
   - Screenshots (all sizes)
   - App description
   - Keywords
   - Support URL
   - Privacy policy URL

2. **Submit for review:**
   - App Store Connect → My Apps
   - Select version
   - Fill all required fields
   - Submit for Review

3. **Wait 1-3 days** for Apple review

4. **Release:**
   - Once approved, click "Release"
   - App goes live in 24 hours

## 📊 Analytics & Monitoring

### Add Firebase Analytics

```swift
// In Podfile
pod 'Firebase/Analytics'

// In AppDelegate
import Firebase

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    FirebaseApp.configure()
    return true
}
```

### Track Screen Views

```swift
extension NavigationController {
    func session(_ session: Session, didProposeVisit proposal: VisitProposal) {
        // Track page view
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: proposal.url.path
        ])
        
        visit(url: proposal.url, action: proposal.options.action)
    }
}
```

## 🐛 Debugging Tips

### View Web Console

```swift
// Add to NavigationController
#if DEBUG
extension NavigationController: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        print("JS Alert: \(message)")
        completionHandler()
    }
}
#endif
```

### Enable Safari Web Inspector

1. iPhone: Settings → Safari → Advanced → Web Inspector
2. Mac: Safari → Develop → [Your iPhone] → [Your App]

### Print Network Requests

```swift
session.webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
    print("Cookies: \(cookies)")
}
```

## ✅ Testing Checklist

- [ ] App launches successfully
- [ ] Navigation works (back/forward)
- [ ] Forms submit correctly
- [ ] Authentication works
- [ ] Dark mode matches web
- [ ] RTL layout works (Arabic/Hebrew)
- [ ] Offline page appears when disconnected
- [ ] Pull to refresh works
- [ ] Deep links work
- [ ] Push notifications work (if implemented)
- [ ] Camera/photos work (if implemented)
- [ ] App icon displays correctly
- [ ] Launch screen shows properly
- [ ] No console errors
- [ ] Performance is smooth (60fps)

## 📚 Resources

- **Turbo iOS Docs**: https://github.com/hotwired/turbo-ios
- **SwiftUI Tutorial**: https://developer.apple.com/tutorials/swiftui
- **App Store Guidelines**: https://developer.apple.com/app-store/review/guidelines/
- **HIG (Design)**: https://developer.apple.com/design/human-interface-guidelines/

## 🎉 Success!

You now have a native iOS app powered by your Rails backend! 🚀

**Next steps:**
1. Test on real devices
2. Add TestFlight beta testers
3. Submit to App Store
4. Celebrate! 🎊
