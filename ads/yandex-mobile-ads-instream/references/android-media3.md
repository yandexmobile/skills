# Android InStream with Media3

Use this path for an existing Media3/ExoPlayer player and automatic
Pre/Mid/Post-roll. For a custom player or In-roll/Pause-roll use
[InStream API](android-instream-api.md).

## Dependencies and API

Keep `com.yandex.android:mobileads` and add the required Media3 modules through
the project's existing version catalog/build convention:

```kotlin
implementation("androidx.media3:media3-exoplayer:<compatible-version>")
implementation("androidx.media3:media3-ui:<same-compatible-version>")
```

Retain the app's HLS/DASH modules if its content needs them. Resolve
compatibility with the installed Yandex SDK and
[the integration guide](https://ads.yandex.com/helpcenter/en/dev/android/instream-based?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-instream);
do not blindly select the newest Media3 release or mix Media3 versions. The
guide's dependency numbers are examples, not a promise for every SDK release.

Use `com.yandex.mobile.ads.instream.media3.YandexAdsLoader` with
`androidx.media3.*`. Do not combine it with
`com.google.android.exoplayer2.*` or the old `instream.exoplayer` import.
If the app still uses ExoPlayer2, inspect its supported adapter/version and
agree on any player migration rather than changing all imports implicitly.

Relevant imports:

```kotlin
import android.net.Uri
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.ui.PlayerView
import com.yandex.mobile.ads.instream.InstreamAdRequest
import com.yandex.mobile.ads.instream.media3.YandexAdsLoader
```

Use the project's Media3 `UnstableApi` opt-in convention where required.
All player/loader interaction below belongs on the main thread.

## Connect the existing player

This fragment assumes a real `context`, attached `playerView`, `pageId` and
`contentUri`. Integrate it into a screen/session owner; do not create another
player if the app already owns one.

```kotlin
val request = InstreamAdRequest.Builder(pageId).build()
val adsLoader = YandexAdsLoader(context, request)
val mediaSourceFactory = DefaultMediaSourceFactory(context)
    .setLocalAdInsertionComponents({ adsLoader }, playerView)
val player = ExoPlayer.Builder(context)
    .setMediaSourceFactory(mediaSourceFactory)
    .build()

playerView.player = player
adsLoader.setPlayer(player)

val item = MediaItem.Builder()
    .setUri(contentUri)
    .setAdsConfiguration(
        MediaItem.AdsConfiguration.Builder(
            Uri.parse(YandexAdsLoader.AD_TAG_URI)
        ).build()
    )
    .build()
player.setMediaItem(item)
player.prepare()
// Set playWhenReady from the app's playback intent/readiness flow.
```

- The content URI is the main video. `AD_TAG_URI` is the Yandex adapter's
  marker (`yandex://ad_tag`), not a VAST URL or the Page ID.
- Both `setLocalAdInsertionComponents` and `MediaItem.AdsConfiguration` are
  needed. Attaching only `YandexAdsLoader` does not connect the ad source.
- Let Media3 drive automatic insertion. Do not also attach an
  `InstreamAdBinder`, call an independent `InstreamAdLoader`, or implement
  a timer for the same Pre/Mid/Post-rolls.
- Preserve the app's data sources, DRM and player configuration when adapting
  its media source factory. Check compatibility rather than discarding them
  to reproduce this minimal fragment.
- Keep `PlayerView`'s ad overlay intact. It supplies the ad view provider.

## Lifecycle and content replacement

Keep the loader alive for the intended content session and attach/detach the
current player on the main thread. Recomposition and temporary view changes
must not repeatedly construct loaders or reset the media item.

When releasing a player, save the **content** position and the user's playback
intent, then detach it:

```kotlin
val savedContentPosition = player.contentPosition
// Capture the app's content playback intent separately if an ad is active.
adsLoader.setPlayer(null)
playerView.player = null
player.release()
```

`currentPosition` during an ad is not the main video's resume position.
At final session teardown also call `adsLoader.release()` and discard it.
Never reattach a released loader. If a temporary lifecycle stop releases only
the player, reattach its replacement to the retained loader before preparing
the content and restore the saved content state. Verify that previously
played breaks are not replayed inadvertently.

In a View Activity follow the existing Media3 ownership pattern:
initialize/resume in `onStart`, pause/release in `onStop` on API 24+; for
API 23 and below use `onResume`/`onPause`. A Fragment's player view follows the
**view** lifecycle. For Compose use [its lifecycle guide](android-compose.md).
Do not resume playback unconditionally after a user pause.

When replacing the actual content item, end the old ad session and establish
the new one deliberately. Do not reuse a previous video's schedule or saved
position merely because the player view is reused.

Handle content/player errors through the existing Media3 error flow. Test ad
load/playback failure with this adapter: if the app's fallback needs to play
the content without ads, make that a one-time transition for the current
session, not repeated `prepare()` calls from an error callback.

## Check

- Inspect Gradle's resolved Media3 dependencies for version conflicts.
- Build the selected app variant, including Media3 opt-in/lint checks.
- Exercise the [shared verification cases](../SKILL.md#verification), with
  particular attention to ad-to-content transitions and background restore.

Sources: [Yandex Media3 integration](https://ads.yandex.com/helpcenter/en/dev/android/instream-based?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-instream),
[Android integration samples](https://github.com/yandexmobile/yandex-ads-sdk-android),
[Media3 ad insertion](https://developer.android.com/media/media3/exoplayer/ad-insertion).
