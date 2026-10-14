# Yandex Mobile agent skills

Agent skills for Yandex mobile SDKs. A skill is a self-contained instruction
that helps an AI coding assistant, such as Claude Code, Cursor or Codex, work
with an SDK in an Android or iOS app: add it to the project, set it up and use
its current API.

Skills are grouped by product. Each directory is a separate set with its own
README:

| Directory | Product | Contents |
| :--- | :--- | :--- |
| [`ads`](./ads) | [Yandex Mobile Ads SDK](https://ads.yandex.com/mobile) | Adding the SDK and ad formats, migrating from SDK 7.x to 8.x |

## Install

Install the skills with the [`skills`](https://github.com/vercel-labs/skills)
CLI in the root of your app project. The CLI requires Node.js.

Install all skills from this repository:

```bash
npx skills add yandexmobile/skills
```

Install a single set, for example the Yandex Mobile Ads skills:

```bash
npx skills add yandexmobile/skills/ads
```

The CLI detects the agents installed on your machine, lets you select skills
and copies them into the agents' skills directories. Preview the list with
`--list`, install a single skill with `--skill <name>`. Update installed skills
with `npx skills update`.

## License

Use of each SDK is subject to its license agreement, linked from the README of
the corresponding set. See also [`LICENSE.txt`](./LICENSE.txt).
