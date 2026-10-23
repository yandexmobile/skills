# AI Integration Agent Instructions for iOS App Open Ads

Apply [iOS API selection](../SKILL.md#ios-api-selection) before using
these examples. Adapt the snippets to the selected project conventions.

## Required Imports

```swift
import UIKit
import YandexMobileAds
```

## Method Signatures

```swift
AppOpenAdLoader()
func loadAd(with request: AdRequest) async throws -> AppOpenAd
func loadAd(with request: AdRequest, completion: @escaping @MainActor (Result<AppOpenAd, Error>) -> Void)

@MainActor final class AppOpenAd {
    weak var delegate: AppOpenAdDelegate?
    func show(from viewController: UIViewController?)
}
```

`AppOpenAdDelegate` (`@MainActor`) has five required methods (step 6).

For completion-based integration, call `loadAd(with:completion:)` from
the selected startup-ready callback. Move the example's success/error
handling into the `Result` switch, retain the ad and assign its delegate
on success, and clear the loading flag on both paths. The outer `Task`
is only needed for the async version.

## Gotchas

- `UIApplication.didBecomeActiveNotification` also fires after system dialogs
  (ATT prompt, permission alerts, Control Center) without the app going to
  the background; decide on `didEnterBackground` + `didBecomeActive`.
- Only one full-screen ad can be on screen
  (`AdErrorCode.adHasAlreadyBeenPresented`, SDK 8.4.0+; on 8.0–8.3 compare
  `(error as NSError).code`); a presenting controller also fails the show.
- App open ads are served only in portrait. If the app is landscape-only, tell
  the user the format will not fill and stop.
- Do not use the SwiftUI `.appOpenAd(request:onEvent:)` modifier: it shows on
  every return and cannot apply these rules. SwiftUI apps use the manager
  below through `@UIApplicationDelegateAdaptor`.
- Capture `self` weakly in `Task` closures. If the project does not use
  synchronized folders, add new files to the app target (see the get-started
  guide).

## App open workflow

1. **Create an app-level manager that owns the ad loader**

   - [ ] Add a new file with the app-wide flag (declare it once per app, skip
     it if it already exists) and the manager:

     ```swift
     @MainActor enum FullscreenAdState { static var isFullscreenAdShowing = false }

     @MainActor
     final class AppOpenAdManager: NSObject {
         static let shared = AppOpenAdManager()
         private static let adUnitID = "demo-appopenad-yandex"
         private static let minBackgroundInterval: TimeInterval = 30

         private let loader = AppOpenAdLoader()
         private var appOpenAd: AppOpenAd?
         private var isLoading = false
         private var backgroundedAt: Date?
     }
     ```

   - [ ] Keep the existing `initializeSDK` call; add
     `AppOpenAdManager.shared.startObserving()` next to it. A SwiftUI app
     without an app delegate adds one with `@UIApplicationDelegateAdaptor`.

2. **Load the ad after the SDK is initialized**

   - [ ] The first load runs when the app first goes to the background (or
     after the first screen's ads have loaded), not together with the other
     formats at launch. After a failure the next return loads again.

     ```swift
     extension AppOpenAdManager {
         func loadAdIfNeeded() {
             guard appOpenAd == nil, !isLoading else { return }
             isLoading = true
             Task { [weak self] in
                 await AdsStartup.waitUntilReady()
                 guard let self else { return }
                 do {
                     let ad = try await loader.loadAd(with: AdRequest(adUnitID: Self.adUnitID))
                     ad.delegate = self
                     appOpenAd = ad
                 } catch {
                     print("App open ad failed to load: \(error)")
                 }
                 isLoading = false
             }
         }
     }
     ```

   - [ ] Gate the first load on the project's startup/ATT readiness flow.
     The async example uses `await AdsStartup.waitUntilReady()` from
     get-started; a completion-based flow starts the load from its
     readiness callback. Omit this gate only if readiness is already
     handled elsewhere or no gate is needed.

3. **Detect the moment the app comes to the foreground**

   ```swift
   extension AppOpenAdManager {
       func startObserving() {
           let center = NotificationCenter.default
           center.addObserver(self, selector: #selector(appDidEnterBackground),
                              name: UIApplication.didEnterBackgroundNotification, object: nil)
           center.addObserver(self, selector: #selector(appDidBecomeActive),
                              name: UIApplication.didBecomeActiveNotification, object: nil)
       }
       @objc private func appDidEnterBackground() {
           backgroundedAt = Date()
           loadAdIfNeeded()
       }
       @objc private func appDidBecomeActive() {
           guard let backgroundedAt else { return }
           self.backgroundedAt = nil
           guard Date().timeIntervalSince(backgroundedAt) >= Self.minBackgroundInterval else { return }
           showAdIfAvailable()
       }
   }
   ```

4. **Show the ad if it is loaded and nothing from the rules forbids it**

   ```swift
   extension AppOpenAdManager {
       func showAdIfAvailable() {
           let scene = UIApplication.shared.connectedScenes
               .compactMap { $0 as? UIWindowScene }
               .first { $0.activationState == .foregroundActive }
           guard let appOpenAd, !FullscreenAdState.isFullscreenAdShowing,
                 let scene, scene.interfaceOrientation.isPortrait,
                 let rootViewController = scene.keyWindow?.rootViewController,
                 rootViewController.presentedViewController == nil else {
               return loadAdIfNeeded()
           }
           FullscreenAdState.isFullscreenAdShowing = true
           appOpenAd.show(from: rootViewController)
       }
   }
   ```

   - [ ] The cold start is skipped: the first show happens on a later return.
     Tell the user this in the final message.
   - [ ] Ask the user for a frequency rule (not in the first sessions, not on
     every return); if the user gave one, add a check before `show`.

5. **Make the interstitial and rewarded ads already in the app set the flag**

   - [ ] For every existing `InterstitialAd`, `RewardedAd`, `.interstitialAd`
     or `.rewardedAd` in the project: set
     `FullscreenAdState.isFullscreenAdShowing = true` right before showing
     (`show(from:)` or `isPresented = true`) and `false` in the dismiss and
     fail-to-show callbacks.

     ```swift
     FullscreenAdState.isFullscreenAdShowing = false
     ```

6. **Release the shown ad and load the next one**

   ```swift
   extension AppOpenAdManager: AppOpenAdDelegate {
       func appOpenAdDidShow(_ appOpenAd: AppOpenAd) {}
       func appOpenAdDidDismiss(_ appOpenAd: AppOpenAd) { releaseAndReload() }
       func appOpenAd(_ appOpenAd: AppOpenAd, didFailToShow error: Error) { releaseAndReload() }
       func appOpenAdDidClick(_ appOpenAd: AppOpenAd) {}
       func appOpenAd(_ appOpenAd: AppOpenAd, didTrackImpression impressionData: ImpressionData?) {}
       private func releaseAndReload() {
           appOpenAd = nil
           FullscreenAdState.isFullscreenAdShowing = false
           loadAdIfNeeded()
       }
   }
   ```

## Verify the build

- [ ] Build the app scheme for a simulator as in the get-started guide
  (`xcodebuild ... -destination 'generic/platform=iOS Simulator' build`) or ask
  the user to build in Xcode; fix compile errors related to the Yandex SDK.

### Links

- https://ads.yandex.com/helpcenter/en/dev/ios/app-open-ad.md
- https://ads.yandex.com/helpcenter/en/dev/ios/demo-blocks.md
