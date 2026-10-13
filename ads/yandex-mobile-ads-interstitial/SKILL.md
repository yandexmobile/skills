---
name: yandex-mobile-ads-interstitial
description: >-
  Implements Yandex Mobile Ads SDK interstitial ads (full-screen ads shown at
  natural transition points) in native Android (Views or Jetpack Compose) and
  iOS (UIKit or SwiftUI) apps. Use when the task involves adding, configuring or
  fixing a Yandex interstitial ad. Don't use for rewarded, app open, banner or
  native ads, or for installing the SDK from scratch.
metadata:
  version: "1.0.0"
  category: YandexAds
---

# Yandex Mobile Ads SDK - Interstitial Ads

An interstitial is a full-screen ad shown at a natural pause in the app: between
levels, after a completed action, on a transition between screens.

## Rules

- Show the ad only at a transition point. Never show it on app launch, on top
  of another full-screen ad, or in the middle of a user action.
- Load the ad in advance, before the user reaches the transition point, and
  show it only when it is already loaded. If it is not ready, continue the
  transition without the ad.
- Continue the interrupted transition exactly once, when the ad is dismissed or
  fails to show. Ignore repeated triggers while the ad is being shown.
- Enforce a minimum interval between shows across the whole app, not per
  screen. Ask the user for the interval if the code does not define one.
- If a load fails, do not retry it right away: load again at the next natural
  trigger, the next transition point, and only if no ad is loaded or loading.
  The docs advise against reloading from the failure callback.
- While the interstitial is on screen, set the app-level `isFullscreenAdShowing`
  flag from the platform guide, so an app open ad is never shown on top of
  it.

## Ad unit ID

- Use the demo ad unit ID `demo-interstitial-yandex` unless the user gives a
  real one.
- Real ad unit IDs are created in the Yandex Advertising Network interface at
  https://partner.yandex.com and look like `R-M-123456-1`. If the user gives
  one, use it as is and do not add the demo ID.
- Keep the ID in one constant per placement so it is easy to replace.

## Workflow

1. **Determine the platform and the UI toolkit** from the project files.
   - Flutter, React Native, Unity or Kotlin Multiplatform project: these
     skills cover native apps only. Point the user to
     https://ads.yandex.com/helpcenter/en/dev/platforms and stop.
   - Android or iOS: if it is unclear, ask before proceeding. Write the code
     in the project's language. Use the Jetpack Compose or SwiftUI guide if the
     target screen is built with it, otherwise the Views or UIKit guide.

2. **Check the SDK.** Find `com.yandex.android:mobileads` (Android: also
   `group = "com.yandex.android"` with `name = "mobileads"` in
   `gradle/libs.versions.toml`) or `YandexMobileAds` (iOS) in the build files.
   - Not installed or never initialized: follow the
     `yandex-mobile-ads-get-started` skill first.
   - Version 7.x or older: stop and tell the user to migrate to SDK 8 first.

3. **Read only the guide for the platform and the UI toolkit**:
   - Android with Views: `references/android-interstitial.md`
   - Android with Jetpack Compose: `references/android-interstitial-compose.md`
   - iOS with UIKit: `references/ios-interstitial.md`
   - iOS with SwiftUI: `references/ios-interstitial-swiftui.md`

4. **Follow these steps in order**:
   - [ ] Choose the transition point where the ad is shown
   - [ ] Create one ad loader and load the ad in advance
   - [ ] Register for ad events
   - [ ] Show the ad at the transition point if it is loaded
   - [ ] Release the shown ad and load the next one
   - [ ] Verify the build

5. If the demo ad unit ID is used, remind the user to replace it with a real
   one before publishing.
