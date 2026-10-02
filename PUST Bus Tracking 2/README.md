# PUST Bus Tracking - iOS Application 🚍📱
### পাবনা বিজ্ঞান ও প্রযুক্তি বিশ্ববিদ্যালয় (PUST)

**PUST Bus Tracking** হলো পাবনা বিজ্ঞান ও প্রযুক্তি বিশ্ববিদ্যালয়ের শিক্ষক, শিক্ষার্থী ও কর্মকর্তা-কর্মচারীদের জন্য একটি আধুনিক, রিয়েল-টাইম বাস ট্র্যাকিং এবং ট্রান্সপোর্ট ম্যানেজমেন্ট iOS অ্যাপ।

---

## 📱 App Highlights & Features

- **Smooth Animated Splash Screen**: রিয়েল-টাইম রাডার পাল্স এনিমেশন, ব্র্যান্ডেড লোগো এবং স্মুথ ট্রানজিশন সহ নেটিভ সুইফটইউআই স্প্ল্যাশ স্ক্রিন।
- **Live Bus Tracking & Interactive Map**: ম্যাপ ভিউতে বাসের অবস্থান, স্পিড, পরবর্তী স্টপেজ এবং এস্টিমেটেড অ্যারাইভাল টাইম (ETA)।
- **Smart Route Navigation**: বিশ্ববিদ্যালয়ের সকল বাস রুট ও স্টপেজের পূর্ণাঙ্গ তালিকা ও টাইমটেবিল।
- **Student ID & QR Verification**: ক্যামেরা ইন্টিগ্রেশন সহ স্টুডেন্ট কার্ড ও কিউআর যাচাইকরণ।
- **Apple Safe Area & Dark Mode**: iOS Safe Area (Dynamic Island / Notch) এবং ডার্ক মোডের সম্পূর্ণ সাপোর্ট।
- **Native iOS Geolocation & WebKit**: হাই-পারফর্মেন্স `WKWebView` এবং `CoreLocation` ইন্টিগ্রেশন।

---

## 🛠 Project Structure

```text
PUSTBusTracking/
├── AGENTS.md                         # AI / contributor guide (file map, rules)
├── .gitignore
├── supabase_push_notifications.sql   # Push token table + chat trigger (Supabase)
├── supabase/
│   └── functions/send-chat-push/
│       └── index.ts                  # Edge Function: APNs push notifications
├── PUSTBusTracking.xcodeproj/       # Xcode Project File
│   └── project.pbxproj
├── PUSTBusTracking/
│   ├── App/
│   │   ├── PUSTBusTrackingApp.swift  # SwiftUI Main Entry Point + AppDelegate
│   │   ├── ContentView.swift        # Main View Coordinator
│   │   ├── SplashScreenView.swift   # Smooth Animated Splash Screen
│   │   ├── WebViewContainer.swift   # WKWebView Native Bridge
│   │   ├── LocationManager.swift    # CoreLocation Authorization Bridge
│   │   └── NotificationManager.swift # Local & Push Notification Handling
│   ├── Resources/
│   │   ├── index.html               # Original Unchanged Web Application
│   │   └── Assets.xcassets/         # App Icons, Splash Logos & Color sets
│   │       ├── AppIcon.appiconset/  # 1024x1024, iPhone & iPad All Sizes
│   │       ├── SplashLogo.imageset/ # 1x, 2x, 3x High-Res Bus Logos
│   │       └── AccentColor.colorset/# PUST Brand Crimson & Navy Palette
│   └── Info.plist                   # App Permissions & Metadata
```

> 🤖 AI assistant বা নতুন contributor হলে আগে [`AGENTS.md`](AGENTS.md) পড়ুন — সেখানে প্রতিটি ফাইলের কাজ,
> `index.html`-এর সেকশন ম্যাপ এবং Supabase/APNs সেটআপ দেওয়া আছে।

---

## 🚀 How to Run in Xcode (ম্যাকবুকে কীভাবে রান করবেন)

1. **প্রজেক্ট ওপেন করুন**:
   - `PUSTBusTracking.xcodeproj` ফাইলে ডাবল-ক্লিক করে Xcode এ ওপেন করুন।
2. **Signing & Team নির্বাচন করুন**:
   - Xcode এর বাম পাশের সাইডবারে `PUSTBusTracking` প্রজেক্ট রুটে ক্লিক করুন।
   - **Signing & Capabilities** ট্যাবে গিয়ে আপনার Apple Developer Account / Personal Team নির্বাচন করুন।
3. **সিমুলেটর অথবা রিয়েল ডিভাইস সিলেক্ট করুন**:
   - উপরের বার থেকে যেকোনো iPhone (যেমন: `iPhone 16 Pro` বা `iPhone 15`) সিলেক্ট করুন।
4. **বিল্ড এবং রান করুন**:
   - `⌘ + R` (Cmd + R) প্রেস করুন অথবা প্লে (▶️) বাটনে ক্লিক করুন।

---

## 🔐 Permissions Included (Info.plist)

- `NSLocationWhenInUseUsageDescription`: লাইভ ক্যাম্পাস বাস এবং নিকটস্থ রুট খোঁজার লোকেশন অনুমতি।
- `NSLocationAlwaysAndWhenInUseUsageDescription`: ব্যাকগ্রাউন্ড বা রিয়েল-টাইম আপডেট পাওয়ার অনুমতি।
- `NSCameraUsageDescription`: স্টুডেন্ট আইডি ও কিউআর কোড স্ক্যান করার জন্য ক্যামেরা অনুমতি।
- `NSAppTransportSecurity`: রিয়েল-টাইম ম্যাপ ও সুপাবেজ এপিআই লোড করার সাপোর্ট।

---

## 📦 App Store Submission Ready

- Bundle Identifier: `edu.pust.bustracking`
- Deployment Target: `iOS 15.0+`
- App Icon: 1024x1024 Marketing Icon ও সকল ডিভাইস ভ্যারিয়েন্ট অন্তর্ভুক্ত।

---

## 🔔 Push Notifications & Backend (Supabase)

- `supabase_push_notifications.sql` — `device_push_tokens` টেবিল ও চ্যাটের নতুন মেসেজে ট্রিগার সেটআপ।
- `supabase/functions/send-chat-push/index.ts` — Apple APNs এর মাধ্যমে অ্যাপ বন্ধ থাকলেও নোটিফিকেশন পাঠায়।
- Edge Function secrets: `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_PRIVATE_KEY`, `APNS_BUNDLE_ID`, `APNS_ENVIRONMENT`।
  এগুলো কখনো GitHub-এ commit করবেন না (`.p8` ফাইল `.gitignore`-এ আছে)।
