# Feed Ad with UIKit

## Dependencies and API choice

Follow [iOS API selection](../SKILL.md#ios-api-selection) for startup and
surrounding code. Feed loading uses delegates.

Add the `YandexMobileAdsFeed` product to the app target using the existing
Yandex SDK Swift Package dependency, or add the `YandexMobileAdsFeed` pod to
the same app target. Resolve a released version compatible with the app's
`YandexMobileAds` version; check the package/podspec rather than copying a
version number. Feed 8.5+ requires iOS 15+. Preserve the existing dependency
manager, mediation setup and privacy configuration.

Import both `YandexMobileAds` and `YandexMobileAdsFeed`. The public objects are
`FeedAd`, `FeedAdAppearance`, `FeedAdCollectionViewAdapter` and
`FeedAdDelegate`; keep strong references to the feed and adapter because the
feed delegate and collection view's data source/delegate are weak.

## Standalone feed

The example supplies the collection view and its SDK owner. Call
`startFeed(cardWidth:)` once SDK/privacy readiness has completed and layout
has produced a positive width. The caller computes card width from the
collection view's bounds minus adjusted horizontal insets and section
padding. Keep any existing screen layout instead of replacing it.

```swift
import UIKit
import YandexMobileAds
import YandexMobileAdsFeed

@MainActor
final class FeedViewController: UIViewController, FeedAdDelegate {
    private static let adUnitID = "demo-feed-yandex"
    let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    )
    private var feedAd: FeedAd?
    private var feedAdapter: FeedAdCollectionViewAdapter?

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    func startFeed(cardWidth: CGFloat) {
        guard feedAd == nil, cardWidth > 0 else { return }
        let feed = FeedAd(
            requestConfiguration: AdRequest(adUnitID: Self.adUnitID),
            appearance: FeedAdAppearance(cardWidth: cardWidth, cardCornerRadius: 16)
        )
        feed.delegate = self
        let adapter = FeedAdCollectionViewAdapter(feedAd: feed)
        adapter.registerCells(in: collectionView)
        feedAd = feed
        feedAdapter = adapter
        collectionView.dataSource = adapter.dataSource
        collectionView.delegate = adapter.delegate
        feed.loadAd()
    }

    func feedAdDidUpdateDataSource(_ feedAd: FeedAd) {
        collectionView.reloadData()
    }

    func feedAdDidLoad(_ feedAd: FeedAd) {
        // Report successful loading to the screen, if needed.
    }

    func feedAd(_ feedAd: FeedAd, didFailToLoadWithError error: Error) {
        // Log the error or update an error state; do not retry here.
    }

    func feedAdDidClick(_ feedAd: FeedAd) {
        // Forward the SDK click event to the app's analytics.
    }

    func feedAd(_ feedAd: FeedAd, didTrackImpression data: ImpressionData?) {
        // Forward impression data if needed; data may be nil.
    }

    func tearDownFeed() {
        feedAd?.delegate = nil
        collectionView.dataSource = nil
        collectionView.delegate = nil
        feedAdapter = nil
        feedAd = nil
    }
}
```

Register cells **before** assigning data source/delegate. Install the
adapter before loading so the first update reaches the collection view.
Reload from `feedAdDidUpdateDataSource`, including loading-state changes,
not just `feedAdDidLoad`. The SDK includes a loading row when needed and
automatically requests more when the last ad becomes fully visible.

## Append after existing content

Keep one collection view and add a final feed section. Keep the app as its
data source and `UICollectionViewDelegateFlowLayout`; do not replace the
content data source with the SDK adapter. Create and retain the adapter and
register its cells as above, then forward only feed-section calls:

| Collection view callback | Feed section |
| :--- | :--- |
| `numberOfItemsInSection` | `adapter.dataSource.collectionView(collectionView, numberOfItemsInSection: section)` |
| `cellForItemAt` | `adapter.dataSource.collectionView(collectionView, cellForItemAt: indexPath)` |
| `layout:sizeForItemAt` | `adapter.delegate.collectionView?(collectionView, layout: layout, sizeForItemAt: indexPath)` |

Use the **original collection-view index path** when dequeuing feed cells:
the item index is relative to the feed section, and the section is its real
section in the collection view. Do not translate it to section zero.
Preserve existing content sections, sizes, selection and scroll behavior.
If declaring a section enum with `Section.allCases`, make it `CaseIterable`.

Keep feed counts and reloads consistent when handling
`feedAdDidUpdateDataSource`. The simple path uses `reloadData()` outside
ongoing batch updates. An existing diffable data source or custom layout
needs deliberate integration with these callbacks and sizing; do not assign
two data sources or copy the standalone wiring over it.

## Lifetime, resizing and failures

- Own the feed for the screen's lifetime. Tear it down when that owner is
  discarded, not on every `viewDidDisappear` (an ad click can temporarily
  cover the screen).
- For changed available width, release the old feed/adapter and create a
  new pair with the measured width. Coordinate this with the screen's layout
  and scroll position; do not recreate on unchanged layout passes.
- Keep loaded cards after a failed next load. If offering a retry, call
  `loadAd()` only at a later intentional trigger; never inside the failure
  callback. There is no public Feed `destroy()` or `cancelLoading()` method.
- On an existing mixed-content screen, teardown should remove only the
  feed section and its owner, preserving the content data source/delegate.

## Verify

- Build the app's actual scheme/target with the resolved Feed product.
- With `demo-feed-yandex`, check first load, scrolling to later cards,
  impressions, clicks/return to the app and failure without a request loop.
- For an appended feed, check that content and feed cells keep their correct
  sizes and index paths, including the loading row.
- Check rotation/split view, leaving/reopening the screen and a failed next
  load with already visible cards. Do not claim runtime success from a build.
- For diagnostics, enable `YandexAds.enableLogging()` in a debug path and
  inspect Console subsystem `com.mobile.ads.ads.sdk`.

## Sources

- [Feed integration](https://ads.yandex.com/helpcenter/en/dev/ios/feed-ad?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-feed)
- [SDK integration](https://ads.yandex.com/helpcenter/en/dev/ios/quick-start?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-feed)
- [Public SDK and samples](https://github.com/yandexmobile/yandex-ads-sdk-ios)
