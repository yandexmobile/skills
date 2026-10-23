# AI Integration Agent Instructions for iOS Rewarded Ads

Apply [iOS API selection](../SKILL.md#ios-api-selection) before using
these examples. Adapt the snippets to the selected project conventions.

## Required Imports

```swift
import UIKit
import YandexMobileAds
```

## Method Signatures

```swift
RewardedAdLoader()
func loadAd(with request: AdRequest) async throws -> RewardedAd
func loadAd(with request: AdRequest, completion: @escaping @MainActor (Result<RewardedAd, Error>) -> Void)

@MainActor final class RewardedAd {
    weak var delegate: RewardedAdDelegate?
    func show(from viewController: UIViewController?)
}

protocol Reward { var amount: Int { get }; var type: String { get } }
```

`RewardedAdDelegate` (`@MainActor`) has six required methods, listed in
step 3.

For completion-based integration, call `loadAd(with:completion:)` from
the selected startup-ready callback. Move the example's success/error
handling into the `Result` switch, retain the ad and assign its delegate
on success, and clear the loading flag on both paths. The outer `Task`
is only needed for the async version.

## Gotchas

- `rewardedAd(_:didReward:)` fires when the impression is counted. Grant the
  reward there, not on show or dismiss.
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

Names such as `ShopViewController`, `watchAdButton` or `grantReward()` in the
snippets are placeholders for the app's own code.

## Rewarded workflow

1. **Choose the control that offers the reward and the reward itself**

   - [ ] Find or add the button ("Watch an ad for 50 coins") and the code that
     grants that reward. Add the app-wide flag; declare it once per app, skip
     it if it already exists:

     ```swift
     @MainActor enum FullscreenAdState { static var isFullscreenAdShowing = false }
     ```

2. **Create one ad loader and load the ad in advance**

   - [ ] Add to your view controller and call `loadRewardedAdIfNeeded()` from
     `viewWillAppear`. After a failure do not retry at once: the next time the
     screen is shown loads again.

     ```swift
     final class ShopViewController: UIViewController {
         private static let rewardedAdUnitID = "demo-rewarded-yandex"
         private let rewardedAdLoader = RewardedAdLoader()
         private let watchAdButton = UIButton(type: .system)
         private var rewardedAd: RewardedAd?
         private var isLoadingRewarded = false
         private var isShowingRewarded = false

         private func loadRewardedAdIfNeeded() {
             guard rewardedAd == nil, !isLoadingRewarded else { return }
             isLoadingRewarded = true
             Task { [weak self] in
                 await AdsStartup.waitUntilReady()
                 guard let self else { return }
                 do {
                     let ad = try await rewardedAdLoader.loadAd(with: AdRequest(adUnitID: Self.rewardedAdUnitID))
                     ad.delegate = self
                     rewardedAd = ad
                 } catch {
                     print("Rewarded ad failed to load: \(error)")
                 }
                 isLoadingRewarded = false
                 watchAdButton.isEnabled = rewardedAd != nil
             }
         }
     }
     ```

   - [ ] Gate the first load on the project's startup/ATT readiness flow.
     The async example uses `await AdsStartup.waitUntilReady()` from
     get-started; a completion-based flow starts the load from its
     readiness callback. Omit this gate only if readiness is already
     handled elsewhere or no gate is needed.

3. **Register for ad events and grant the reward in the reward callback**

   ```swift
   extension ShopViewController: RewardedAdDelegate {
       func rewardedAd(_ rewardedAd: RewardedAd, didReward reward: Reward) { grantReward() }
       func rewardedAdDidShow(_ rewardedAd: RewardedAd) {}
       func rewardedAdDidDismiss(_ rewardedAd: RewardedAd) { releaseRewardedAdAndReload() }
       func rewardedAd(_ rewardedAd: RewardedAd, didFailToShow error: Error) { releaseRewardedAdAndReload() }
       func rewardedAdDidClick(_ rewardedAd: RewardedAd) {}
       func rewardedAd(_ rewardedAd: RewardedAd, didTrackImpression impressionData: ImpressionData?) {}
   }
   ```

   - [ ] Grant the reward the button offered. Use `reward.amount` and
     `reward.type` only if the user says the reward is configured on the ad
     unit; demo ad units return a test value.

4. **Show the ad when the user taps the control**

   - [ ] Start with `watchAdButton.isEnabled = false` and connect the button
     to this action; it is enabled only while an ad is loaded and not shown:

     ```swift
     extension ShopViewController {
         @objc func watchAdButtonTapped() {
             guard let rewardedAd, !isShowingRewarded, !FullscreenAdState.isFullscreenAdShowing else { return }
             watchAdButton.isEnabled = false
             isShowingRewarded = true
             FullscreenAdState.isFullscreenAdShowing = true
             rewardedAd.show(from: self)
         }
     }
     ```

5. **Release the shown ad and load the next one**

   ```swift
   extension ShopViewController {
       private func releaseRewardedAdAndReload() {
           rewardedAd = nil
           isShowingRewarded = false
           FullscreenAdState.isFullscreenAdShowing = false
           loadRewardedAdIfNeeded()
       }
   }
   ```

## Verify the build

- [ ] Build the app scheme for a simulator as in the get-started guide
  (`xcodebuild ... -destination 'generic/platform=iOS Simulator' build`) or ask
  the user to build in Xcode; fix compile errors related to the Yandex SDK.

### Links

- https://ads.yandex.com/helpcenter/en/dev/ios/rewarded.md
- https://ads.yandex.com/helpcenter/en/dev/ios/demo-blocks.md
