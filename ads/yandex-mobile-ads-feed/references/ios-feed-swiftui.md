# Feed Ad with SwiftUI

Follow [iOS API selection](../SKILL.md#ios-api-selection). Use the SDK's
SwiftUI state and views when they fit the screen; loading remains
event-driven, regardless of how the app waits for SDK/ATT readiness.

## Dependencies and ownership

Link `YandexMobileAdsFeed` alongside `YandexMobileAds`, using the same
dependency manager and a compatible released version. SwiftUI Feed requires
Feed 8.4.0+; Feed 8.5+ requires iOS 15+. Confirm `FeedAdState`, `FeedAdView`
and `FeedAdEvent` in the installed module. For an older installation,
upgrade compatibly or use the [UIKit adapter](ios-feed.md) through the
project's UIKit bridge.

`FeedAdState` owns loading and publishes:

- `views: [FeedAdView]`: read-only SDK-rendered views with stable identities.
- `isLoadingNextAd: Bool`: whether another item is loading.
- Events through its initializer's `onEvent` closure:
  `.didLoad`, `.didFailToLoad(Error)`, `.didClick`,
  `.didTrackImpression(ImpressionData?)`.

Keep one state object per placement, above the individual rows. Show each
provided `FeedAdView` once; do not extract its assets, regenerate row IDs or
share one state between visible screens.

## Screen integration

Mount this view only after the existing SDK/privacy readiness gate. Its
parent provides a positive measured card width in points, after safe-area
and horizontal padding, and a stable identity for that width and ad unit.
The generic `content` closure supplies existing content before the ad feed;
use `EmptyView()` for a standalone ad feed.

```swift
import SwiftUI
import YandexMobileAds
import YandexMobileAdsFeed

@MainActor
struct FeedScreen<Content: View>: View {
    @StateObject private var feed: FeedAdState
    @State private var didStart = false
    private let content: Content

    init(
        cardWidth: CGFloat,
        adUnitID: String = "demo-feed-yandex",
        onEvent: @escaping (FeedAdEvent) -> Void,
        @ViewBuilder content: () -> Content
    ) {
        _feed = StateObject(wrappedValue: FeedAdState(
            requestConfiguration: AdRequest(adUnitID: adUnitID),
            appearance: FeedAdAppearance(cardWidth: cardWidth, cardCornerRadius: 16),
            onEvent: onEvent
        ))
        self.content = content()
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                content
                ForEach(feed.views) { adView in
                    adView
                }
                if feed.isLoadingNextAd {
                    ProgressView()
                }
            }
        }
        .onAppear {
            guard !didStart else { return }
            didStart = true
            feed.loadAd()
        }
    }
}
```

`loadAd()` starts the first item. Further loading is automatic when the
last card becomes fully visible; do not call it from every row's
`onAppear` or add a second infinite-scroll loader.

For an existing `ScrollView`/`LazyVStack`, keep that scroll container and
append `ForEach(feed.views)` within it rather than nesting the whole
`FeedScreen` inside another vertical scroll view. Keep the state owner and
one-time initial-load guard at screen scope.

## Changes and failures

- `@StateObject` initialization is tied to view identity. Changing an
  initializer argument alone does not update the feed's appearance/request.
  Recreate the owner deliberately when measured width or ad unit changes
  (for example with a stable `.id` based on both); do not key it with a
  fresh UUID on every render.
- Forward `FeedAdEvent` to the app's current analytics/error handling.
  The event closure is retained with the state; avoid capturing an owning
  reference object strongly in a cycle or assuming a changed closure is
  installed on every view update.
- Keep loaded views on a failure. An error callback should not start another
  load. An explicit retry may call `loadAd()` later; a new screen owner may
  start a new feed. The `didStart` guard prevents automatic retry on every
  appearance.
- Let the screen release its state when permanently removed. There is no
  extra public Feed cancellation/disposal API.

## Verify

Build the app target, then check first load, automatic next load, appended
content, clicks/impressions, an error, navigation away/back and width changes
with `demo-feed-yandex`. Confirm that body recomputation does not issue
another initial request. Report build and runtime results separately.

## Sources

- [Feed integration](https://ads.yandex.com/helpcenter/en/dev/ios/feed-ad)
- [Public SDK, package products and changelogs](https://github.com/yandexmobile/yandex-ads-sdk-ios)
