# AI Integration Agent Instructions for iOS Rewarded Ads with SwiftUI

## Required Imports

```swift
import SwiftUI
import YandexMobileAds
```

## Method Signatures

SwiftUI API, SDK 8.0.0+:

```swift
func rewardedAd(
    isPresented: Binding<Bool>,
    request: Binding<AdRequest?>,
    onEvent: ((RewardedAdEvent) -> Void)? = nil
) -> some View

enum RewardedAdEvent {
    case didLoad(AdInfo?), didShow, didDismiss, didClick, didReward(Reward)
    case didFailToShow(Error), didFailToLoad(Error), didTrackImpression(ImpressionData?)
}
```

## Gotchas

- `.didReward` fires when the impression is counted. Grant the reward there,
  not on show or dismiss.
- A non-`nil` `request` starts loading (`nil` cancels it); `isPresented =
  true` shows the loaded ad and returns to `false` after a dismiss or failure.
- Attach the modifier to a view that lives for the whole flow (screen or
  navigation root), otherwise the loaded ad is lost.
- After `.didFailToLoad` set `request` to `nil` and assign a new request the
  next time the screen appears, never at once. After `.didDismiss` and
  `.didFailToShow` assign a new `AdRequest` to load the next ad.
- Reset `FullscreenAdState.isFullscreenAdShowing` only in `.didDismiss` and
  `.didFailToShow`, not in `.onDisappear`: the ad is a full-screen modal, so
  the content under it disappears while the ad is still on screen.
- If the project does not use synchronized folders, add new files to the
  app target (see the get-started guide).

Names such as `ShopView` or `grantReward()` in the snippets are placeholders
for the app's own code.

## Rewarded workflow

1. **Choose the control that offers the reward and the reward itself**

   - [ ] Find or add the button and the code that grants the reward. Add the
     app-wide flag; declare it once per app, skip it if it already exists:

     ```swift
     @MainActor enum FullscreenAdState { static var isFullscreenAdShowing = false }
     ```

2. **Create one ad loader and load the ad in advance**

   - [ ] The modifier owns the loader. Add to your screen; `.task` runs every
     time the screen appears:

     ```swift
     struct ShopView: View {
         private static let rewardedAdUnitID = "demo-rewarded-yandex"
         @State private var rewardedRequest: AdRequest?
         @State private var isRewardedPresented = false
         @State private var isRewardedLoaded = false

         var body: some View {
             Button("Watch an ad for 50 coins") { showRewardedAd() }
                 .disabled(!isRewardedLoaded || isRewardedPresented)
                 .rewardedAd(isPresented: $isRewardedPresented, request: $rewardedRequest) { event in
                     handleRewardedEvent(event)
                 }
                 .task {
                     await AdsStartup.waitUntilReady()
                     if rewardedRequest == nil { rewardedRequest = AdRequest(adUnitID: Self.rewardedAdUnitID) }
                 }
         }
     }
     ```

   - [ ] If the project has `AdsStartup` (from get-started), keep
     `await AdsStartup.waitUntilReady()` before the first load; otherwise
     drop that line.

3. **Register for ad events and grant the reward in the reward callback**

   ```swift
   extension ShopView {
       private func handleRewardedEvent(_ event: RewardedAdEvent) {
           switch event {
           case .didLoad: isRewardedLoaded = true
           case .didReward: grantReward()
           case .didDismiss, .didFailToShow:
               isRewardedLoaded = false
               FullscreenAdState.isFullscreenAdShowing = false
               rewardedRequest = AdRequest(adUnitID: Self.rewardedAdUnitID)
           case .didFailToLoad(let error):
               print("Rewarded ad failed to load: \(error)")
               rewardedRequest = nil
           case .didShow, .didClick, .didTrackImpression: break
           }
       }
   }
   ```

   - [ ] Grant the reward the button offered. Use `reward.amount` and
     `reward.type` from `.didReward(let reward)` only if the user says the
     reward is configured on the ad unit; demo ad units return a test value.

4. **Show the ad when the user taps the control**

   ```swift
   extension ShopView {
       private func showRewardedAd() {
           guard isRewardedLoaded, !isRewardedPresented, !FullscreenAdState.isFullscreenAdShowing else { return }
           FullscreenAdState.isFullscreenAdShowing = true
           isRewardedPresented = true
       }
   }
   ```

5. **Release the shown ad and load the next one**

   - [ ] Done by the handler in step 3: a new `AdRequest` on `.didDismiss` and
     `.didFailToShow`.

## Verify the build

- [ ] Build the app scheme for a simulator as in the get-started guide
  (`xcodebuild ... -destination 'generic/platform=iOS Simulator' build`) or ask
  the user to build in Xcode; fix compile errors related to the Yandex SDK.

### Links

- https://ads.yandex.com/helpcenter/en/dev/ios/swiftui/rewarded.md
- https://ads.yandex.com/helpcenter/en/dev/ios/demo-blocks.md
