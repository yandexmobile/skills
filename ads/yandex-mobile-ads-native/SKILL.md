---
name: yandex-mobile-ads-native
description: >-
  Implements Yandex Mobile Ads SDK native ads (ads rendered by the app's own
  views to match its design, for example in a feed) in native Android (Views or
  Jetpack Compose) and iOS (UIKit or SwiftUI) apps. Use when the task involves
  adding, configuring or fixing a Yandex native ad or an ad inside a feed or
  list. Don't use for banner, interstitial, rewarded or app open ads, or for
  installing the SDK from scratch.
metadata:
  version: "1.0.0"
  category: YandexAds
---

# Yandex Mobile Ads SDK - Native Ads

A native ad is delivered as a set of assets (title, body, image or video, icon,
call to action and others) that the app renders with its own views, so the ad
matches the app's design. It fits feeds and lists best. A feed rendered by the
SDK itself is a separate format, Ad feed, and is not covered by these skills:
see https://ads.yandex.com/helpcenter/en/dev/android/feed-ad.md and
https://ads.yandex.com/helpcenter/en/dev/ios/feed-ad.md.

## Rules

- Lay out the ad with the platform's native ad view as the root and add a view
  for every asset. Which assets an ad contains, and therefore which views
  binding requires, differs from ad to ad: a missing view makes binding fail
  on real traffic, even if demo ads render.
- Keep the ad view and the required asset views visible, opaque, large enough
  and fully inside the ad view. A hidden or too small view does not fail
  binding, but the impression is not counted.
- Do not change asset texts or images. Scale images only with their aspect
  ratio and crop no more than 20%.
- Keep the sponsored label visible and do not imitate app content.
- Load ads for a list in advance and insert them at a fixed interval. Insert
  only as many ad rows as ads were actually returned, and bind each ad to one
  visible view at a time.
- If a load fails, do not retry it right away: load again at the next natural
  trigger, the screen is shown again, and only if no ad is loaded or loading.
  The docs advise against reloading from the failure callback.

## Ad unit ID

- Use the demo ad unit ID `demo-native-app-yandex` for a single ad and
  `demo-native-bulk-yandex` for several ads loaded at once, unless the user
  gives a real one. `demo-native-content-yandex` and
  `demo-native-video-yandex` return other ad types for testing.
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
   - Android with Views: `references/android-native.md`
   - Android with Jetpack Compose: `references/android-native-compose.md`
   - iOS with UIKit: `references/ios-native.md`
   - iOS with SwiftUI: `references/ios-native-swiftui.md`

4. **Follow these steps in order**:
   - [ ] Choose the placement and how many ads it needs
   - [ ] Create the ad layout with a view for every asset
   - [ ] Create one ad loader and load the ads
   - [ ] Bind the loaded ad to the layout and handle a binding failure
   - [ ] Register for ad events
   - [ ] Verify the build

5. If the demo ad unit ID is used, remind the user to replace it with a real
   one before publishing.
