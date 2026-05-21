# CookieZap - iOS Development Guide

## Executive Summary

**CookieZap** is a Safari Web Extension for iOS/iPadOS/macOS that automatically detects and rejects cookie consent popups, providing users with a clean, uninterrupted browsing experience. Unlike competitors that merely hide cookie banners with CSS, CookieZap intelligently locates and clicks "Reject" / "Decline" / "Necessary Only" buttons, ensuring actual privacy consent rather than visual suppression.

**Product Vision**: "One tap to say goodbye to cookie popups forever" — zero configuration, instant effect, privacy-first.

**Target Audience**: US + EU global English-speaking Safari users who are frustrated by constant cookie consent interruptions.

**Key Differentiators**:
1. **Smart Rejection** — Actually clicks "Reject" buttons, not just CSS hiding
2. **Zero Configuration** — Install, enable extension, done. No settings needed.
3. **Achievement Dashboard** — "47 popups zapped today" gives users satisfaction and proof of value
4. **One-Time Purchase** — $1.99 lifetime, no subscription fatigue
5. **Heuristic Detection** — Falls back to semantic analysis when known CMP rules don't match

## Competitive Analysis

| App | Price | Strengths | Weaknesses | Our Advantage |
|-----|-------|-----------|------------|---------------|
| **Hush** | Free | Zero config, simple | Only hides (CSS), no reject click, no stats | Smart reject + stats dashboard |
| **Consent-O-Matic** | Free | Open source, customizable | Only 11 ratings, high RAM, few sites covered | Better performance + wider coverage |
| **Super Agent** | $1.19/mo–$29.99 | 1.9K ratings, AI analysis | Confusing subscription pricing, manual setup needed | Zero config + one-time $1.99 |
| **1Blocker** | $3.99/mo | Deep customization, cross-device sync | Expensive subscription, bloated features, cookie is secondary | Focused on cookies + affordable |
| **AdGuard** | Free/Paid | Comprehensive ad blocking | Too complex, cookie blocking requires manual enable | Out-of-box cookie focus |
| **CookieDNT** | $2.99 | Per-site cookie control, iCloud sync | Deletes cookies, doesn't reject popups; no popup blocking | Smart popup rejection + stats |
| **Adblock Plus** | Free + IAP | 10M+ downloads, trusted brand | Cookie blocking is secondary feature; subscription IAP | Dedicated cookie focus + one-time price |

## Feature Inventory

### Primary Features

| # | Feature | User Operation Flow | Data Input | Processing | Data Output | Persistence | Acceptance Criteria |
|---|---------|--------------------|------------|------------|-------------|-------------|---------------------|
| 1 | Smart Cookie Popup Rejection | 1. User visits website in Safari → 2. Cookie popup appears → 3. CookieZap detects popup → 4. CookieZap clicks "Reject" button → 5. Popup dismissed | Webpage DOM (auto-detected) | content.js: match CMP rules → find reject button → click; fallback: heuristic keyword matching | Popup dismissed, page scrollable | ZapEvent in SwiftData (domain, action, cmp, timestamp) | Cookie popup is rejected and disappears within 2 seconds of page load |
| 2 | CSS Fallback Hiding | 1. Cookie popup detected → 2. No reject button found → 3. CSS display:none applied → 4. Scroll restored | Webpage DOM (auto-detected) | content.js: apply CSS hide + restore scroll | Popup hidden, page scrollable | ZapEvent (action="hidden") | Cookie popup is hidden and page scroll is restored |
| 3 | Statistics Dashboard | 1. User opens CookieZap app → 2. Dashboard shows today's zapped count, total zapped, success rate | Auto-collected from extension | DashboardViewModel: load from App Group UserDefaults | Today count, total count, success rate displayed | App Group UserDefaults (today_zapped, total_zapped, total_rejected, total_attempted) | Dashboard displays accurate counts matching extension activity |
| 4 | Onboarding Flow | 1. User launches app first time → 2. Welcome screen with animation → 3. Guide to enable Safari extension → 4. Open Settings button → 5. Completion screen | User taps "Get Started", "Open Settings" | OnboardingView: step navigation, open Settings URL | Safari Settings opened, extension enabled | UserDefaults (hasCompletedOnboarding) | First launch shows 3-step onboarding; subsequent launches skip to dashboard |
| 5 | Settings — Enable/Disable Toggle | 1. User opens Settings tab → 2. Toggles "Enable CookieZap" switch | Toggle state | SettingsViewModel: update App Group UserDefaults | Extension reads setting and enables/disables | App Group UserDefaults (is_enabled) | Toggling off stops popup rejection; toggling on resumes |
| 6 | Settings — Blocking Mode | 1. User opens Settings → 2. Selects "Smart Reject" or "Hide Only" | Segmented picker selection | SettingsViewModel: update App Group UserDefaults | Extension uses selected mode | App Group UserDefaults (blocking_mode) | Smart Reject clicks reject buttons; Hide Only only applies CSS |
| 7 | Settings — Whitelist Management | 1. User opens Settings → 2. Adds domain to whitelist → 3. Extension skips that domain | Domain text input | SettingsViewModel: validate domain, save to SwiftData + App Group | Domain appears in whitelist, extension skips it | SwiftData (WhitelistSite) + App Group JSON | Whitelisted sites show cookie popups normally |
| 8 | Safari Toolbar Popup | 1. User taps ⚡ icon in Safari toolbar → 2. Popup shows current site status → 3. Pause/Resume or Add to Whitelist | User taps buttons in popup | popup.js: read current tab domain, send message to background | Status display, pause/resume toggle | browser.storage.local | Popup shows protection status; pause stops blocking for current site |
| 9 | Content Blocker Rules | 1. Safari loads page → 2. Content Blocker applies CSS hide rules from JSON → 3. Known CMP banners hidden before JS runs | blockerlist.json rules | BlockerRequestHandler: load rules from App Group or bundled JSON | CSS elements hidden immediately | App Group (blocker_rules.json) or bundled blockerlist.json | Known cookie banners are hidden before page renders |
| 10 | Rule Auto-Update | 1. Background check for rule updates → 2. Download updated rules from GitHub → 3. Save to App Group → 4. Notify content blocker | Auto-triggered (periodic) | RuleUpdateService: fetch from GitHub Pages, compare version, save | Updated rules loaded by extension | App Group (blocker_rules.json, cmp-rules.json) | Rules update silently; new CMP platforms covered |

### Sub-Features & Detail Interactions

| # | Parent Feature | Sub-Feature | Detail Description | Interaction Pattern |
|---|---------------|-------------|-------------------|--------------------|
| 1.1 | Smart Rejection | CMP-Specific Rules | Rules for OneTrust, Cookiebot, Quantcast, Didomi, TrustArc, Usercentrics, CookieYes, iubenda, Civic, Moove | Auto-detected via CSS selectors |
| 1.2 | Smart Rejection | Heuristic Detection | When no CMP rule matches, detect cookie keywords in text + find reject button by text matching | Auto-detected via keyword scan |
| 1.3 | Smart Rejection | Multi-language Reject Buttons | Detects "Reject", "Decline", "Refuse", "Necessary Only", "Only Essential", "Opt Out", "Deny", "Reject All", "Decline All", "Manage Choices" | Auto-detected via keyword matching |
| 3.1 | Dashboard | Hero Stat Card | Large animated number showing today's zapped count with ⚡ icon | Auto-updated when app opens |
| 3.2 | Dashboard | Stat Cards | Two side-by-side cards: Total Zapped + Success Rate | Auto-updated when app opens |
| 3.3 | Dashboard | Recent Activity | Last 5 zapped domains with action type (Rejected/Hidden) | Auto-populated from SwiftData |
| 4.1 | Onboarding | Step 1 Animation | Cookie popup appears then gets zapped with ⚡ animation | Auto-played |
| 4.2 | Onboarding | Step 2 Deep Link | "Open Settings" button opens iOS Settings → Safari → Extensions | Tap button |
| 5.1 | Settings | Auto-update Rules Toggle | Toggle to enable/disable automatic rule updates | Toggle switch |
| 7.1 | Whitelist | Add Website | Text field to enter domain name, with validation | Text input + tap Add |
| 7.2 | Whitelist | Delete from Whitelist | Swipe-to-delete or tap X button on whitelist entry | Swipe or tap |
| 8.1 | Toolbar Popup | Pause for This Site | Temporarily disable blocking for current domain | Tap button |
| 8.2 | Toolbar Popup | Add to Whitelist | Permanently add current domain to whitelist | Tap button |
| 8.3 | Toolbar Popup | Today's Stats | Show today's zapped count in popup | Auto-displayed |

### Cross-Feature Dependencies

| Dependency | Source Feature | Target Feature | Data Passed | Trigger Condition |
|------------|---------------|----------------|-------------|-------------------|
| Extension stats → Dashboard | Smart Rejection / CSS Fallback | Statistics Dashboard | zapped count, action type, domain | Every popup zapped event |
| Whitelist → Extension | Whitelist Management | Smart Rejection / CSS Fallback | Whitelisted domain list | Extension checks before processing |
| Blocking mode → Extension | Blocking Mode Setting | Smart Rejection / CSS Fallback | Mode selection (smart/hide) | Extension reads mode on each page |
| Enable toggle → Extension | Enable/Disable Toggle | All extension features | Boolean enabled state | Extension checks on each page |
| Rule update → Content Blocker | Rule Auto-Update | Content Blocker Rules | Updated JSON rules | Periodic background check |
| Toolbar popup → Whitelist | Safari Toolbar Popup | Whitelist Management | Domain to whitelist | User taps "Add to Whitelist" |
| Toolbar popup → Pause | Safari Toolbar Popup | Smart Rejection | Domain to pause | User taps "Pause for this site" |

## Apple Design Guidelines Compliance

- **HIG — Extensions**: App includes Safari Web Extension with clear purpose disclosure in marketing text. Extension does not include marketing, advertising, or in-app purchases per Guideline 4.4.
- **HIG — Privacy**: No user data collected. No analytics. No network requests except rule updates from GitHub Pages. Privacy Policy clearly states zero data collection.
- **HIG — Navigation**: TabView with Dashboard and Settings tabs follows standard iOS navigation patterns.
- **HIG — Controls**: Toggle switches, segmented pickers, and lists follow standard iOS control patterns.
- **HIG — Onboarding**: Three-step onboarding with clear instructions and deep link to Settings.
- **HIG — Accessibility**: All interactive elements have accessibilityLabel and accessibilityHint. Dynamic Type supported. VoiceOver compatible.
- **HIG — Dark Mode**: Full dark mode support using semantic colors and .ultraThinMaterial backgrounds.
- **App Review 4.4 — Extensions**: Extension complies with Safari Web Extensions documentation. App includes help screens (onboarding) and settings interface.
- **App Review 5.1.1 — Privacy**: App collects no data. Privacy Policy URL required and provided.

## Technical Architecture

- **Language**: Swift 5.9+
- **Framework**: SwiftUI (primary UI), Swift Observation (@Observable)
- **Data**: SwiftData (ZapEvent, WhitelistSite), UserDefaults with App Group (stats), browser.storage.local (extension data)
- **Extension**: Safari Web Extension (manifest.json v3, content.js, background.js, popup.html/js)
- **Content Blocker**: Safari Content Blocker Extension (blockerlist.json)
- **Communication**: App Group shared container for data exchange between main app and extension
- **Networking**: URLSession for rule updates from GitHub Pages
- **No Third-Party Dependencies**: Pure Apple frameworks only

## Module Structure

```
CookieZap/
├── CookieZap/                          # Main App Target
│   ├── CookieZapApp.swift              # App entry point
│   ├── Views/
│   │   ├── MainTabView.swift           # Tab navigation
│   │   ├── DashboardView.swift         # Statistics dashboard
│   │   ├── SettingsView.swift          # Settings page
│   │   └── OnboardingView.swift        # Onboarding flow
│   ├── ViewModels/
│   │   ├── DashboardViewModel.swift    # Dashboard logic
│   │   └── SettingsViewModel.swift     # Settings logic
│   ├── Models/
│   │   ├── ZapEvent.swift              # Zap event model
│   │   └── WhitelistSite.swift         # Whitelist model
│   ├── Services/
│   │   ├── StatsManager.swift          # Stats management
│   │   ├── RuleUpdateService.swift     # Rule update service
│   │   └── AppGroupManager.swift       # App Group shared data
│   └── Widgets/
│       ├── ZapStatsWidget.swift        # Stats widget
│       └── ZapToggleWidget.swift       # Quick toggle widget
│
├── CookieZapExtension/                 # Safari Web Extension Target
│   ├── SafariWebExtensionHandler.swift # Swift bridge
│   └── Resources/
│       ├── manifest.json               # Extension manifest
│       ├── content.js                  # DOM manipulation + smart reject
│       ├── background.js               # Background event handling
│       ├── popup.html                  # Toolbar popup UI
│       ├── popup.js                    # Popup logic
│       ├── styles.css                  # Popup styles
│       ├── inject.css                  # CSS injection for hiding
│       ├── rules/
│       │   └── cmp-rules.json          # CMP detection rules
│       └── images/                     # Extension icons
│
├── CookieZapBlocker/                   # Content Blocker Target
│   ├── BlockerRequestHandler.swift     # Rule loading handler
│   └── blockerlist.json                # Static CSS hide rules
│
└── Shared/                             # Shared code
    ├── Constants.swift                 # Constants
    └── AppGroupIDs.swift               # App Group identifiers
```

## Data Flow Diagram

### Feature 1: Smart Cookie Popup Rejection

```
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── User visits website in Safari (automatic trigger)    │
│       │                                                   │
│  Content Script Processing (content.js)                   │
│  └── Load CMP rules from cmp-rules.json                   │
│  └── Check whitelist (browser.storage.local)              │
│  └── Observe DOM mutations (MutationObserver)             │
│  └── Match element against CMP detect selectors           │
│  └── Find reject button via reject_button selector        │
│  └── Click reject button OR fallback to heuristic         │
│  └── If no reject found → CSS hide (Feature 2)           │
│       │                                                   │
│  Background Script Processing (background.js)             │
│  └── Receive popup_zapped message from content.js         │
│  └── Save stat to browser.storage.local                   │
│  └── Update badge text with today's count                 │
│       │                                                   │
│  App Group Bridge                                         │
│  └── Stats synced to App Group UserDefaults               │
│       │                                                   │
│  Display Output                                           │
│  └── DashboardView shows today/total stats                │
│  └── Safari badge shows today's zapped count              │
└───────────────────────────────────────────────────────────┘
```

### Feature 3: Statistics Dashboard

```
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── User opens CookieZap app                             │
│       │                                                   │
│  ViewModel Processing                                     │
│  └── DashboardViewModel.loadStats()                       │
│  └── Read App Group UserDefaults: today_zapped,           │
│      total_zapped, total_rejected, total_attempted        │
│  └── Calculate successRate = rejected / attempted          │
│       │                                                   │
│  Model/Persistence                                        │
│  └── App Group UserDefaults (shared container)            │
│  └── SwiftData ZapEvent (recent activity list)            │
│       │                                                   │
│  Display Output                                           │
│  └── HeroStatCard: today's zapped count (large number)    │
│  └── StatCards: total zapped + success rate               │
│  └── Recent Activity: last 5 ZapEvents                    │
└───────────────────────────────────────────────────────────┘
```

### Feature 7: Whitelist Management

```
┌───────────────────────────────────────────────────────────┐
│  User Input                                               │
│  └── User enters domain in Settings or taps "Add to       │
│      Whitelist" in Safari popup                           │
│       │                                                   │
│  ViewModel Processing                                     │
│  └── SettingsViewModel.addWhitelistSite(domain)           │
│  └── Validate domain format                               │
│  └── Save to SwiftData (WhitelistSite entity)             │
│  └── Sync to App Group JSON (whitelist_sites.json)        │
│       │                                                   │
│  Model/Persistence                                        │
│  └── SwiftData: WhitelistSite (domain, addedAt, isTemp)   │
│  └── App Group: whitelist_sites.json                      │
│  └── browser.storage.local: whitelist (extension reads)   │
│       │                                                   │
│  Display Output                                           │
│  └── Settings: whitelist list with delete buttons         │
│  └── Extension: skips whitelisted domains                 │
└───────────────────────────────────────────────────────────┘
```

### Feature 9: Content Blocker Rules

```
┌───────────────────────────────────────────────────────────┐
│  System Input                                             │
│  └── Safari requests content blocker rules                │
│       │                                                   │
│  BlockerRequestHandler Processing                         │
│  └── Check App Group for updated blocker_rules.json       │
│  └── If exists → load from App Group                      │
│  └── If not → load bundled blockerlist.json               │
│  └── Return NSExtensionItem with JSON attachment          │
│       │                                                   │
│  Rule Source                                              │
│  └── Bundled: blockerlist.json (initial rules)            │
│  └── Updated: App Group blocker_rules.json (from update)  │
│       │                                                   │
│  Display Output                                           │
│  └── Safari applies CSS hide rules before page renders    │
│  └── Known CMP banners hidden immediately                │
└───────────────────────────────────────────────────────────┘
```

### Feature 10: Rule Auto-Update

```
┌───────────────────────────────────────────────────────────┐
│  Trigger                                                  │
│  └── Periodic background check (or app launch)            │
│       │                                                   │
│  RuleUpdateService Processing                             │
│  └── Fetch version info from GitHub Pages URL             │
│  └── Compare with local version                           │
│  └── If newer → download updated JSON files               │
│  └── Save to App Group shared container                   │
│  └── Reload content blocker rules                         │
│       │                                                   │
│  Persistence                                              │
│  └── App Group: blocker_rules.json, cmp-rules.json        │
│  └── UserDefaults: last_update_timestamp, rule_version    │
│       │                                                   │
│  Cross-Feature Output                                     │
│  └── Content Blocker loads updated rules                  │
│  └── content.js loads updated CMP rules                   │
└───────────────────────────────────────────────────────────┘
```

## Implementation Flow

1. Create Xcode project with iOS App + Safari Web Extension + Content Blocker targets
2. Configure App Group shared container for data exchange
3. Implement Safari Web Extension (manifest.json, content.js, background.js, popup.html/js)
4. Implement Content Blocker (blockerlist.json, BlockerRequestHandler.swift)
5. Implement CMP detection rules (cmp-rules.json with 10+ CMP platforms)
6. Implement smart rejection engine in content.js (rule matching + heuristic fallback)
7. Build main app UI (Dashboard, Settings, Onboarding) with SwiftUI
8. Implement SwiftData models (ZapEvent, WhitelistSite)
9. Implement App Group data bridge (StatsManager, AppGroupManager)
10. Implement rule auto-update service (RuleUpdateService)
11. Implement Safari toolbar popup (popup.html/js/css)
12. Test on Top 100 websites for coverage
13. Prepare App Store metadata and submit

## UI/UX Design Specifications

- **Color Scheme**:
  - Zap Orange: #FF6B35 (primary, energy, action)
  - Trust Blue: #007AFF (system blue, reliability)
  - Clean Black: #1C1C1E (dark mode background)
  - Pure White: #FFFFFF (light mode background)
  - Success Green: #34C759 (blocked successfully)
  - Warning Yellow: #FF9500 (whitelist indicator)
- **Typography**: SF Pro system font, rounded design for numbers (.rounded)
- **Layout**: VStack/HStack with 20pt spacing, 16pt padding, .ultraThinMaterial card backgrounds
- **Animations**:
  - Number count-up: `contentTransition(.numericText())`
  - Zap icon pulse: SwiftUI `spring` animation
  - Success flash: `withAnimation(.easeInOut)`
  - List row insertion: SwiftUI `animation` modifier
- **Dark Mode**: Full support via semantic colors and .ultraThinMaterial
- **Accessibility**: VoiceOver labels on all interactive elements, Dynamic Type support

## Code Generation Rules

- One type per Swift file, high cohesion, low coupling
- SwiftUI for all UI, Swift Observation (@Observable) for view models
- SwiftData for persistence, no CoreData
- async/await for asynchronous operations, no callbacks
- App Group for all data sharing between app and extension
- No third-party dependencies in main app
- Privacy-first: no data collection, no analytics, no network requests except rule updates
- MIT-licensed rule data from open-source projects
- Original code implementation (reference GPL projects for rule data only, not code)

## Build & Deployment Checklist

- [ ] Xcode project configured with 3 targets: Main App, Safari Extension, Content Blocker
- [ ] App Group configured and shared container accessible
- [ ] Safari Extension manifest.json valid and permissions declared
- [ ] Content Blocker blockerlist.json valid Safari format
- [ ] All Swift files compile without errors
- [ ] App runs on iPhone and iPad simulators
- [ ] Safari Extension loads and processes cookie popups
- [ ] Content Blocker rules applied correctly
- [ ] App Group data sharing works between targets
- [ ] Onboarding flow completes and opens Settings
- [ ] Dashboard displays accurate statistics
- [ ] Whitelist management works end-to-end
- [ ] Settings toggles affect extension behavior
- [ ] Privacy Policy page accessible from Settings
- [ ] No data collection — App Store privacy questionnaire accurate
- [ ] App Store metadata prepared (keytext.md)
- [ ] GitHub repository created and code pushed
- [ ] Policy pages deployed to GitHub Pages
