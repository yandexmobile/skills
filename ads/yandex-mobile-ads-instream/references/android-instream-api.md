# Android InStream API

Use Binder for automatic Pre/Mid/Post-roll, and `InstreamAdBreak` for manual
playback. Preserve the app's content player. Use the SDK's default ad player
when it meets the requirements; implement a custom one only when needed.

Contents: [API map](#sdk-8-api-map), [player adapters](#content-and-ad-player-adapters),
[Binder](#load-and-bind), [manual breaks](#manual-in-roll-and-pause-roll),
[cleanup](#lifecycle-and-cleanup).

## SDK 8 API map

Check these public APIs in the resolved SDK before adapting the fragments:

```kotlin
import com.yandex.mobile.ads.instream.InstreamAd
import com.yandex.mobile.ads.instream.InstreamAdLoader
import com.yandex.mobile.ads.instream.InstreamAdRequest
import com.yandex.mobile.ads.instream.InstreamAdLoadListener
import com.yandex.mobile.ads.instream.InstreamAdRequestError
import com.yandex.mobile.ads.instream.InstreamAdListener
import com.yandex.mobile.ads.instream.InstreamAdBreakType
import com.yandex.mobile.ads.instream.InstreamAdBreakEventListener
import com.yandex.mobile.ads.instream.binder.InstreamAdBinder
import com.yandex.mobile.ads.instream.adbreak.InstreamAdBreak
import com.yandex.mobile.ads.instream.player.content.VideoPlayer
import com.yandex.mobile.ads.instream.player.ad.InstreamAdPlayer
import com.yandex.mobile.ads.instream.player.ad.InstreamAdView
```

| Operation | API |
| :--- | :--- |
| Request a schedule | `InstreamAdRequest.Builder(pageId).build()` |
| Load | `InstreamAdLoader(context).loadAd(request, listener)` |
| Cancel | `loader.cancelLoading()` |
| Default ad player | `InstreamAdBinder(context, ad, contentPlayer)` |
| Custom ad player | `InstreamAdBinder(context, ad, contentPlayer, adPlayer)` |
| Observe Binder | `binder.setInstreamAdListener(listener)` |
| Prepare/bind | `binder.prepareAd()` / `binder.bind(adView)` |
| Break collection | `ad.instreamAdBreaks` |
| Prepare manual break | `adBreak.prepare()` or `adBreak.prepare(adPlayer)` |
| Manual playback | `adBreak.play(adView)`, `pause()`, `resume()` |
| Invalidate manual playback | `adBreak.invalidate()` |

The custom Binder constructor takes **content player before ad player**.
Use the three-argument overload for the default player, not a guessed
four-argument call with `null`. Do not remove `invalidate()` based on an old
migration table; check the installed interface.

Use callback loading for the broadly applicable SDK 8 example. If the app
uses coroutines and its resolved SDK exposes a suspend overload, inspect its
result and cancellation contract before choosing it; do not assume all 8.x
artifacts have every overload available in current source.

## Content and ad player adapters

Implement `VideoPlayer` around the existing content player:

- `videoPosition` and `videoDuration` are **milliseconds**, `volume` is 0–1.
  Handle unknown/unset duration according to the player's and SDK's contract,
  not by passing a sentinel as a real duration.
- Implement `prepareVideo()`, `pauseVideo()`, `resumeVideo()` and
  `setVideoPlayerListener(...)`. Forward real prepared, completed, paused,
  resumed and error events to `VideoPlayerListener`.
- SDK pause/resume callbacks must switch content controls and visibility
  as well as playback. Separate SDK pause from user pause and backgrounding
  so a programmatic pause does not trigger Pause-roll.
- Report completion from the player, not from a timer; missing it can
  suppress Post-roll. Keep progress queries tied to content during ads.

With a custom `InstreamAdPlayer`, implement all methods of the resolved
interface, including `supportedMimeTypes`, `bindPlayerView(container)`,
`prepareAd`, `playAd`, `pauseAd`, `resumeAd`, `stopAd`, `skipAd`, `releaseAd`,
volume and progress accessors. Forward real events through
`InstreamAdPlayerListener`, retaining the same SDK `VideoAd` identity for
its callbacks. Report supported formats honestly; do not list HLS/DASH if
the player cannot decode them. Use distinct content/ad player instances.

Create an `InstreamAdView` in the visible hierarchy (at least 300 x 160 dp).
With the default player the SDK attaches ad playback. With a custom player,
attach its view/surface to the supplied container in `bindPlayerView`; leave
the SDK controls unobscured. Do not assume Binder renders the content player.

## Load and bind

The fragment belongs inside a screen/session owner. `onLoaded` and
`onLoadFailed` below are application handlers, not SDK APIs.

```kotlin
val loader = InstreamAdLoader(context)
val request = InstreamAdRequest.Builder(pageId).build()
loader.loadAd(request, object : InstreamAdLoadListener {
    override fun onInstreamAdLoaded(ad: InstreamAd) {
        onLoaded(ad)
    }

    override fun onInstreamAdFailedToLoad(error: InstreamAdRequestError) {
        onLoadFailed(error.description)
    }
})
```

Before requesting, capture a session generation/content key and set loading
state. In both handlers first check that generation and the owner's active
state. Accept a result only for the current session, and clear loading state
on both terminal paths. Keep content usable when loading fails.

On an accepted result:

```kotlin
val binder = InstreamAdBinder(context, ad, contentPlayer)
binder.setInstreamAdListener(listener)
binder.prepareAd() // Optional early preparation of Pre-roll.
binder.bind(instreamAdView)
```

Retain the binder and adapters until teardown. Implement the listener's
`onInstreamAdPrepared()`, `onInstreamAdCompleted()` and `onError(reason)`.
Content transitions normally come through the `VideoPlayer` adapter: do not
add a second unconditional resume in the Binder listener. Coordinate error
fallback with the adapter so continuation happens once.

## Manual In-roll and Pause-roll

Select the requested type from a loaded schedule:

```kotlin
val pending = ArrayDeque(
    ad.instreamAdBreaks.filter {
        it.adBreakData.type == InstreamAdBreakType.INROLL
    }
)
```

For Pause-roll filter `PAUSEROLL` instead. Keep this queue and one
`currentBreak` in the session owner, not a local variable discarded after load.
Use this state flow:

1. Remove the next break from the queue once, retain it, register a fresh
   `InstreamAdBreakEventListener`, and call `prepare()` (or `prepare(adPlayer)`).
2. Record the prepared event. It enables playback; it does not itself mean
   the user/content trigger happened. Play only when both readiness and a
   still-valid trigger are present, with no other break active.
3. On `onInstreamAdBreakStarted`, pause content for this break and hide content
   controls. Preserve the previous content intent. For Pause-roll it is
   usually already paused by the user.
4. Route `onInstreamAdBreakCompleted` and `onInstreamAdBreakError(reason)`
   through one idempotent finalizer. Check the captured break/session
   identity, detach its listener, invalidate it, clear current state and
   restore controls and content intent. A late event from the previous break
   must not finish the next one.
5. Prepare the next break if the session is still active; wait for its own
   trigger. Do not drain all In-rolls immediately after the first trigger.

An error may arrive during preparation, before content was paused by this
break. Track whether this break actually acquired the playback interruption;
do not resume an unrelated user or Binder pause. If preparation finishes
after the user has resumed content, the old Pause-roll trigger has expired.

When combined with Binder, manual playback may consume only In-roll and
Pause-roll, using a separate explicit ad player and no overlap with
Binder-controlled playback.

### A specific break instead of a schedule

Use the public `instream.adbreak.InstreamAdBreakLoader` with
`InstreamAdBreakRequest.Builder(pageId, impId).build()` and
`InstreamAdBreakLoadListener`. Its result is one `InstreamAdBreak`; verify the
listener/error signatures in the resolved artifact. Do not invent an `impId`
or expose `Private*` / internal URL-loading APIs as public integration APIs.
Keep the same preparation, lifecycle and late-callback rules.

## Lifecycle and cleanup

All these operations and callbacks should run on the main thread.

- On temporary backgrounding pause the active playback path and preserve
  content intent. Resume only the same still-valid session when appropriate.
- On content replacement or final teardown mark the old session inactive and
  increment its generation **before** cancelling/invalidation.
- Call `loader.cancelLoading()` (and the specific-break loader's equivalent).
- For Binder call `unbind()`, `invalidateAdPlayer()` and
  `invalidateVideoPlayer()`, then clear its listener and reference.
- For a manual break clear its listener, call `invalidate()`, and clear the
  current break and queue.
- Remove player listeners/observers and release only players owned by this
  session. Do not release a shared application player without its owner's
  agreement. Teardown must not resume content.

Sources: [InStream API integration](https://ads.yandex.com/helpcenter/en/dev/android/instream-advanced),
[Android samples](https://github.com/yandexmobile/yandex-ads-sdk-android).
