# Yandex Mobile Ads SDK agent skills

Agent skills are self-contained instructions that help AI coding assistants
integrate the Yandex Mobile Ads SDK into a native Android or iOS app: install
the latest SDK, initialize it and add ad formats with the current API. They
work with Claude Code, Cursor, Codex and other agents supported by the
[`skills`](https://github.com/vercel-labs/skills) CLI. The skills are written
for SDK 8.x.

## Install

The CLI requires Node.js. Run in the root of your app project:

```bash
npx skills add yandexmobile/skills/ads
```

The CLI detects the agents installed on your machine and copies the skills into
their skills directories. Install a single skill with `--skill <name>`, preview
the list with `--list`, skip the prompts with `-y`.

Update the installed skills:

```bash
npx skills update
```

## Skills

| Skill | Description | Sample prompt |
| :--- | :--- | :--- |
| `yandex-mobile-ads-get-started` | Adds the latest SDK to an Android or iOS app, applies privacy settings and initializes the SDK. | *Add Yandex Mobile Ads SDK to my app* |
| `yandex-mobile-ads-banner` | Adds a sticky or inline banner, with Views, Jetpack Compose, UIKit or SwiftUI. | *Add a Yandex banner to the bottom of the main screen* |
| `yandex-mobile-ads-interstitial` | Adds an interstitial ad shown at a transition point. | *Show a Yandex interstitial after a level is completed* |
| `yandex-mobile-ads-rewarded` | Adds a rewarded ad behind a button that offers a reward. | *Give the user 50 coins for watching a Yandex rewarded ad* |
| `yandex-mobile-ads-app-open` | Adds an app open ad shown when the user returns to the app. | *Show a Yandex app open ad when the user returns to the app* |
| `yandex-mobile-ads-native` | Adds native ads rendered with the app's own views, for example in a feed. | *Insert Yandex native ads into the news feed every 10 items* |
| `yandex-mobile-ads-feed` | Adds an SDK-rendered ad feed as a standalone list or after existing content, on Android or iOS. | *Append a Yandex Feed Ad after the article list* |
| `yandex-mobile-ads-instream` | Adds video ads to a content player: Media3, automatic ad breaks or manual In-roll/Pause-roll, with Views, Compose, UIKit or SwiftUI. | *Add Yandex pre-roll and mid-roll ads to my video player* |
| `yandex-mobile-ads-android-migrate-to-8` | Migrates an Android app from SDK 7.x to 8.x. | *Migrate my project to Yandex Mobile Ads SDK 8* |
| `yandex-mobile-ads-ios-migrate-to-8` | Migrates an iOS app from SDK 7.x to 8.x. | *Migrate my project from Yandex Mobile Ads SDK 7.x to 8.x* |

## Ad unit IDs

The skills insert demo ad unit IDs, such as `demo-banner-yandex`, unless you
give your own. Create ad units in the Yandex Advertising Network interface at
[partner.yandex.com](https://partner.yandex.com) and replace the demo IDs with
them before publishing the app.

InStream uses the video resource's Page ID. Its demo Page ID is
`demo-instream-vmap-yandex`; replace it with your video resource's Page ID
before publishing. The InStream skill also checks the additional iOS
`YandexMobileAdsInstream` dependency.

## Network access

While following the skills, the agent queries Maven Central, the GitHub API,
CocoaPods and `yastatic.net` to resolve the latest SDK version and the
SKAdNetwork identifiers.

## Important notice

Review every change the agent makes. Skills make the result more accurate, but
an AI assistant can still make mistakes.

Use of the SDK is subject to the
[license agreement](https://legal.yandex.com/partner_ch/). Report problems
with the skills in the
[GitHub issues](https://github.com/yandexmobile/skills/issues)
of this repository.
