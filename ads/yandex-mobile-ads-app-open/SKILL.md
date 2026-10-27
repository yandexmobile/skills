---
name: yandex-mobile-ads-app-open
description: >-
  Implements Yandex Mobile Ads SDK app open ads (full-screen ads shown when the
  user returns to the app) in native Android and iOS apps. Use when the task
  involves adding, configuring or fixing a Yandex app open ad or an ad on app
  launch or on return from background. Don't use for interstitial, rewarded,
  banner or native ads, or for installing the SDK from scratch.
metadata:
  version: "1.0.0"
  category: YandexAds
---

# Yandex Mobile Ads SDK - App Open Ads

An app open ad is a full-screen ad shown when the app comes to the foreground,
most often when the user returns to the app from background.

## Rules

- App open ads are served only to apps in portrait orientation. If the app is
  landscape-only, tell the user that the format will not fill and stop.
- Show the ad only when the user returns to the app after it stayed in
  background for a minimum time. Use 30 seconds unless the user asks for
  another value.
- On a cold start the ad is usually not loaded yet, so the first show happens
  on a later return. Show it on a cold start only if the app keeps a splash
  screen and the ad loads within a short timeout. Tell the user this in the
  final message, otherwise they will think the integration is broken.
- Do not show the ad on top of another full-screen ad. Interstitial and
  rewarded ads set an app-level `isFullscreenAdShowing` flag while they are
  on screen, and the app open manager checks it.
- Do not show the ad to new users during their first sessions, and not on
  every return. Ask the user for the rule (number of sessions, minimum
  interval between shows) if the code has none; if the user has no
  preference, the 30-second background minimum alone is enough.
- Load the ad in advance, after the SDK is initialized, but do not start the
  first load at the same time as other ad formats at app start: start it when
  the app first goes to background or after the first screen's ads have
  loaded. Load the next ad after the current one is dismissed or fails to
  show.
- If a load fails, do not retry it right away: load again at the next natural
  trigger, the next return to the app, and only if no ad is loaded or loading.
  The docs advise against reloading from the failure callback.

## Ad unit ID

- Use the demo ad unit ID `demo-appopenad-yandex` unless the user gives a real
  one.
- Real ad unit IDs are created in the Yandex Advertising Network interface at
  https://partner.yandex.com and look like `R-M-123456-1`. If the user gives
  one, use it as is and do not add the demo ID.
- Keep the ID in one constant so it is easy to replace.

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

1. **Determine the platform** from the project files.
   - Flutter, React Native, Unity or Kotlin Multiplatform project: these
     skills cover native apps only. Point the user to
     https://ads.yandex.com/helpcenter/en/dev/platforms and stop.
   - Android or iOS: if it is unclear, ask before proceeding. Write the code
     in the project's language.

2. **Check the SDK.** Find `com.yandex.android:mobileads` (Android: also
   `group = "com.yandex.android"` with `name = "mobileads"` in
   `gradle/libs.versions.toml`) or `YandexMobileAds` (iOS) in the build files.
   - Not installed or never initialized: follow the
     `yandex-mobile-ads-get-started` skill first.
   - Version 7.x or older: stop and tell the user to migrate to SDK 8 first.

3. **Read the platform guide**. The app open manager lives at the app level,
   so Jetpack Compose and SwiftUI apps use the same guide:
   - Android: `references/android-app-open.md`
   - iOS: `references/ios-app-open.md`

4. **Follow these steps in order**:
   - [ ] Create an app-level manager that owns the ad loader
   - [ ] Load the ad after the SDK is initialized
   - [ ] Detect the moment the app comes to the foreground
   - [ ] Show the ad if it is loaded and nothing from the rules forbids it
   - [ ] Make the interstitial and rewarded ads already in the app set the
     `isFullscreenAdShowing` flag while they are on screen
   - [ ] Release the shown ad and load the next one
   - [ ] Verify the build

5. If the demo ad unit ID is used, remind the user to replace it with a real
   one before publishing.
