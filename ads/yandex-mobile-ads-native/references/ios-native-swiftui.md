# AI Integration Agent Instructions for iOS Native Ads with SwiftUI

## Required Imports

```swift
import SwiftUI
import YandexMobileAds
```

## Method Signatures

SwiftUI API, requires SDK 8.6.0+ (older SDK 8 versions: use the UIKit guide):

```swift
@MainActor final class NativeAdState: ObservableObject, Identifiable {
    convenience init(request: AdRequest, options: NativeAdOptions = .init())
    init(ad: NativeAd)
    func loadAd()
}
NativeAdContainer(state: NativeAdState, content: { (NativeAdLayoutInfo) in ... }, placeholder: { ... })
    .onAdBindingFailure { (Error) in }  .onAdClick { }  .onAdImpression { (ImpressionData?) in }
NativeAdAsset.Title(), .Body(), .CallToAction(), .Domain(), .Sponsored(), .Age(), .Price(),
    .ReviewCount(), .Warning(), .Icon(), .Favicon(), .Media(), .Feedback(), .Rating { (Double) in }
NativeBulkAdLoader()
func loadAds(with request: AdRequest, adsCount: UInt, options: NativeAdOptions = .init()) async throws -> [NativeAd]
```

## Gotchas

- Render assets only through `NativeAdAsset` primitives inside the
  `NativeAdContainer` content; anything else is not registered with the SDK.
- The docs always require title, domain, warning, sponsored, feedback, call to
  action and media, plus icon and price for app install ads
  ([components](https://ads.yandex.com/helpcenter/en/dev/ios/components.md)).
  A missing required asset calls `.onAdBindingFailure`. Hidden, transparent
  or too small assets do not, but the impression is not counted. For video
  keep the card and the media at least 300 x 160 points.
- One `NativeAdState` serves one container; keep the states in a model or
  `@StateObject`, never create them in `body` or `ForEach`. If the project
  does not use synchronized folders, add new files to the app target
  (see the get-started guide).

Names such as `FeedView` or `items` in the snippets are placeholders for the
app's own code.

## Native workflow

1. **Choose the placement and how many ads it needs**

   - [ ] Feed (main case): `NativeBulkAdLoader`, up to 9 ads, after every N items.

2. **Create the ad layout with a view for every asset**

   ```swift
   struct NativeAdCard: View {
       let layout: NativeAdLayoutInfo

       var body: some View {
           VStack(alignment: .leading, spacing: 8) {
               HStack {
                   NativeAdAsset.Sponsored(); NativeAdAsset.Age(); Spacer()
                   if layout.has(.feedback) { NativeAdAsset.Feedback().frame(width: 24, height: 24) }
               }
               HStack {
                   if layout.has(.icon) { NativeAdAsset.Icon().frame(width: 40, height: 40) }
                   NativeAdAsset.Title().font(.headline)
               }
               NativeAdAsset.Media()
               NativeAdAsset.Body()
               HStack {
                   if layout.has(.favicon) { NativeAdAsset.Favicon().frame(width: 14, height: 14) }
                   NativeAdAsset.Domain(); NativeAdAsset.Rating { Text(String(format: "%.1f", $0)) }
                   NativeAdAsset.ReviewCount(); NativeAdAsset.Price()
               }
               NativeAdAsset.CallToAction()
               NativeAdAsset.Warning().font(.caption2)
           }
           .padding(12)
           .background(Color(.systemBackground))
       }
   }
   ```

3. **Create one ad loader and load the ads**

   - [ ] Add a model for the feed. It gets 0 to `adsCount` ads; after a failure
     or an empty result the next appearance of the screen loads again:

     ```swift
     @MainActor
     final class FeedAdsModel: ObservableObject {
         private static let adUnitID = "demo-native-bulk-yandex"
         @Published private(set) var adStates: [NativeAdState] = []
         private let loader = NativeBulkAdLoader()
         private var isLoadingNativeAds = false

         func loadAdsIfNeeded() async {
             guard adStates.isEmpty, !isLoadingNativeAds else { return }
             isLoadingNativeAds = true
             await AdsStartup.waitUntilReady()
             do {
                 let ads = try await loader.loadAds(with: AdRequest(adUnitID: Self.adUnitID), adsCount: 3)
                 adStates = ads.map { NativeAdState(ad: $0) }
             } catch {
                 print("Native ads failed to load: \(error)")
             }
             isLoadingNativeAds = false
         }
     }
     ```

   - [ ] If the project has `AdsStartup` (from get-started), keep
     `await AdsStartup.waitUntilReady()` before the first load; otherwise
     drop that line.
   - [ ] One ad on a screen: a `@StateObject` `NativeAdState(request:)` with
     `demo-native-app-yandex`, rendered as in step 4, `loadAd()` in `.onAppear`.

4. **Bind the loaded ad to the layout and handle a binding failure**

   - [ ] Insert an ad row only for the ads that came back; hide a row whose
     binding fails:

     ```swift
     struct FeedView: View {
         private static let adInterval = 8
         let items: [String]
         @StateObject private var adsModel = FeedAdsModel()

         var body: some View {
             List {
                 ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                     Text(item)
                     if let adState = adState(afterItemAt: index) {
                         NativeAdRow(state: adState)
                     }
                 }
             }
             .task { await adsModel.loadAdsIfNeeded() }
         }
         private func adState(afterItemAt index: Int) -> NativeAdState? {
             guard (index + 1) % Self.adInterval == 0 else { return nil }
             let adIndex = (index + 1) / Self.adInterval - 1
             return adIndex < adsModel.adStates.count ? adsModel.adStates[adIndex] : nil
         }
     }
     struct NativeAdRow: View {
         @ObservedObject var state: NativeAdState
         @State private var isBindingFailed = false

         var body: some View {
             if !isBindingFailed {
                 NativeAdContainer(state: state) { NativeAdCard(layout: $0) } placeholder: { EmptyView() }
                 .onAdBindingFailure { error in
                     print("Native ad binding failed: \(error)")
                     isBindingFailed = true
                 }
             }
         }
     }
     ```

5. **Register for ad events**

   - [ ] Add `.onAdClick { }` and `.onAdImpression { _ in }` to the container
     in `NativeAdRow` if the app needs them, for example for analytics.

## Verify the build

- [ ] Build the app scheme for a simulator as in the get-started guide
  (`xcodebuild ... -destination 'generic/platform=iOS Simulator' build`) or ask
  the user to build in Xcode; fix compile errors related to the Yandex SDK.

### Links

- https://ads.yandex.com/helpcenter/en/dev/ios/native.md
- https://ads.yandex.com/helpcenter/en/dev/ios/components.md
- https://ads.yandex.com/helpcenter/en/dev/ios/demo-blocks.md
