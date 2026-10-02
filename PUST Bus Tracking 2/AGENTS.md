# AGENTS.md — AI / contributor guide for PUST Bus Tracking

This file is written for AI coding assistants (ChatGPT, Gemini, Copilot, Cursor, Claude, etc.)
and for new contributors. Read it first; it tells you what every file does and where to look.

## 1. What this project is

- **Name:** PUST Bus Tracking (পাবনা বিজ্ঞান ও প্রযুক্তি বিশ্ববিদ্যালয় / Pabna University of Science and Technology)
- **Type:** iOS app (SwiftUI shell) that hosts a **single-file web app** (`index.html`) inside a `WKWebView`.
- **Backend:** Supabase (Postgres + Auth + Realtime + Edge Function) and Apple Push Notifications (APNs).
- **Languages in UI:** Bangla + English (translation table inside `index.html`).
- **Bundle ID:** `edu.pust.bustracking` · **Min iOS:** 15.0

Almost all product logic (UI, map, chat, timetable, login) lives in ONE file:
`PUSTBusTracking/Resources/index.html` (~6,500 lines, ~350 KB, plain HTML + CSS + vanilla JS, no build step).
The Swift code is a thin native bridge (location, notifications, splash screen, WebView).

## 2. Repository map

```text
.
├── AGENTS.md                              # this file
├── README.md                              # human-facing overview (Bangla)
├── .gitignore                             # ignores .DS_Store, xcuserdata, secrets, build output
├── supabase_push_notifications.sql        # device_push_tokens table + chat_messages -> push trigger
├── supabase/
│   └── functions/send-chat-push/index.ts  # Deno Edge Function: sends APNs push for new chat messages
├── PUSTBusTracking.xcodeproj/
│   └── project.pbxproj                    # Xcode project (targets, signing, deployment target)
└── PUSTBusTracking/
    ├── Info.plist                         # permissions (location, camera), background modes, ATS
    ├── App/
    │   ├── PUSTBusTrackingApp.swift       # @main entry + AppDelegate (APNs token registration)
    │   ├── ContentView.swift              # shows splash, then the web view
    │   ├── SplashScreenView.swift         # animated radar-pulse splash
    │   ├── WebViewContainer.swift         # WKWebView + JS<->native message bridge
    │   ├── LocationManager.swift          # CoreLocation wrapper, pushes GPS to the web page
    │   └── NotificationManager.swift      # local/remote notification permission + display
    └── Resources/
        ├── index.html                     # THE WEB APP (see section 4)
        └── Assets.xcassets/               # AppIcon, SplashLogo (1x/2x/3x), AccentColor
```

## 3. How the pieces talk to each other

**Web page -> native** (`window.webkit.messageHandlers.<name>.postMessage(...)`, handled in `WebViewContainer.swift`):

| Handler name | Purpose |
|---|---|
| `requestNativeLocation` | Ask Swift (`LocationManager`) for GPS permission / location |
| `requestNotificationPermission` | Ask iOS for notification permission (`NotificationManager`) |
| `sendLocalNotification` | Show a local notification (e.g. new chat message) |

**Web page -> Supabase** (client created in `index.html`, config object `SUPABASE` near line 1810):

- Tables read/written: `app_settings`, `blocked_users`, `bus_location_shares`, `buses`, `chat_announcements`,
  `chat_messages`, `device_push_tokens`, `feature_tiles`, `legal_sections`, `notices`, `places`,
  `reported_messages`, `rider_stats`, `route_stops`, `routes`, `student_profiles`, `timetable`.
- RPC functions: `login_student_profile`, `register_student_profile`.
- If Supabase is unreachable the app falls back to local data on the device (localStorage / built-in data).

**Push notifications:** new row in `chat_messages` -> Supabase webhook or trigger
(`supabase_push_notifications.sql`) -> Edge Function `send-chat-push` -> APNs -> iPhone.

## 4. Where things are inside `index.html` (approximate line numbers)

| Lines | Section |
|---|---|
| 1–1050 | `<style>`: design tokens (light/dark), CSS for every screen |
| 1051–1550 | HTML markup for all screens (login, home, leaderboard, settings, bus status, route timeline, location sharing, chat list, chat room, live map) |
| 1554 | Start of the single `<script>` block |
| 1558–2140 | Translations (Bangla / English strings) |
| 1800–1990 | Supabase config (`SUPABASE` url + publishable key) and loading of remote data into `PLACES`, `ROUTES`, `BUS_NAMES`, `TIMETABLE` |
| 2142–2330 | Feature tiles, app state, rendering, screen navigation |
| 2325–2740 | Login, Supabase sign-in, student ID authentication + card/QR scanner |
| 2737–3100 | Home events; **PUST Transport Pool timetable** (`PLACES`, `ROUTES`, `BUS_NAMES`, notice dated 07-04-2026) |
| 3100–3750 | Live map: geometry helpers, OSRM road routes, map setup, GPS marker, bus cards, open/close |
| 3703–4150 | Location prompt on the live map, bus live status |
| 4154–5110 | Live chat: data layer, realtime, chat list, chat room, events |
| 5117–5860 | Appearance, confirm dialog, settings screens, actions |
| 5854–6200 | Location-sharing route gate, leaderboard / ranking |
| 6194–6537 | App init, place autocomplete, search results |

Search for the `/* ---------- ... ---------- */` and `/* ----- ... ----- */` comment banners to jump between sections.
Line numbers drift as the file changes; the banners are the stable landmarks.

## 5. Rules for AI assistants editing this repo

1. **Do not split, minify, or rewrite `index.html`** unless asked. Make small, targeted edits.
2. **Never commit secrets.** The Supabase *publishable* key in `index.html` is meant for browsers and is safe.
   The `service_role` key, APNs `.p8` key, and `APNS_*` values must only live in Supabase function secrets.
3. Bus names and routes should come from the PUST Transport Pool notice (dated 07-04-2026).
   Keep `BRTC-10` and `BRTC-11` as **separate** buses. Show bus names, not "Bus-1 / Bus-2".
4. Stop coordinates in `PLACES` are approximate placeholders, except Campus, Pabna town centre, Ishwardi, Sujanagar.
5. Keep Bangla and English strings in sync when adding UI text.
6. Swift changes: keep deployment target iOS 15.0, SwiftUI + UIKit bridge style already used.
7. If `index.html` mentions `supabase-schema.sql` or `SUPABASE_SETUP.md` and they are missing from the repo,
   they have not been uploaded yet; do not invent their contents.

## 6. Setup quick reference

**Run the iOS app:** open `PUSTBusTracking.xcodeproj` in Xcode -> select your Team under *Signing & Capabilities* ->
pick a simulator/device -> `Cmd + R`.

**Run only the web part:** open `PUSTBusTracking/Resources/index.html` in a browser (native features such as GPS bridge
and push will not work there).

**Push notifications:** run `supabase_push_notifications.sql` in the Supabase SQL Editor, deploy
`supabase/functions/send-chat-push`, and set these function secrets:
`APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_PRIVATE_KEY`, `APNS_BUNDLE_ID`, `APNS_ENVIRONMENT` (`production` or sandbox).
`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are provided to Edge Functions automatically.
