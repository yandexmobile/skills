# AI Integration Agent Instructions for iOS Interstitial Ads with SwiftUI

Apply [iOS API selection](../SKILL.md#ios-api-selection) before using
these examples. Adapt the snippets to the selected project conventions.

## Required Imports

```swift
import SwiftUI
import YandexMobileAds
```

## Method Signatures

SwiftUI API, SDK 8.0.0+:

```swift
func interstitialAd(
    isPresented: Binding<Bool>,
    request: Binding<AdRequest?>,
    onEvent: ((InterstitialAdEvent) -> Void)? = nil
) -> some View

enum InterstitialAdEvent {
    case didLoad(AdInfo?), didShow, didDismiss, didClick
    case didFailToShow(Error), didFailToLoad(Error), didTrackImpression(ImpressionData?)
}
```

The SDK view/modifier below owns loading. The API choice applies to
the surrounding startup/readiness code; a callback-based flow updates
the same state from its readiness callback instead of awaiting in `.task`.
Keep the SDK view/modifier unless the project's architecture requires
a custom loader; in that case use the [UIKit loader/view guide](ios-interstitial.md)
and adapt its presentation to SwiftUI.

## Gotchas

- A non-`nil` `request` starts loading (`nil` cancels it); `isPresented =
  true` shows the loaded ad and returns to `false` after a dismiss or failure.
- Attach the modifier to a view that lives for the whole flow (screen or
  navigation root), otherwise the loaded ad is lost.
- After `.didFailToLoad` set `request` to `nil` and assign a new request at
  the next transition, never at once. After `.didDismiss` and
  `.didFailToShow` assign a new `AdRequest` to load the next ad.
- Reset `FullscreenAdState.isFullscreenAdShowing` only in `.didDismiss` and
  `.didFailToShow`, not in `.onDisappear`: the ad is a full-screen modal, so
  the content under it disappears while the ad is still on screen.
- If the project does not use synchronized folders, add new files to the
  app target (see the get-started guide).

Names such as `GameView` or `openNextLevel()` in the snippets are placeholders
for the app's own code.

## Interstitial workflow

1. **Choose the transition point where the ad is shown**

   - [ ] Find the action that performs the transition. Add the app-wide state
     (declare each type once per app, skip it if it exists); ask the user for
     the interval if the code has none:

     ```swift
     @MainActor enum FullscreenAdState { static var isFullscreenAdShowing = false }

     @MainActor enum InterstitialPacing {
         static let minInterval: TimeInterval = 60
         static var lastShownAt: Date?
     }
     ```

2. **Create one ad loader and load the ad in advance**

   - [ ] The modifier owns the loader. Add to your screen:

     ```swift
     struct GameView: View {
         private static let interstitialAdUnitID = "demo-interstitial-yandex"
         @State private var interstitialRequest: AdRequest?
         @State private var isInterstitialPresented = false
         @State private var isInterstitialLoaded = false

         var body: some View {
             Button("Next level") { levelDidFinish() }
                 .interstitialAd(isPresented: $isInterstitialPresented, request: $interstitialRequest) { event in
                     handleInterstitialEvent(event)
                 }
                 .task {
                     await AdsStartup.waitUntilReady()
                     requestInterstitialIfNeeded()
                 }
         }

         private func requestInterstitialIfNeeded() {
             guard interstitialRequest == nil, !isInterstitialLoaded else { return }
             interstitialRequest = AdRequest(adUnitID: Self.interstitialAdUnitID)
         }
     }
     ```

   - [ ] Gate the first load on the project's startup/ATT readiness flow.
     The async example uses `await AdsStartup.waitUntilReady()` from
     get-started; a completion-based flow starts the load from its
     readiness callback. Omit this gate only if readiness is already
     handled elsewhere or no gate is needed.

3. **Register for ad events**

   ```swift
   extension GameView {
       private func handleInterstitialEvent(_ event: InterstitialAdEvent) {
           switch event {
           case .didLoad: isInterstitialLoaded = true
           case .didShow: InterstitialPacing.lastShownAt = Date()
           case .didDismiss, .didFailToShow:
               isInterstitialLoaded = false
               FullscreenAdState.isFullscreenAdShowing = false
               interstitialRequest = AdRequest(adUnitID: Self.interstitialAdUnitID)
               openNextLevel()
           case .didFailToLoad(let error):
               print("Interstitial failed to load: \(error)")
               interstitialRequest = nil
           case .didClick, .didTrackImpression: break
           }
       }
   }
   ```

4. **Show the ad at the transition point if it is loaded**

   ```swift
   extension GameView {
       private func levelDidFinish() {
           guard !isInterstitialPresented else { return }
           let hasIntervalPassed = Date().timeIntervalSince(InterstitialPacing.lastShownAt ?? .distantPast)
               >= InterstitialPacing.minInterval
           guard isInterstitialLoaded, hasIntervalPassed, !FullscreenAdState.isFullscreenAdShowing else {
               requestInterstitialIfNeeded()
               return openNextLevel()
           }
           FullscreenAdState.isFullscreenAdShowing = true
           isInterstitialPresented = true
       }
   }
   ```

5. **Release the shown ad and load the next one**

   - [ ] Done by the handler in step 3: one transition and a new `AdRequest`
     on `.didDismiss` and `.didFailToShow`.

## Verify the build

- [ ] Build the app scheme for a simulator as in the get-started guide
  (`xcodebuild ... -destination 'generic/platform=iOS Simulator' build`) or ask
  the user to build in Xcode; fix compile errors related to the Yandex SDK.

### Links

- https://ads.yandex.com/helpcenter/en/dev/ios/swiftui/interstitial.md
- https://ads.yandex.com/helpcenter/en/dev/ios/demo-blocks.md
