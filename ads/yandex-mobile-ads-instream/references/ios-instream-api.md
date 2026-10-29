# iOS InStream API

Apply [iOS API selection](../SKILL.md#ios-api-selection) before using these
examples. Loading can use async/await or completion; playback still uses
player and Binder/AdBreak delegates.

Contents: [dependencies](#dependencies), [public API](#public-api),
[player adapters](#player-adapters-and-view-hierarchy),
[loading](#loading-style), [Binder](#automatic-breaks-with-binder),
[manual breaks](#manual-in-roll-and-pause-roll), [lifecycle](#lifecycle).

## Dependencies

Keep the existing dependency manager:

- **SPM:** add the `YandexMobileAdsInstream` product from the same
  `https://github.com/yandexmobile/yandex-ads-sdk-ios` package revision as
  `YandexMobileAds`, and link it to the app target. Preserve existing products
  and `-ObjC`/`$(inherited)` linker flags.
- **CocoaPods:** add `YandexMobileAdsInstream` to the app target. Inspect its
  published podspec's `YandexMobileAds` dependency and resolve a compatible
  pair with the existing main SDK. If that requires an SDK update, explain
  the change; do not independently choose the latest version of both pods.
  Run `pod install` with the project's normal Bundler workflow and inspect
  `Podfile.lock`.
- The InStream pod has its own **0.x** version; it is not an obsolete main
  SDK version. Never construct `YandexMobileAdsInstream:8.x` from the main
  SDK version.

Use the main SDK's [get-started guide](../../yandex-mobile-ads-get-started/references/ios-get-started.md)
for privacy, SKAdNetwork and initialization. Also verify the selected InStream
release's deployment target and toolchain requirements. Do not add a second
startup/consent flow.

Sources for resolving dependencies:
[integration](https://ads.yandex.com/helpcenter/en/dev/ios/quick-start?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-instream),
[package and podspecs](https://github.com/yandexmobile/yandex-ads-sdk-ios),
[InStream pod versions](https://trunk.cocoapods.org/api/v1/pods/YandexMobileAdsInstream).

## Public API

```swift
import UIKit
import YandexMobileAdsInstream
```

Relevant signatures, abbreviated to the parameters needed here:

```swift
InstreamAdLoader()
InstreamAdRequestConfiguration(pageID: String)
func loadInstreamAd(configuration: InstreamAdRequestConfiguration)
    async throws -> InstreamAd
func loadInstreamAd(
    configuration: InstreamAdRequestConfiguration,
    completion: @MainActor @escaping
        (Result<InstreamAd, InstreamAdLoadingFailureInfo>) -> Void
)
func cancelLoading()

InstreamAdBinder(
    ad: InstreamAd,
    adPlayer: InstreamAdPlayer,
    videoPlayer: VideoPlayer
)
// Binder: @MainActor; delegate is weak.
func prepareAd()
func bind(with adView: InstreamAdView)
func unbind()
func invalidateAdPlayer()
func invalidateVideoPlayer()

// InstreamAd: @MainActor
var adBreaks: [InstreamAdBreak] { get }
// InstreamAdBreak: @MainActor; delegate is weak.
func prepare(with adPlayer: InstreamAdPlayer)
func play(with adView: InstreamAdView)
func pause()
func resume()
func invalidate()
```

These are reference signatures, not a standalone Swift declaration file.
Check the installed SDK's actual throwing type and Objective-C selectors.
Do not reuse Android's `InstreamAdRequest`, `loadAd`, constructor ordering,
default-player overload or `instreamAdBreaks` property on iOS.

## Player adapters and view hierarchy

Adapt the existing content player (commonly AVPlayer) to `VideoPlayer`, and
provide a separate ad player conforming to `InstreamAdPlayer`. Keep both
adapters alive for the session. The iOS Binder constructor requires both.

| Adapter | Required behavior |
| :--- | :--- |
| `VideoPlayer` | `delegate`, content `position`/`duration`, `prepareVideo()`, `pauseVideo()`, `resumeVideo()` |
| `InstreamAdPlayer` | `delegate`, `isPlaying`, ad `position`/`duration`, `prepareAd(with:)`, `playAd()`, `pauseAd()`, `resumeAd()`, `stopAd()`, `setVolume(_:)` |

Positions and durations are **seconds** (`TimeInterval`), unlike Android's
milliseconds. Check for non-finite/unknown `CMTime` values before converting.
Use the installed SDK's requirements for a duration not yet available.

Forward actual content preparation, completion, pause, resume and failure
through `VideoPlayerDelegate`. Forward ad readiness, start, pause, resume,
completion, stop, failure and volume changes through
`InstreamAdPlayerDelegate`. Retain the `VideoAd` received in
`prepareAd(with:)` and return that same object in the ad delegate events.
Convert player errors to the SDK's public `InstreamAdPlayerError`.

For AVPlayer use item status/end/failure observations and playback state to
produce these events once. Retain observation tokens and remove them when
replacing an item or ending the session. Guard queued callbacks against the
old item. Do not synthesize successful preparation before the media is ready.

Put `InstreamAdView` in the hierarchy with the player's rendering view inside
it and constraints that keep the SDK controls visible. Keep a usable video
area of at least 300 x 160 points. The SDK container is not an AVPlayer:
the application supplies the rendering surface. Reuse suitable adapters from
the [official sample](https://github.com/yandexmobile/yandex-ads-sdk-ios)
after inspecting their dependencies; classes named `AdPlayer`, `ContentPlayer`
or `PlayerView` in samples are application code, not SDK classes to import.

When Binder calls content `pauseVideo()`, pause and hide content controls;
restore the appropriate content state when it calls `resumeVideo()`. Keep
user intent separate from SDK and background pauses. Missing content-complete
events can prevent Post-roll.

## Loading style

Use one retained loader per owner. The fragments below belong to a main-actor
screen/controller; `generation`, `isActive`, `isLoading`, `accept` and
`handleLoadFailure` are application state/handlers to implement.

For async loading, call from the project's owned task after its readiness
gate:

```swift
let requestGeneration = generation
let configuration = InstreamAdRequestConfiguration(pageID: pageID)
isLoading = true
do {
    let ad = try await loader.loadInstreamAd(configuration: configuration)
    guard !Task.isCancelled, isActive, generation == requestGeneration else {
        return
    }
    isLoading = false
    accept(ad)
} catch {
    guard !Task.isCancelled, isActive, generation == requestGeneration else {
        return
    }
    isLoading = false
    handleLoadFailure(error)
}
```

On cancellation or content replacement, the owner resets its own loading
state while advancing the generation. A stale task must not clear a newer
request's state. Retain the task handle and cancel it explicitly on teardown;
do not rely on `deinit` if a running task retains the owner.

For completion loading, continue from the project's readiness callback:

```swift
let requestGeneration = generation
let configuration = InstreamAdRequestConfiguration(pageID: pageID)
isLoading = true
loader.loadInstreamAd(configuration: configuration) { [weak self] result in
    guard let self, self.isActive,
          self.generation == requestGeneration else { return }
    self.isLoading = false
    switch result {
    case .success(let ad):
        self.accept(ad)
    case .failure(let info):
        self.handleLoadFailure(info) // The SDK description is info.reason.
    }
}
```

For Objective-C use the block overload exposed in the installed header.
Do not reintroduce the removed `InstreamAdLoaderDelegate`. Failure should leave
content usable and should not recursively start a new request.

## Automatic breaks with Binder

In the accepted-load handler:

```swift
let binder = InstreamAdBinder(
    ad: ad,
    adPlayer: adPlayer,
    videoPlayer: contentPlayer
)
binder.delegate = self
adBinder = binder
binder.prepareAd() // Optional Pre-roll preparation before binding.
binder.bind(with: instreamAdView)
```

Implement `InstreamAdBinderDelegate`:

- `instreamAdBinder(_:didPrepare:)`
- `instreamAdBinder(_:didComplete:)`
- `instreamAdBinder(_:didFailToPlay:with:)`

Retain `self`/the delegate through the session owner, since Binder's delegate
is weak. Ignore events from a replaced Binder. Let the content adapter handle
normal pause/resume transitions; coordinate any Binder error fallback with
it instead of resuming content twice. Prepared does not mean impression.

## Manual In-roll and Pause-roll

Filter `ad.adBreaks` by `adBreakData.type == .inroll` (or `.pauseroll`).
Keep the returned order and a current-break reference in the owner:

1. Remove the next break from the pending queue; assign its delegate and
   call `prepare(with: adPlayer)`.
2. In `instreamAdBreakDidPrepare(_:)`, mark readiness. Only call
   `play(with: instreamAdView)` when the requested playback trigger is still
   valid, the screen is active and no other ad break owns playback.
3. In `instreamAdBreakDidStart(_:)`, acquire the content interruption and hide
   content controls. Keep the prior content intent.
4. Handle both `instreamAdBreakDidComplete(_:)` and
   `instreamAdBreakDidError(_:)` through one idempotent finalizer. Accept events
   only for the current break/session; clear the delegate, invalidate the
   break, clear its reference and restore the content controls/intent once.
5. Prepare the next break, but wait for its own trigger. Do not repeatedly use
   `queue.first` without removing the consumed break.

Preparation may fail before content was interrupted. Do not resume a user
pause or a Binder pause that this break did not own. For Pause-roll, trigger
only on a real user pause, invalidate the trigger if the user resumes before
preparation finishes, and keep content paused after completion/error.

When also using Binder, use a different ad player for manual playback and
only In-roll/Pause-roll from the schedule. Never start manual playback during
a Binder-controlled ad.

### Loading a specific break

The iOS API uses
`InstreamAdBreakRequestConfiguration(adBreakURL:parameters:)` with the user's
actual break URL, then `loader.loadInroll(configuration:)` or its completion
overload. It returns an `InstreamAd`, whose `adBreaks` must be inspected.
Do not port Android's `(pageId, impId)` builder or assume the result is a
single `InstreamAdBreak`. Do not construct a URL by guessing a host/path.

## Lifecycle

Perform UI/Binder/AdBreak work and delegate delivery on the main actor.
When adapting nonisolated player protocols to a main-actor implementation,
use the project's Swift language-mode/SDK compatibility approach; do not
silence isolation errors with `@unchecked Sendable` or detached tasks.

On temporary backgrounding pause the active playback path and retain intent.
On final screen exit/content replacement, call an explicit main-actor cleanup:

1. Mark the session inactive, advance its generation and clear loading state.
2. Cancel the owned task and call `loader.cancelLoading()`.
3. Clear Binder's delegate; call `unbind()`, `invalidateAdPlayer()` and
   `invalidateVideoPlayer()`; release the Binder.
4. Clear the current manual break's delegate, call `invalidate()`, and clear
   the queue/current reference.
5. Remove player observations, detach rendering surfaces, and release owned
   playback resources. Never resume content during cleanup.

Do not rely solely on `deinit` for main-actor teardown. For reusable cells or
SwiftUI wrappers, cleanup must occur while the owner is still accessible.

Sources: [InStream integration](https://ads.yandex.com/helpcenter/en/dev/ios/instream-advanced?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-instream),
[iOS SDK and sample](https://github.com/yandexmobile/yandex-ads-sdk-ios).
