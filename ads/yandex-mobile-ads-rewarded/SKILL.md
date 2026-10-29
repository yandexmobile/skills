---
name: yandex-mobile-ads-rewarded
description: >-
  Implements Yandex Mobile Ads SDK rewarded ads (full-screen ads the user
  chooses to watch in exchange for an in-app reward) in native Android (Views or
  Jetpack Compose) and iOS (UIKit or SwiftUI) apps. Use when the task involves
  adding, configuring or fixing a Yandex rewarded ad. Don't use for
  interstitial, app open, banner or native ads, or for installing the SDK from
  scratch.
metadata:
  version: "1.0.0"
  category: YandexAds
---

# Yandex Mobile Ads SDK - Rewarded Ads

A rewarded ad is a full-screen ad the user opts into to receive a reward: an
extra life, coins, a hint, access to content.

## Rules

- **Never show a rewarded ad automatically.** Show it only after the user taps a
  control that clearly offers the reward.
- Enable the offer control only while an ad is loaded and not being shown, so a
  double tap cannot show the same ad twice.
- Grant the reward only in the reward callback, not on show or dismiss. Grant
  the reward the user asked for; if the request does not name the reward and
  its amount, ask. Use the amount and type from the callback only if the user
  says the reward is configured on the ad unit; demo ad units return a test
  value.
- Load the next ad after the current one is dismissed or fails to show.
- If a load fails, do not retry it right away: load again at the next natural
  trigger, the screen is shown again, and only if no ad is loaded or loading.
  The docs advise against reloading from the failure callback.
- While the rewarded ad is on screen, set the app-level `isFullscreenAdShowing`
  flag from the platform guide, so an app open ad is never shown on top of
  it.

## Ad unit ID

- Use the demo ad unit ID `demo-rewarded-yandex` unless the user gives a real
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
     https://ads.yandex.com/helpcenter/en/dev/platforms?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-rewarded and stop.
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
   - Android with Views: `references/android-rewarded.md`
   - Android with Jetpack Compose: `references/android-rewarded-compose.md`
   - iOS with UIKit: `references/ios-rewarded.md`
   - iOS with SwiftUI: `references/ios-rewarded-swiftui.md`

4. **Follow these steps in order**:
   - [ ] Choose the control that offers the reward and the reward itself
   - [ ] Create one ad loader and load the ad in advance
   - [ ] Register for ad events and grant the reward in the reward callback
   - [ ] Show the ad when the user taps the control
   - [ ] Release the shown ad and load the next one
   - [ ] Verify the build

5. If the demo ad unit ID is used, remind the user to replace it with a real
   one before publishing.
