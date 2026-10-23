# AI Integration Agent Instructions for iOS Native Ads

Apply [iOS API selection](../SKILL.md#ios-api-selection) before using
these examples. Adapt the snippets to the selected project conventions.

## Required Imports

```swift
import UIKit
import YandexMobileAds
```

## Method Signatures

```swift
NativeBulkAdLoader()
func loadAds(with request: AdRequest, adsCount: UInt, options: NativeAdOptions = .init()) async throws -> [NativeAd]
func loadAds(with request: AdRequest, adsCount: UInt, options: NativeAdOptions = .init(), completion: @escaping @MainActor (Result<[NativeAd], Error>) -> Void)
NativeAdLoader()
func loadAd(with request: AdRequest, options: NativeAdOptions = .init()) async throws -> NativeAd
func loadAd(with request: AdRequest, options: NativeAdOptions = .init(), completion: @escaping @MainActor (Result<NativeAd, Error>) -> Void)

@MainActor protocol NativeAd: NSObjectProtocol {
    var delegate: NativeAdDelegate? { get set }   // weak
    func bind(with adView: NativeAdView) throws
}
```

`NativeAdView` is an open `UIView` with one optional property per asset (all
of them are set in step 2). `NativeAdDelegate` (`@MainActor`) has two
required methods (step 5).

For a completion-based feed model, use `loadAds(with:adsCount:options:completion:)`
from the project's startup-ready callback. Move the async example's
success/error handling into the `Result` switch and clear the loading
flag on both paths. Preserve the same ad ownership and rendering.

## Gotchas

- SDK 8 has no native templates; the sample
  [`NativeAdBannerView.swift`](https://github.com/yandexmobile/yandex-ads-sdk-ios/blob/master/Examples/YandexMobileAdsExample/YandexMobileAdsExample/Common/Native/NativeAdBannerView.swift)
  is a layout to copy. The SDK fills the asset views: do not change them.
- The docs always require title, domain, warning, sponsored, feedback, call to
  action and media, plus icon and price for app install ads
  ([components](https://ads.yandex.com/helpcenter/en/dev/ios/components.md)).
- `bind(with:)` throws `NativeErrorCode.noViewForAsset` or
  `.invalidViewForBinding` (SDK 8.4.0+; on 8.0–8.3 compare
  `(error as NSError).code`). Hidden, transparent or too small asset views do
  not fail binding, but the impression is not counted. For video keep the ad
  and the media view at least 300 x 160 points.
- In Swift 6 mode a `UIView` conforming to `Rating` needs
  `@preconcurrency Rating` (in Swift 5 mode drop `@preconcurrency`).
- With ad rows in the table, map index paths through `rows` everywhere, for
  example in `didSelectRowAt`.
- Capture `self` weakly in `Task` closures. If the project does not use
  synchronized folders, add new files to the app target (see the get-started
  guide).

Names such as `FeedViewController` or `items` in the snippets are
placeholders for the app's own code.

## Native workflow

1. **Choose the placement and how many ads it needs**

   - [ ] Feed (main case): `NativeBulkAdLoader`, up to 9 ads, after every N items.

2. **Create the ad layout with a view for every asset**

   ```swift
   final class FeedNativeAdView: NativeAdView {
       override init(frame: CGRect) {
           super.init(frame: frame)
           let (title, body, domain, sponsored, warning) = (UILabel(), UILabel(), UILabel(), UILabel(), UILabel())
           let (age, price, reviewCount, rating) = (UILabel(), UILabel(), UILabel(), RatingLabel())
           let (icon, favicon, media) = (UIImageView(), UIImageView(), NativeMediaView())
           let (feedback, callToAction) = (UIButton(type: .custom), UIButton(type: .system))
           (titleLabel, bodyLabel, domainLabel, sponsoredLabel, warningLabel) = (title, body, domain, sponsored, warning)
           (ageLabel, priceLabel, reviewCountLabel, ratingView) = (age, price, reviewCount, rating)
           (iconImageView, faviconImageView, mediaView) = (icon, favicon, media)
           (feedbackButton, callToActionButton) = (feedback, callToAction)
           let stack = UIStackView(arrangedSubviews: [
               row(sponsored, age, UIView(), feedback), row(icon, title), body, media,
               row(favicon, domain), row(rating, reviewCount, price, UIView(), callToAction), warning,
           ])
           backgroundColor = .systemBackground
           stack.axis = .vertical
           stack.spacing = 8
           stack.translatesAutoresizingMaskIntoConstraints = false
           addSubview(stack)
           NSLayoutConstraint.activate([
               icon.widthAnchor.constraint(equalToConstant: 40), icon.heightAnchor.constraint(equalToConstant: 40),
               favicon.widthAnchor.constraint(equalToConstant: 14), favicon.heightAnchor.constraint(equalToConstant: 14),
               feedback.widthAnchor.constraint(equalToConstant: 30), feedback.heightAnchor.constraint(equalToConstant: 30),
               media.heightAnchor.constraint(equalTo: media.widthAnchor, multiplier: 9.0 / 16.0),
               stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
               stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
               stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
               stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
           ])
       }

       required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

       private func row(_ views: UIView...) -> UIStackView {
           let row = UIStackView(arrangedSubviews: views)
           row.spacing = 8
           row.alignment = .center
           return row
       }
   }

   final class RatingLabel: UILabel, @preconcurrency Rating {
       var rating: NSNumber? {
           didSet { text = rating.map { String(format: "%.1f", $0.doubleValue) } }
       }
   }
   ```

   - [ ] Adapt the rows to the app's design; keep the sponsored label, warning
     and feedback button visible.

3. **Create one ad loader and load the ads**

   - [ ] Add to your table view controller. The loader returns from 0 to
     `adsCount` ads: rows are built only for the ads that came back. After a
     failure or an empty result do not retry at once: the next time the
     screen is shown loads again.

     ```swift
     final class FeedViewController: UITableViewController {
         private static let nativeAdUnitID = "demo-native-bulk-yandex"
         private static let nativeAdInterval = 8
         private enum FeedRow { case item(String), ad(NativeAd) }

         private let nativeAdLoader = NativeBulkAdLoader()
         private var items: [String] = []
         private var nativeAds: [NativeAd] = []
         private var rows: [FeedRow] = []
         private var isLoadingNativeAds = false

         override func viewDidLoad() {
             super.viewDidLoad()
             tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ItemCell")
             tableView.register(NativeAdCell.self, forCellReuseIdentifier: NativeAdCell.reuseIdentifier)
             rebuildRows()
         }

         override func viewWillAppear(_ animated: Bool) {
             super.viewWillAppear(animated)
             loadNativeAdsIfNeeded()
         }

         private func loadNativeAdsIfNeeded() {
             guard nativeAds.isEmpty, !isLoadingNativeAds else { return }
             isLoadingNativeAds = true
             Task { [weak self] in
                 await AdsStartup.waitUntilReady()
                 guard let self else { return }
                 do {
                     nativeAds = try await nativeAdLoader.loadAds(with: AdRequest(adUnitID: Self.nativeAdUnitID), adsCount: 3)
                     nativeAds.forEach { $0.delegate = self }
                     rebuildRows()
                     tableView.reloadData()
                 } catch {
                     print("Native ads failed to load: \(error)")
                 }
                 isLoadingNativeAds = false
             }
         }

         private func rebuildRows() {
             var remainingAds = nativeAds.makeIterator()
             rows = items.enumerated().flatMap { index, item -> [FeedRow] in
                 guard (index + 1) % Self.nativeAdInterval == 0, let ad = remainingAds.next() else { return [.item(item)] }
                 return [.item(item), .ad(ad)]
             }
         }

         private func removeNativeAd(_ ad: NativeAd) {
             nativeAds.removeAll { $0 === ad }
             rebuildRows()
             tableView.reloadData()
         }
     }
     ```

   - [ ] Gate the first load on the project's startup/ATT readiness flow.
     The async example uses `await AdsStartup.waitUntilReady()` from
     get-started; a completion-based flow starts the load from its
     readiness callback. Omit this gate only if readiness is already
     handled elsewhere or no gate is needed.
   - [ ] One ad on a screen: a `NativeAdLoader` and a hidden `FeedNativeAdView`;
     in `viewWillAppear`, if no ad is loaded or loading, call
     `loadAd(with: AdRequest(adUnitID: "demo-native-app-yandex"))` and bind as in step 4.

4. **Bind the loaded ad to the layout and handle a binding failure**

   - [ ] One ad per row, bound in `cellForRowAt` to the cell's own view. On a
     binding error remove the ad:

     ```swift
     final class NativeAdCell: UITableViewCell {
         static let reuseIdentifier = "NativeAdCell"
         let adView = FeedNativeAdView()

         override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
             super.init(style: style, reuseIdentifier: reuseIdentifier)
             selectionStyle = .none
             adView.translatesAutoresizingMaskIntoConstraints = false
             contentView.addSubview(adView)
             NSLayoutConstraint.activate([
                 adView.topAnchor.constraint(equalTo: contentView.topAnchor),
                 adView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                 adView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                 adView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
             ])
         }

         required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
     }

     extension FeedViewController {
         override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

         override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
             switch rows[indexPath.row] {
             case .item(let title):
                 let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
                 cell.textLabel?.text = title
                 return cell
             case .ad(let ad):
                 let cell = tableView.dequeueReusableCell(withIdentifier: NativeAdCell.reuseIdentifier, for: indexPath)
                 guard let adCell = cell as? NativeAdCell else { return cell }
                 do {
                     try ad.bind(with: adCell.adView)
                 } catch {
                     print("Native ad binding failed: \(error)")
                     Task { [weak self] in self?.removeNativeAd(ad) }
                 }
                 return adCell
             }
         }
     }
     ```

5. **Register for ad events**

   ```swift
   extension FeedViewController: NativeAdDelegate {
       func nativeAdDidClick(_ ad: NativeAd) {}
       func nativeAd(_ ad: NativeAd, didTrackImpression impressionData: ImpressionData?) {}
   }
   ```

## Verify the build

- [ ] Build the app scheme for a simulator as in the get-started guide
  (`xcodebuild ... -destination 'generic/platform=iOS Simulator' build`) or ask
  the user to build in Xcode; fix compile errors related to the Yandex SDK.

### Links

- https://ads.yandex.com/helpcenter/en/dev/ios/native.md
- https://ads.yandex.com/helpcenter/en/dev/ios/components.md
- https://ads.yandex.com/helpcenter/en/dev/ios/demo-blocks.md
