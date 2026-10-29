---
name: yandex-mobile-ads-feed
description: >-
  Implements Yandex Mobile Ads SDK Feed Ad (Ad feed), an SDK-rendered sequence
  of ads used as a standalone list or appended after existing content, in
  native Android and iOS apps. Use for FeedAd, FeedAdAdapter,
  FeedAdCollectionViewAdapter or FeedAdState integration and troubleshooting.
  For individual ads rendered by the app or inserted every N content items,
  use the native ads skill instead.
metadata:
  version: "1.0.0"
  category: YandexAds
---

# Yandex Mobile Ads SDK - Feed Ad

Feed Ad renders its cards inside the SDK and loads more as the user scrolls.
It can occupy the screen or follow the app's content. It is a separate format
from app-rendered native ads: it does not need an asset layout,
`NativeAdViewBinder` or `NativeBulkAdLoader`.

## Workflow

1. **Identify the placement, platform and UI toolkit.** Read the target
   screen and its project rules. For an ambiguous request such as "ads in my
   feed", establish whether the user wants an SDK-rendered ad sequence or
   individual native ads mixed into content. Route the latter to
   `yandex-mobile-ads-native`. These guides cover native apps; for Flutter,
   React Native, Unity or Kotlin Multiplatform, use the
   [platform documentation](https://ads.yandex.com/helpcenter/en/dev/platforms?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-feed).
2. **Check dependencies and startup.** Inspect the resolved SDK version and
   existing initialization/privacy flow. These examples target SDK 8.x.
   Migrate SDK 7.x first. If installation or initialization is missing, use
   `yandex-mobile-ads-get-started` when available, or the platform's official
   quick-start guide linked below. On iOS also link `YandexMobileAdsFeed`:
   installing `YandexMobileAds` alone is insufficient.
3. **Read the relevant guide:**
   - [Android Views](references/android-feed.md)
   - [Android Compose](references/android-feed-compose.md), together with
     the Android Views guide for the SDK objects and callbacks
   - [iOS UIKit](references/ios-feed.md)
   - [iOS SwiftUI](references/ios-feed-swiftui.md)
4. **Implement in order:**
   - [ ] Select standalone or appended placement, preserving existing content
   - [ ] Wait for SDK/privacy readiness and measure the actual container width
   - [ ] Configure the request and appearance; retain the feed owner
   - [ ] Connect load, failure, click and impression callbacks
   - [ ] Connect the UI and start the initial load in the platform guide's
         order: UIKit adapter before `loadAd()`, Android `preloadAd()` before
         adapter attachment
   - [ ] Let the SDK drive further loading
   - [ ] Handle screen disposal and intentional recreation
   - [ ] Build and exercise the integration using the guide's checks
5. Report what was built and tested, what still needs device verification,
   and whether the demo ID must be replaced before release.

## iOS API selection

Choose the integration style before applying the examples:

1. Respect the user's stated preference and read applicable `AGENTS.md`,
   `CLAUDE.md` and scoped rules. Explicit rules take priority over an example
   or the style of nearby code.
2. Inspect the target screen, view model or service and similar operations
   nearby: async/await or completion handlers, task ownership, cancellation
   and actor isolation.
3. Where the SDK offers both forms, use the one that fits those conventions.
   Preserve suitable SDK SwiftUI components and existing bridges at module
   boundaries. For Objective-C verify selectors in the installed headers.
4. If the choice remains unclear, recommend an approach and ask one focused
   question before implementing it. Do not ask again if the user chose.

Feed itself has no async/completion loading overload: UIKit uses `loadAd()`
and `FeedAdDelegate`; SwiftUI uses `FeedAdState` and `FeedAdEvent`. Keep that
event model. Apply the decision above to startup/ATT readiness and surrounding
app code; do not invent `await feed.loadAd()` or wrap repeated feed events in
a one-shot continuation. For async startup, define task lifetime and
cancellation; for callback startup, continue from the readiness callback.
Keep SDK/UI access on the main actor.

## Shared rules

- Use `demo-feed-yandex` unless the user supplies a real ad unit ID. Keep it
  in one placement constant and remind the user to replace a demo ID before
  publishing. Real IDs come from [YAN](https://partner.yandex.com).
- Call SDK methods on the main thread. Create feed objects after the app's
  existing SDK/privacy readiness gate; do not create a second consent or
  initialization flow.
- Use the container's available width after insets/padding: points on iOS,
  dp on Android. Wait for a positive measured width. Treat a changed width or
  ad unit as a new feed configuration, not a reason to reload on every layout
  or recomposition.
- Keep SDK-rendered cards unobscured and interactive. Let SDK events report
  impressions and clicks; rendering a row is not proof of an impression.
- Do not implement a second pagination loop or an immediate retry from a
  failure callback. Preserve already displayed content; retry only on an
  explicit user action or a later screen entry, following platform guidance.
- Verify the installed public interface when documentation and examples
  disagree. Do not use internal SDK types in publisher code.

## Documentation

- [Android Feed Ad](https://ads.yandex.com/helpcenter/en/dev/android/feed-ad?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-feed)
- [Android quick start](https://ads.yandex.com/helpcenter/en/dev/android/quick-start?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-feed)
- [iOS Feed Ad](https://ads.yandex.com/helpcenter/en/dev/ios/feed-ad?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-feed)
- [iOS quick start](https://ads.yandex.com/helpcenter/en/dev/ios/quick-start?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-feed)
