# App Store Rejection Fixes + Website Improvements — Walkthrough

## Part 1: App Store Rejection Fixes (Flutter App)

All three guideline violations resolved. `flutter analyze` passes with **0 errors, 0 warnings**.

### Fix 1: Sign in with Apple (Guideline 4.8)

| File | Change |
|---|---|
| [pubspec.yaml](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/pubspec.yaml) | Added `sign_in_with_apple` + `crypto` |
| [Runner.entitlements](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/ios/Runner/Runner.entitlements) | Added Apple sign-in entitlement |
| [auth_service.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/services/auth_service.dart) | `signInWithApple()` with SHA256 nonce |
| [login_screen.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/screens/login_screen.dart) | Apple button (iOS-only) + handler |
| [auth_wrapper.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/screens/auth_wrapper.dart) | Handle Apple users without Google account |

### Fix 2: iPad Export Bug (Guideline 2.1a)
| File | Change |
|---|---|
| [settings_screen.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/screens/settings_screen.dart) | `GlobalKey`-based share positioning on export buttons |

### Fix 3: Account Deletion (Guideline 5.1.1v)
| File | Change |
|---|---|
| [auth_service.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/services/auth_service.dart) | `deleteAccount()` — Firestore + Firebase Auth cleanup |
| [store.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/services/store.dart) | `clearAllData()` — local data wipe |
| [settings_screen.dart](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/lib/screens/settings_screen.dart) | Delete Account UI with type-to-confirm dialog |

---

## Part 2: Website Improvements

Cloned [roze-whisper-glass](https://github.com/maheshwari-aniruddh/roze-whisper-glass) repo. Build verified: **✓ built in 1.73s**.

### SEO Fixes
| File | Change |
|---|---|
| [index.html](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/roze-website/index.html) | Added `og:url`, `twitter:title`, `twitter:description` |
| [sitemap.xml](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/roze-website/public/sitemap.xml) | **[NEW]** XML sitemap for Google/Bing |
| [robots.txt](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/roze-website/public/robots.txt) | Added `Sitemap:` directive |

### New "Backed by Science" Section
| File | Change |
|---|---|
| [ScienceSection.tsx](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/roze-website/src/components/ScienceSection.tsx) | **[NEW]** 4 animated stat cards with research sources |
| [Navbar.tsx](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/roze-website/src/components/Navbar.tsx) | Added "Science" nav link |
| [Index.tsx](file:///Users/aniruddhmodi/Documents/Aniruddh/Extracurricular/flutter-app/the_30sec_journal/roze-website/src/pages/Index.tsx) | Wired ScienceSection between Privacy and CTA |

### Screenshots

````carousel
![Hero section with Science nav link](file:///Users/aniruddhmodi/.gemini/antigravity/brain/47413fb9-5a29-46cb-aab1-0409d3ab1018/hero_section_1772696759195.png)
<!-- slide -->
![Science section header — "Research says it works"](file:///Users/aniruddhmodi/.gemini/antigravity/brain/47413fb9-5a29-46cb-aab1-0409d3ab1018/science_section_found_1772696832971.png)
<!-- slide -->
![Science stat cards with research sources](file:///Users/aniruddhmodi/.gemini/antigravity/brain/47413fb9-5a29-46cb-aab1-0409d3ab1018/science_stats_1772696849096.png)
````

### Recording
![Website preview recording](file:///Users/aniruddhmodi/.gemini/antigravity/brain/47413fb9-5a29-46cb-aab1-0409d3ab1018/website_preview_1772696720232.webp)

---

## Next Steps For You

1. **Push website changes** — `cd roze-website && git add . && git commit -m "Add science section, fix SEO" && git push`
2. **Enable Sign in with Apple** in Xcode Signing & Capabilities ✅ (done)
3. **Enable Sign in with Apple** in Apple Developer portal App ID
4. **Resubmit to App Store**
