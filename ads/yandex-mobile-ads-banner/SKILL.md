---
name: yandex-mobile-ads-banner
description: >-
  Implements Yandex Mobile Ads SDK banner ads (sticky and inline adaptive
  banners) in native Android (Views or Jetpack Compose) and iOS (UIKit or
  SwiftUI) apps. Use when the task involves adding, configuring or fixing a
  Yandex banner ad. Don't use for ads inside a feed or list unless an inline
  banner is requested, for interstitial, rewarded, app open or native ads, or
  for installing the SDK from scratch.
metadata:
  version: "1.0.0"
  category: YandexAds
---

# Yandex Mobile Ads SDK - Banner Ads

A banner is a rectangular ad that stays on screen inside the app layout and
refreshes automatically.

| Banner type | When to use |
| :--- | :--- |
| **Sticky** | **Default.** Pinned to the top or bottom edge of a screen the user stays on. |
| **Inline** | Placed inside scrolling content, such as an article. |

Use **sticky** if the user asks for "a banner" without naming a type. If the
user asks for ads inside a feed or list without saying "banner", use the
`yandex-mobile-ads-native` skill instead.

## Rules

- Compute the banner width from the container the banner is placed in, not
  from a hard-coded value.
- If a load fails, do not retry it right away: load again at the next natural
  trigger, the screen is shown again, and only if no ad is loaded or loading.
  The docs advise against reloading from the failure callback.

## Ad unit ID

- Use the demo ad unit ID `demo-banner-yandex` unless the user gives a real
  one.
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
   - Android with Views: `references/android-banner.md`
   - Android with Jetpack Compose: `references/android-banner-compose.md`
   - iOS with UIKit: `references/ios-banner.md`
   - iOS with SwiftUI: `references/ios-banner-swiftui.md`

4. **Follow these steps in order**:
   - [ ] Choose the placement and the banner type
   - [ ] Create the ad view with the size computed from the container width
   - [ ] Register for ad events
   - [ ] Load the ad
   - [ ] Release the ad view with its screen
   - [ ] Verify the build

5. If the demo ad unit ID is used, remind the user to replace it with a real
   one before publishing.
