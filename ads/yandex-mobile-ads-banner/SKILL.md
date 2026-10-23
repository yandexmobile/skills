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
user asks for ads inside a feed or list without saying "banner", determine
whether they mean individual app-rendered ads (`yandex-mobile-ads-native`)
or an SDK-rendered ad sequence (`yandex-mobile-ads-feed`).

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

## iOS API selection

Choose the integration style before applying the iOS examples:

1. Read the applicable `AGENTS.md`, `CLAUDE.md` and scoped project rules.
   Respect the user's stated preference; explicit project rules take priority
   over the style of an example or nearby code.
2. Inspect the target screen, view model or service and similar operations
   nearby: async/await or completion handlers, task ownership, cancellation
   and actor isolation. Prefer local conventions over a project-wide count
   of API usages.
3. For SDK APIs that offer both forms, use async/await where it fits the
   project's concurrency model, or completion where callbacks fit. Use the
   block API for Objective-C; verify its selector in the installed SDK header.
   Keep SDK SwiftUI views/modifiers when they fit the screen and format rules;
   they do not require a manual loader just to choose async or completion.
4. If rules and code leave the choice unclear (mixed styles or a new module),
   explain the tradeoff, recommend an approach and ask one focused question
   before implementing it. Do not ask again if the user already chose.

The snippets demonstrate SDK behavior, not a mandatory API style. Adapt both
loading and startup/ATT readiness to the selected approach. For async work,
define who owns a task and when it is cancelled; a synchronous lifecycle
method may start a task when that fits the project. For completion code,
continue from the project's readiness callback instead of adding a task just
to copy an async example. Preserve error handling, main-actor UI updates and
existing async/completion bridges at module boundaries.

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
