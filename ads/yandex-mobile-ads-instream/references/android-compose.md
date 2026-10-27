# InStream in Jetpack Compose

Read either [Media3](android-media3.md) or [InStream API](android-instream-api.md)
first. Compose changes view and lifecycle ownership, not which ad API supports
the requested break types.

## Ownership

Use `AndroidView` to host the existing `PlayerView` for Media3 or the
`InstreamAdView` hierarchy for Binder/manual breaks. There is no need to add
`mobileads-compose` solely to host these Android views; do not invent an
`InstreamAd` composable from another ad format's API.

Keep one screen-scoped owner containing the loader, player references, Binder
or current break, session generation, queue and content intent. Do not retain
an Activity, `PlayerView` or `InstreamAdView` in a long-lived ViewModel.
A ViewModel can own UI state/content identity without owning those views.

- Create the view in `AndroidView.factory`.
- Allocate/remember the owner with stable content-session and placement keys.
- Start work once when that owner and its rendering surface are ready, after
  the app's privacy/readiness flow. Do not call `loadAd`, `prepare`, `bind` or
  `setMediaItem` from every recomposition or `AndroidView.update`.
- Use `update` for idempotent view/state synchronization. Keep callbacks fresh
  with the project's state-holder/`rememberUpdatedState` pattern.
- Treat a real content or Page ID change as an explicit session replacement.
  Do not key the owner on mutable progress/loading state.

## Lifecycle

Observe `LocalLifecycleOwner` through the project's existing lifecycle
integration (`DisposableEffect` plus an observer, or an equivalent supported
API). Follow the selected platform guide's foreground/background transitions.
Composition remaining alive does not mean the app is in the foreground.

Keep one authority for cleanup:

- On final disposal, invalidate the session before cancelling requests,
  unbinding/invalidation and releasing owned players.
- If `AndroidView.onRelease` also handles removal, make teardown idempotent
  and avoid two owners releasing the same player.
- A cancelled `LaunchedEffect` does not automatically cancel a callback-based
  SDK load. Explicitly call the loader cancellation API and reject stale
  generation callbacks.
- If the view's lifecycle stops temporarily, preserve playback intent. Do not
  restart or autoplay solely because recomposition or `ON_START` happened.
- When a view is reused in a lazy list, detach the previous session on reset
  and bind the new content intentionally. Stable item keys alone do not
  cancel a previous load.

Preserve the platform guide's minimum ad-view area and let SDK ad controls
receive touches. A transparent Compose overlay can still intercept them.

## Verify

- A state change/recomposition does not trigger another request.
- Navigating away while loading does not show an ad on the new screen.
- Background/foreground retains the correct paused/playing state.
- Changing content keys or reusing a row invalidates the previous session.
- Content controls and SDK ad controls never compete for the same touches.

Source: [Compose Views interoperability](https://developer.android.com/develop/ui/compose/migrate/interoperability-apis/views-in-compose).
