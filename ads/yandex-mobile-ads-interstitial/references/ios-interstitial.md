# AI Integration Agent Instructions for iOS Interstitial Ads

## Required Imports

```swift
import UIKit
import YandexMobileAds
```

## Method Signatures

```swift
InterstitialAdLoader()
func loadAd(with request: AdRequest) async throws -> InterstitialAd

@MainActor final class InterstitialAd {
    weak var delegate: InterstitialAdDelegate?
    func show(from viewController: UIViewController?)
}
```

`InterstitialAdDelegate` (`@MainActor`) has five required methods, listed in
step 3.

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

   - [ ] If the project has `AdsStartup` (from get-started), keep
     `await AdsStartup.waitUntilReady()` before the first load; otherwise
     drop that line.

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

- https://ads.yandex.com/helpcenter/en/dev/ios/interstitial.md
- https://ads.yandex.com/helpcenter/en/dev/ios/demo-blocks.md
