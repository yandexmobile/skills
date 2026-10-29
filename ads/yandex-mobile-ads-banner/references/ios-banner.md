# AI Integration Agent Instructions for iOS Banner Ads

Apply [iOS API selection](../SKILL.md#ios-api-selection) before using
these examples. Adapt the snippets to the selected project conventions.

## Required Imports

```swift
import UIKit
import YandexMobileAds
```

## Method Signatures

```swift
BannerAdSize.sticky(containerWidth: CGFloat) -> BannerAdSize
BannerAdSize.inline(width: CGFloat, maxHeight: CGFloat) -> BannerAdSize

BannerAdView(adSize: BannerAdSize)
weak var delegate: BannerAdViewDelegate?
func loadAd(with request: AdRequest)
func displayAtTop(in view: UIView)
func displayAtBottom(in view: UIView)

AdRequest(adUnitID: String)
```

`BannerAdViewDelegate` (`@MainActor`, `NSObjectProtocol`) has four required
methods, listed in step 3.

`BannerAdView.loadAd(with:)` reports loading through its delegate; it has
no async/completion overload choice. Apply the selected style to the
startup-ready flow around it. A callback-based flow calls `loadAd(with:)`
from that callback without the example's `Task`.

## Gotchas

- The size is fixed when the view is created. `safeAreaLayoutGuide` is
  zero-sized in `viewDidLoad`, so create the banner after layout. If the width
  can change (rotation, split view), remove the banner and create a new one
  for the new width.
- `displayAtBottom(in:)` pins the banner to the bottom of the view's safe
  area, so in a `UITabBarController` it sits above the tab bar. It overlays the
  content: add a bottom inset to scroll views.
- Do not add a fixed height constraint: the view sets its intrinsic content
  size from the loaded ad. It stays transparent until the ad loads.
- The delegate must be an `NSObject` subclass. Keep a strong reference to the
  banner.
- Capture `self` weakly in `Task` closures.
- If the project does not use synchronized folders, add new files to the
  app target (see the get-started guide).

## Banner workflow

1. **Choose the placement and the banner type**

   - [ ] Sticky goes to the top or bottom edge of the screen's root view;
     inline goes into the scrolling content, for example a stack view.

2. **Create the ad view with the size computed from the container width**

   - [ ] Add to your view controller. Sticky uses the width of the safe area:

     ```swift
     final class FeedViewController: UIViewController {
         private static let bannerAdUnitID = "demo-banner-yandex"
         private var bannerAdView: BannerAdView?
         private var isBannerLoaded = false
         private var isLoadingBanner = false

         override func viewDidLayoutSubviews() {
             super.viewDidLayoutSubviews()
             let width = view.safeAreaLayoutGuide.layoutFrame.width
             guard bannerAdView == nil, width > 0 else { return }
             let bannerAdView = BannerAdView(adSize: .sticky(containerWidth: width))
             bannerAdView.delegate = self
             bannerAdView.displayAtBottom(in: view)
             self.bannerAdView = bannerAdView
             loadBannerIfNeeded()
         }

         override func viewWillAppear(_ animated: Bool) {
             super.viewWillAppear(animated)
             loadBannerIfNeeded()
         }
     }
     ```

   - [ ] Inline: `BannerAdSize.inline(width:maxHeight:)` with the width of the
     content column, placed with Auto Layout.

3. **Register for ad events**

   ```swift
   extension FeedViewController: BannerAdViewDelegate {
       func bannerAdViewDidLoad(_ bannerAdView: BannerAdView) {
           isBannerLoaded = true
           isLoadingBanner = false
       }
       func bannerAdViewDidFailLoading(_ bannerAdView: BannerAdView, error: Error) {
           isLoadingBanner = false
           print("Banner failed to load: \(error)")
       }
       func bannerAdViewDidClick(_ bannerAdView: BannerAdView) {}
       func bannerAdView(_ bannerAdView: BannerAdView, didTrackImpression impressionData: ImpressionData?) {}
   }
   ```

4. **Load the ad**

   - [ ] Load once per banner view; the banner refreshes itself afterwards.
     After a failure do not retry at once: `viewWillAppear` loads again the
     next time the screen is shown.

     ```swift
     extension FeedViewController {
         private func loadBannerIfNeeded() {
             guard bannerAdView != nil, !isBannerLoaded, !isLoadingBanner else { return }
             isLoadingBanner = true
             Task { [weak self] in
                 await AdsStartup.waitUntilReady()
                 self?.bannerAdView?.loadAd(with: AdRequest(adUnitID: Self.bannerAdUnitID))
             }
         }
     }
     ```

   - [ ] Gate the first load on the project's startup/ATT readiness flow.
     The async example uses `await AdsStartup.waitUntilReady()` from
     get-started; a completion-based flow starts the load from its
     readiness callback. Omit this gate only if readiness is already
     handled elsewhere or no gate is needed.

5. **Release the ad view with its screen**

   - [ ] The screen owns the banner; never keep it in a singleton or static.
     To remove it earlier, call `removeFromSuperview()` and drop the
     reference.

## Verify the build

- [ ] Build the app scheme for a simulator as in the get-started guide
  (`xcodebuild ... -destination 'generic/platform=iOS Simulator' build`) or ask
  the user to build in Xcode; fix compile errors related to the Yandex SDK.

### Links

- https://ads.yandex.com/helpcenter/en/dev/ios/adaptive-sticky-banner.md?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-banner
- https://ads.yandex.com/helpcenter/en/dev/ios/adaptive-inline-banner.md?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-banner
- https://ads.yandex.com/helpcenter/en/dev/ios/demo-blocks.md?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-banner
