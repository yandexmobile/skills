# InStream in SwiftUI

Read [iOS InStream API](ios-instream-api.md) first. Keep its player adapters and
Binder/AdBreak lifecycle. Do not invent a native SDK `Instream` SwiftUI view
or use a plain SwiftUI `VideoPlayer` as the SDK's `VideoPlayer` protocol adapter.

## Wrap the playback owner

Prefer `UIViewControllerRepresentable` around the existing UIKit playback
controller when that controller already owns playback and lifecycle. For a
view-based design, use `UIViewRepresentable` with a retained coordinator or
screen owner for the loader, adapters, Binder/manual breaks and observations.

- Create the UIKit controller/view and adapters once in `make...`.
- Retain weak SDK delegates through that owner/coordinator.
- Apply inputs in `update...` only when content identity, Page ID or an
  explicit playback action actually changes. Do not reload or rebind on every
  SwiftUI update.
- Let one stable owner store task handles, generation and playback intent.
  In a design using an `ObservableObject`, create it with `@StateObject`
  rather than constructing it repeatedly in `body`.
- Choose one place to initiate loading: the owner's start method or an owned
  `.task(id: contentIdentity)` flow. Do not start it both in `make...` and
  `.task`.

`InstreamAdView` and the content/ad rendering views must share the proper
UIKit hierarchy. Size the wrapper explicitly so the ad view is at least
300 x 160 points. Keep SDK controls accessible and do not intercept their
touches with a SwiftUI overlay.

## Teardown and scene state

Implement `dismantleUIViewController` or `dismantleUIView` to call the owner's
explicit main-actor cleanup from the platform guide. Cancel its task, cancel
SDK loading, invalidate the generation, unbind/invalidate playback and remove
observations. Do not wait for `deinit` or assume dropping the SwiftUI value
releases its controller immediately.

If the screen persists off-screen or the app becomes inactive, use the
existing navigation lifecycle/`scenePhase` flow to pause the current playback
path. Preserve the distinction between a user pause and lifecycle pause;
backgrounding must not request a Pause-roll. Resume only the valid session
according to content intent. Avoid separately resuming in both UIKit and
SwiftUI lifecycle callbacks.

Cancellation of `.task` is not sufficient for the SDK's completion overload.
Even for async loading, invalidate the owner and cancel the SDK loader so
queued results cannot bind to an old view.

## Verify

- Updating unrelated `@State` does not load or play another ad.
- Changing video identity replaces the session and clears its old queue.
- Dismissal during loading/preparation rejects the late result.
- A paused video stays paused through scene transitions and Pause-roll.
- Returning to the screen follows the app's intended resume/restart policy.

Sources: [UIViewControllerRepresentable](https://developer.apple.com/documentation/swiftui/uiviewcontrollerrepresentable),
[UIViewRepresentable](https://developer.apple.com/documentation/swiftui/uiviewrepresentable).
