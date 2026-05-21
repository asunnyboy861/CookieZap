# Git Repositories

## Main App (iOS Application)

| Item | Value |
|------|-------|
| **Repository Name** | CookieZap |
| **Git URL** | git@github.com:asunnyboy861/CookieZap.git |
| **Repo URL** | https://github.com/asunnyboy861/CookieZap |
| **Visibility** | Public |
| **Primary Language** | Swift |
| **GitHub Pages** | ✅ **ENABLED** (from `/docs` folder) |

## Policy Pages (Deployed from Main Repository /docs)

| Page | URL | Status |
|------|-----|--------|
| Landing Page | https://asunnyboy861.github.io/CookieZap/ | ✅ Active |
| Support | https://asunnyboy861.github.io/CookieZap/support.html | ✅ Active |
| Privacy Policy | https://asunnyboy861.github.io/CookieZap/privacy.html | ✅ Active |
| Terms of Use | https://asunnyboy861.github.io/CookieZap/terms.html | ✅ Active |

## Repository Structure

```
CookieZap/
├── CookieZap/                         # iOS App Source Code
│   ├── CookieZap.xcodeproj/           # Xcode Project
│   ├── CookieZap/                     # Main App Swift Source Files
│   │   ├── Views/
│   │   ├── Models/
│   │   ├── Services/
│   │   ├── Shared/
│   │   └── ...
│   ├── CookieZapExtension/            # Safari Web Extension
│   │   ├── SafariWebExtensionHandler.swift
│   │   ├── Resources/                 # JS, HTML, CSS, manifest.json
│   │   └── Info.plist
│   └── CookieZapBlocker/              # Content Blocker Extension
│       ├── BlockerRequestHandler.swift
│       ├── blockerlist.json
│       └── Info.plist
├── docs/                              # Policy Pages (GitHub Pages source)
│   ├── index.html
│   ├── support.html
│   ├── privacy.html
│   └── terms.html
├── .github/workflows/
│   └── deploy.yml
├── us.md
├── keytext.md
├── capabilities.md
├── icon.md
├── price.md
└── nowgit.md
```
