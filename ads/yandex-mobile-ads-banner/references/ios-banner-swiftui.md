# AI Integration Agent Instructions for iOS Banner Ads with SwiftUI

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
BannerState(size: BannerSize, request: AdRequest)
enum BannerSize {
    case sticky(width: CGFloat? = nil)
    case inline(width: CGFloat, maxHeight: CGFloat)
}
Banner(state: BannerState)
    .onAdLoad { (AdInfo?) in }
    .onAdFailure { (Error) in }
    .onAdClick { }
    .onAdImpression { (ImpressionData?) in }

AdRequest(adUnitID: String)
```

The SDK view/modifier below owns loading. The API choice applies to
the surrounding startup/readiness code; a callback-based flow updates
the same state from its readiness callback instead of awaiting in `.task`.
Keep the SDK view/modifier unless the project's architecture requires
a custom loader; in that case use the [UIKit loader/view guide](ios-banner.md)
and adapt its presentation to SwiftUI.

## Gotchas

- `Banner` loads when it first appears with a `BannerState`, and again only
  when it gets a different `BannerState` instance (every `BannerState(...)`
  call creates a new one). Re-rendering with the same instance does not
  reload, so keep the state in `@State`, never create it inside `body`.
- SwiftUI uses the enum `BannerSize`, UIKit uses the class `BannerAdSize`.
  They are different types: do not mix them.
- The banner refreshes itself after a successful load.
- If the project does not use synchronized folders, add new files to the
  app target (see the get-started guide).

Names such as `FeedContent` in the snippets are placeholders for the app's own
code.

## Banner workflow

1. **Choose the placement and the banner type**

   - [ ] Sticky: at the bottom or top of the screen's root stack, outside the
     scrolling content. Inline: inside the `ScrollView` content.

2. **Create the ad view with the size computed from the container width**

   - [ ] `.sticky()` takes the width of the container `Banner` is placed in;
     `.inline(width:maxHeight:)` needs the width explicitly, for example from
     a `GeometryReader`. Add to your screen:

     ```swift
     struct FeedView: View {
         private static let bannerAdUnitID = "demo-banner-yandex"
         @State private var bannerState: BannerState?
         @State private var isBannerLoaded = false
         @State private var isLoadingBanner = false

         var body: some View {
             VStack(spacing: 0) {
                 FeedContent()
                 if let bannerState {
                     Banner(state: bannerState)
                         .onAdLoad { _ in
                             isBannerLoaded = true
                             isLoadingBanner = false
                         }
                         .onAdFailure { error in
                             isLoadingBanner = false
                             print("Banner failed to load: \(error)")
                         }
                 }
             }
             .task { await loadBannerIfNeeded() }
         }
     }
     ```

3. **Register for ad events**

   - [ ] Use the modifiers on `Banner` above: `.onAdLoad`, `.onAdFailure`,
     `.onAdClick`, `.onAdImpression`.

4. **Load the ad**

   - [ ] `.task` runs every time the screen appears. After a failure it loads
     again then, never at once:

     ```swift
     extension FeedView {
         private func loadBannerIfNeeded() async {
             guard !isBannerLoaded, !isLoadingBanner else { return }
             isLoadingBanner = true
             await AdsStartup.waitUntilReady()
             bannerState = BannerState(size: .sticky(), request: AdRequest(adUnitID: Self.bannerAdUnitID))
         }
     }
     ```

   - [ ] Gate the first load on the project's startup/ATT readiness flow.
     The async example uses `await AdsStartup.waitUntilReady()` from
     get-started; a completion-based flow starts the load from its
     readiness callback. Omit this gate only if readiness is already
     handled elsewhere or no gate is needed.

5. **Release the ad view with its screen**

   - [ ] Keep the state in the screen's own `@State`, never in a singleton.
     Removing `Banner` from the hierarchy releases the ad.

## Verify the build

- [ ] Build the app scheme for a simulator as in the get-started guide
  (`xcodebuild ... -destination 'generic/platform=iOS Simulator' build`) or ask
  the user to build in Xcode; fix compile errors related to the Yandex SDK.

### Links

- https://ads.yandex.com/helpcenter/en/dev/ios/swiftui/adaptive-sticky-banner.md?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-banner
- https://ads.yandex.com/helpcenter/en/dev/ios/swiftui/adaptive-inline-banner.md?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-banner
- https://ads.yandex.com/helpcenter/en/dev/ios/demo-blocks.md?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-banner
