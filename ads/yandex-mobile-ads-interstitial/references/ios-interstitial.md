# AI Integration Agent Instructions for iOS Interstitial Ads

Apply [iOS API selection](../SKILL.md#ios-api-selection) before using
these examples. Adapt the snippets to the selected project conventions.

## Required Imports

```swift
import UIKit
import YandexMobileAds
```

## Method Signatures

```swift
InterstitialAdLoader()
func loadAd(with request: AdRequest) async throws -> InterstitialAd
func loadAd(with request: AdRequest, completion: @escaping @MainActor (Result<InterstitialAd, Error>) -> Void)

@MainActor final class InterstitialAd {
    weak var delegate: InterstitialAdDelegate?
    func show(from viewController: UIViewController?)
}
```

`InterstitialAdDelegate` (`@MainActor`) has five required methods, listed in
step 3.

For completion-based integration, call `loadAd(with:completion:)` from
the selected startup-ready callback. Move the example's success/error
handling into the `Result` switch, retain the ad and assign its delegate
on success, and clear the loading flag on both paths. The outer `Task`
is only needed for the async version.

## Gotchas

- The loader does not keep the ad: keep it in a property and set the property
  to `nil` in the dismiss and fail-to-show callbacks. `delegate` is weak.
- An ad can be shown once, and only one full-screen ad can be on screen.
  Otherwise `show(from:)` fails with `AdErrorCode.adHasAlreadyBeenPresented`
  (SDK 8.4.0+; on 8.0–8.3 compare `(error as NSError).code` instead).
- Pass a view controller that is on screen and not presenting anything.
- If the screen can close while the ad is on screen, reset
  `FullscreenAdState.isFullscreenAdShowing` in `viewDidDisappear` when
  `isBeingDismissed || isMovingFromParent`.
- Capture `self` weakly in `Task` closures.
- If the project does not use synchronized folders, add new files to the
  app target (see the get-started guide).

Names such as `GameViewController` or `openNextLevel()` in the snippets are
placeholders for the app's own code.

## Interstitial workflow

1. **Choose the transition point where the ad is shown**

   - [ ] Find the code that performs the transition. Add the app-wide state
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

   - [ ] Add to your view controller and call `loadInterstitialAdIfNeeded()`
     from `viewDidLoad`. After a failure do not retry at once: the next
     transition loads again.

     ```swift
     final class GameViewController: UIViewController {
         private static let interstitialAdUnitID = "demo-interstitial-yandex"
         private let interstitialAdLoader = InterstitialAdLoader()
         private var interstitialAd: InterstitialAd?
         private var isLoadingInterstitial = false
         private var isShowingInterstitial = false

         private func loadInterstitialAdIfNeeded() {
             guard interstitialAd == nil, !isLoadingInterstitial else { return }
             isLoadingInterstitial = true
             Task { [weak self] in
                 await AdsStartup.waitUntilReady()
                 guard let self else { return }
                 do {
                     let ad = try await interstitialAdLoader.loadAd(
                         with: AdRequest(adUnitID: Self.interstitialAdUnitID)
                     )
                     ad.delegate = self
                     interstitialAd = ad
                 } catch {
                     print("Interstitial failed to load: \(error)")
                 }
                 isLoadingInterstitial = false
             }
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
   extension GameViewController: InterstitialAdDelegate {
       func interstitialAdDidShow(_ interstitialAd: InterstitialAd) {
           InterstitialPacing.lastShownAt = Date()
       }
       func interstitialAdDidDismiss(_ interstitialAd: InterstitialAd) { finishTransition() }
       func interstitialAd(_ interstitialAd: InterstitialAd, didFailToShow error: Error) { finishTransition() }
       func interstitialAdDidClick(_ interstitialAd: InterstitialAd) {}
       func interstitialAd(_ interstitialAd: InterstitialAd, didTrackImpression impressionData: ImpressionData?) {}
   }
   ```

4. **Show the ad at the transition point if it is loaded**

   - [ ] Ignore repeated triggers while the ad is on screen; otherwise show
     the ad or run the transition right away:
     If the transition needs data (the selected item), store it before `show`
     and use it in `finishTransition`.

     ```swift
     extension GameViewController {
         func levelDidFinish() {
             guard !isShowingInterstitial else { return }
             let hasIntervalPassed = Date().timeIntervalSince(InterstitialPacing.lastShownAt ?? .distantPast)
                 >= InterstitialPacing.minInterval
             guard let interstitialAd, hasIntervalPassed, !FullscreenAdState.isFullscreenAdShowing else {
                 loadInterstitialAdIfNeeded()
                 return openNextLevel()
             }
             isShowingInterstitial = true
             FullscreenAdState.isFullscreenAdShowing = true
             interstitialAd.show(from: self)
         }
     }
     ```

5. **Release the shown ad and load the next one**

   ```swift
   extension GameViewController {
       private func finishTransition() {
           interstitialAd = nil
           isShowingInterstitial = false
           FullscreenAdState.isFullscreenAdShowing = false
           openNextLevel()
           loadInterstitialAdIfNeeded()
       }
   }
   ```

## Verify the build

- [ ] Build the app scheme for a simulator as in the get-started guide
  (`xcodebuild ... -destination 'generic/platform=iOS Simulator' build`) or ask
  the user to build in Xcode; fix compile errors related to the Yandex SDK.

### Links

- https://ads.yandex.com/helpcenter/en/dev/ios/interstitial.md?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-interstitial
- https://ads.yandex.com/helpcenter/en/dev/ios/demo-blocks.md?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-interstitial
