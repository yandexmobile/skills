# General Rules

> **Every step file MUST reference this document at the top.**
> Read and internalize these rules before executing any step.

## 1. Do NOT Invent API Names

Never guess or fabricate class names, method signatures, or property names that are not explicitly listed in the step files. If a pattern is not covered — ask the user.

## 2. Do NOT Modify `import YandexMobileAds`

The module name remains `YandexMobileAds`. Only the **Yandex** entry point `MobileAds` (unqualified or from `YandexMobileAds`) is renamed to `YandexAds`. Never change import statements.

**Third-party SDKs**: Other modules may expose their own `MobileAds` type (e.g. `GoogleMobileAds.MobileAds`). The mechanical script **must not** rewrite those — only **unqualified** `MobileAds.` (not preceded by `.`). If another framework uses a delegate name that substring-matches a removed Yandex loader delegate, extend `run_final_verification.sh` with an extra `grep -v` for that framework’s module prefix.

## 3. Preserve Existing Logic

Use code examples in step files as **reference patterns only**. Adapt them to the actual logic, context, and environment of the code being changed. Do not blindly copy-paste examples.

## 4. Name Conflicts

If a rename introduces a name conflict with a project-local type, resolve it by using the fully qualified module name: `YandexMobileAds.TypeName`.

## 5. Objective-C translation

If processed files are Objective-C (`.m`, `.h`) or mixed files, warn the user that this guide is Swift-only and apply these translation rules:

Objective-C classes use the `YMA` prefix. Always check the actual prefix for each class:
- Swift `YandexAds` → ObjC `YMAYandexAds`
- Swift `AdRequest` → ObjC `YMAAdRequest`
- Swift `BannerAdView` → ObjC `YMABannerAdView`

**CRITICAL**: Objective-C selectors often differ from Swift method names. The Swift-to-ObjC name mapping is not always predictable. **Always verify the actual selector** in the SDK's Objective-C header files (`<YandexMobileAds/*.h>`) or generated Swift interface before applying changes. Do not assume a 1:1 name translation.

`async/await` is not available in Objective-C. Always use the completion handler (block) variant.

Swift enum cases use dot syntax; ObjC uses class methods or constants:
- Swift `Gender.male` → ObjC `[YMAGender male]`


Swift closures translate to Objective-C blocks:
- Swift `{ [weak self] result in ... }` → ObjC `^(YMAResult *result) { ... }`

## 6. Context Management

1. Read only the **current step file**. Do not load all steps at once.
2. Focus on files identified in Step 1. Read applicable project instructions
   and nearby code as needed to select the API style; keep edits within the
   migration scope.
3. If you have processed more than 3 project files since last reading the step file — re-read it to prevent drift.
4. You can unload already completed step docs if facing context window shortage.

## 7. Execution Discipline

1. **Do NOT skip any step.**
2. **Do NOT change the order of steps.**
3. **Do NOT stop mid-migration** — proceed to the end.
4. **Do NOT generate `.md` log files** unless explicitly asked.
5. **Never partially apply a step** — if a step has multiple changes, apply ALL of them to each file.
6. If uncertain about a specific change — ask the user before proceeding.

## 9. Choosing Between Completion Handler And Async/Await

Choose the style during discovery, before applying API replacements:

1. Read applicable `AGENTS.md`, `CLAUDE.md` and scoped project rules.
   Respect the user's stated preference; explicit project rules take
   priority over nearby code and the examples in this guide.
2. Inspect the affected screen, view model or service and similar operations
   nearby, including task ownership, cancellation and actor isolation.
3. Preserve the existing approach unless rules or the user require a change:
   use async/await in an async-oriented integration, completion handlers in
   a callback-oriented one, and blocks for Objective-C. Removed SDK 7 loader
   delegates alone do not decide the replacement; inspect surrounding code.
4. If rules and nearby code leave the choice unclear (mixed styles or no
   established convention), explain the tradeoff, recommend an approach and
   ask one focused question before rewriting the calls. Do not ask again if
   the user already chose.

Apply this decision to initialization, ad loading and image loading. The
examples show both API forms without prescribing a default. A synchronous
entry point may create `Task` when it fits the selected architecture;
define its owner and cancellation/lifetime. Preserve error handling and
main-actor UI updates. Keep existing async/completion bridges at module
boundaries; consistency does not require rewriting every call in a file.
Existing SDK SwiftUI views/modifiers can remain when they fit the project
and format; migration does not itself require switching to manual loaders.

## 10. Step Verification

Every step ends with a **Verification** section. You MUST run all verification checks before moving to the next step. If any check fails — fix the issue before proceeding.

## 11. Iterative Compilation
**After completing all migration steps**, you MUST perform **iterative project compilation** until all compilation errors are eliminated.
See [`final_verification.md`](final_verification.md) for the complete compilation process.
**DO NOT** mark the migration as complete until the project builds successfully without errors.
