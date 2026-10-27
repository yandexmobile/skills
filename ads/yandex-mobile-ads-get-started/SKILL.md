---
name: yandex-mobile-ads-get-started
description: >-
  Installs and initializes the Yandex Mobile Ads SDK in a native Android
  (Kotlin/Java) or iOS (Swift) app: adds the latest SDK dependency, applies
  platform requirements and privacy settings, and initializes the SDK. Use when
  the task is to add Yandex Ads (Yandex Mobile Ads SDK, Yandex Advertising
  Network) to an app, or when a Yandex ad format is requested and the SDK is not
  installed or not initialized yet. Don't use for Flutter, React Native or Unity
  apps, for placing a specific ad format into an app that already has the SDK,
  or for migrating from Yandex Mobile Ads SDK 7.
metadata:
  version: "1.0.0"
  category: YandexAds
---

# Yandex Mobile Ads SDK - Get Started

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

1. **Determine the platform** from the project files. Check cross-platform
   frameworks first: their projects also contain Android and iOS folders.
   - Flutter (`pubspec.yaml`), React Native (`react-native` in
     `package.json`), Unity (`ProjectSettings/ProjectVersion.txt`) or Kotlin
     Multiplatform: these skills cover native apps only. Point the user to
     https://ads.yandex.com/helpcenter/en/dev/platforms and stop.
   - Android: `settings.gradle(.kts)` or `build.gradle(.kts)` with the Android
     Gradle plugin.
   - iOS: `*.xcodeproj`, `*.xcworkspace`, `Podfile` or `Package.swift`.
   - If it is still unclear, ask before proceeding.

2. **Check whether the SDK is already installed.** Search the build files for
   `com.yandex.android:mobileads` (Android: also `group = "com.yandex.android"`
   with `name = "mobileads"` in `gradle/libs.versions.toml`) or
   `YandexMobileAds` (iOS).
   - Version 8.x or newer is present: skip the dependency step, but still check
     the privacy settings and the initialization below.
   - Version 7.x or older is present: stop and tell the user to migrate to
     SDK 8 first with the `yandex-mobile-ads-android-migrate-to-8` or
     `yandex-mobile-ads-ios-migrate-to-8` skill from this set.

3. **Read the platform guide**:
   - Android: `references/android-get-started.md`
   - iOS: `references/ios-get-started.md`

4. **Follow these steps in order**:
   - [ ] Add the latest SDK version as a dependency
   - [ ] Apply the platform requirements
   - [ ] Apply privacy settings
   - [ ] Initialize the SDK
   - [ ] Verify the build

5. If the user already named an ad format, continue with that format's skill.
   Otherwise ask which ad format to add next: banner, interstitial, rewarded,
   app open, native, [Feed Ad](../yandex-mobile-ads-feed/SKILL.md) (an
   SDK-rendered ad sequence) or [InStream](../yandex-mobile-ads-instream/SKILL.md).
   For ads inside a video player, continue with InStream; its guide checks
   the player integration and the additional iOS `YandexMobileAdsInstream`
   dependency.

## Rules

- **Always resolve the latest released SDK version** with the command from the
  platform guide. Never copy a version number from memory or from this skill.
- If the latest major version is newer than 8, warn the user that these
  instructions were written for SDK 8 and the API may differ.
- Ask about the audience only if the code does not answer it: does the app
  serve users in the EEA or the UK, and is it directed at children.
- Never invent privacy values. Pass consent to the SDK only if the app already
  has a consent flow, and only the value that flow produced. Child-directed
  apps mark all users as age-restricted; mixed-audience apps pass the stored
  answer of their age gate on every launch. Never hard-code the age value.
