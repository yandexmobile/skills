---
name: yandex-mobile-ads-instream
description: >-
  Integrates or fixes Yandex Mobile Ads InStream video ads in native Android
  (Views or Jetpack Compose) and iOS (UIKit or SwiftUI) apps. Use for ads before,
  during or after video content, pre-roll, mid-roll, post-roll, in-roll,
  pause-roll, Media3 YandexAdsLoader, InstreamAdBinder or InstreamAdBreak.
  Don't use for interstitial/rewarded video ads, native ads in a feed, ad feeds,
  server-side ad insertion, or implementing SDK internals.
metadata:
  version: "1.0.0"
  category: YandexAds
---

# Yandex Mobile Ads SDK - InStream Ads

Add ads to the app's existing video playback flow. InStream uses a video
resource's schedule of ad breaks; it is not an interstitial placed over a
video. A break can contain several creatives (an AdPod).

## Workflow

1. **Inspect the project and the requested placement.** Identify the platform,
   language, UI toolkit, player, content URL/source, installed SDK and desired
   break types. Read applicable project rules and nearby playback code before
   choosing APIs. Keep the existing player and dependency manager when possible.
   - These guides cover native Android/iOS apps. For Flutter, React Native,
     Unity or Kotlin Multiplatform, use the
     [platform documentation](https://ads.yandex.com/helpcenter/en/dev/platforms).
     Do not treat generated native folders as an independent native app.
   - Distinguish an ad inside a video from a rewarded ad or native feed item.
     Ask only for information that the request and project do not establish.

2. **Check SDK setup.** Find `com.yandex.android:mobileads`, including version
   catalog aliases, or `YandexMobileAds` in the app's dependencies.
   - Missing SDK or startup/privacy setup: follow
     [get-started](../yandex-mobile-ads-get-started/SKILL.md), then return here.
   - SDK 7 or older: route to the platform's migration skill before applying
     SDK 8 examples. Verify InStream APIs separately against the installed
     artifact; migration guidance is not a substitute for its API.
   - These guides target SDK 8. For a newer major, verify its published API
     before using the examples.
   - On iOS also link `YandexMobileAdsInstream`; its **0.x** version is
     independent of the main SDK's **8.x** version. See the iOS guide.

3. **Select one integration path**, based on capabilities rather than UI:

   | App and requirement | Guide |
   | :--- | :--- |
   | Android Media3/ExoPlayer with Pre/Mid/Post-roll | [Android Media3](references/android-media3.md) |
   | Android custom player, advanced control, In-roll or Pause-roll | [Android InStream API](references/android-instream-api.md) |
   | iOS with automatic or manually triggered breaks | [iOS InStream API](references/ios-instream-api.md) |

   Add [Compose lifecycle](references/android-compose.md) or
   [SwiftUI lifecycle](references/ios-swiftui.md) only for the relevant UI.
   Android's Media3 path has no In-roll/Pause-roll support. Do not replace
   an existing custom player with Media3 merely to use a shorter example.

4. **Implement and validate the chosen flow.**
   - [ ] Resolve compatible dependencies and preserve privacy/startup readiness
   - [ ] Configure the Page ID and content separately
   - [ ] Create a playback owner for one content session
   - [ ] Load, prepare and play via the selected API
   - [ ] Implement player event forwarding and content/control transitions
   - [ ] Handle failure, cancellation, content replacement and screen teardown
   - [ ] Build the app and exercise the verification cases below

5. **Report** the selected API, changed files, dependency versions, checks
   actually run and any missing device/network verification. If a demo Page ID
   remains, remind the user to replace it before publishing.

## Page ID and requests

- Use `demo-instream-vmap-yandex` when the user has not provided a real Page ID.
  Keep it in one configurable constant. Preserve a supplied ID as is.
- A Page ID identifies the video resource in the Yandex Advertising Network
  interface. It is not a generic banner/interstitial ad unit ID, a content URL,
  an `impId`, or a VAST URL. Never invent one from another identifier.
- Pre/Mid/Post-roll scheduling and AdPods come from the video resource.
  Do not add a second client timer for breaks already controlled by Binder.
- A request for one specific break is a separate API. Its inputs differ
  between platforms; see the platform guide before accepting an ID or URL.
- See [video resource setup](https://ads.yandex.com/helpcenter/en/monetization/ad-unit/instream)
  for production configuration. A working demo does not prove that a
  production video resource is configured.

## Playback rules

- Maintain one owner for the current content/ad session. Serialize load/show
  triggers and reject callbacks from an old session after navigation, content
  replacement or cancellation. Cancel requests as well as invalidating their
  generation; cancellation alone is not a late-callback guard.
- Treat content playback intent separately from SDK-induced pauses and app
  backgrounding. An ad completion/error must restore the appropriate content
  state once. A Pause-roll must not turn a user's pause into autoplay, and
  Post-roll completion must not restart an ended video.
- Binder owns automatic Pre/Mid/Post-roll. For manual breaks, prepare first,
  await the prepared event, then play only when the requested trigger is still
  valid. Consume breaks in their returned order.
- When combining Binder and manual breaks, use separate ad player instances;
  select only In-roll/Pause-roll for manual playback and never start them while
  Binder has paused content for an automatic break.
- Keep SDK ad controls visible and interactive. Show content controls only
  when they belong to content. Do not cover or replace SDK skip/click controls.
- Restore usable content on load/playback failure without an immediate retry
  loop. In a manual flow, handle both completion and error. On teardown,
  suppress continuation rather than starting video on a departed screen.
- Do not interpret loaded/prepared as an impression or a reward. Distinguish
  a creative's completion from the completion of its whole ad break.

## iOS API selection

Honor the user's choice and applicable `AGENTS.md`, `CLAUDE.md` and scoped
rules first, then inspect the target screen/service's concurrency conventions.
Choose async/await or completion handlers for APIs offering both. Use the
block API for Objective-C and check its selector in the installed header.
If the choice remains ambiguous, recommend an approach and ask one focused
question before implementing; do not ask again after a choice is established.

Adapt startup/readiness and error handling as well as the loader call. Own and
cancel async tasks explicitly; callback code should continue from the existing
readiness callback. Preserve main-actor UI access and existing module bridges.
Player/Binder delegates remain necessary with either loading style.

## Verification

Build the app's actual target/variant using its existing tools. Then verify
the cases relevant to the chosen path, reporting untested cases explicitly:

- Demo load and playback; the requested Pre/Mid/Post-roll positions.
- A full AdPod finishes before content resumes.
- Load failure and playback failure restore content/controls without looping.
- Navigate away during loading/preparation/playback: no late show or autoplay.
- Return from background and change orientation without duplicate sessions.
- Replace the content item: no callbacks, position or ads from the old item.
- Manual breaks: prepare-before-play, repeat-trigger protection, queue
  consumption and no overlap with Binder.
- Pause-roll: a user pause stays paused after completion/error; an SDK pause
  or lifecycle pause does not itself trigger another Pause-roll.
- Compose recomposition/SwiftUI updates and list reuse do not repeat loads.

Sources: [Android overview](https://ads.yandex.com/helpcenter/en/dev/android/instream),
[iOS overview](https://ads.yandex.com/helpcenter/en/dev/ios/instream).
