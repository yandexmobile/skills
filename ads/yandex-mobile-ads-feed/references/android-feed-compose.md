# Feed Ad in a Compose screen

Read [Android Views](android-feed.md) for dependencies, the `FeedSession`
helper, callbacks and lifetime rules. The Feed API uses `FeedAdAdapter` and
RecyclerView; do not assume `mobileads-compose` provides a `Feed` composable
or `rememberFeedAdState`.

Host the RecyclerView with `AndroidView`. This bridge needs no
`mobileads-compose` dependency. Use a Compose UI version that supports
`AndroidView.onRelease` (1.4+), or the project's equivalent disposal hook.
Keep the host on the main thread and show it only after SDK/privacy readiness.

## Standalone feed

The following example reuses `FeedSession` from the Views guide. It builds
the RecyclerView inside `factory`, loads once per view/configuration and
clears listeners and the adapter when the view is released.

```kotlin
import android.content.Context
import android.widget.FrameLayout
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.key
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import androidx.recyclerview.widget.RecyclerView

private class FeedHostView(
    context: Context,
    cardWidthDp: Int,
    adUnitId: String,
) : FrameLayout(context) {
    private val recyclerView = RecyclerView(context)
    private val session: FeedSession

    init {
        addView(recyclerView, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
        session = FeedSession(context, recyclerView, cardWidthDp, adUnitId)
    }

    fun release() = session.release()
}

@Composable
fun FeedScreen(
    modifier: Modifier = Modifier,
    adUnitId: String = "demo-feed-yandex",
) {
    BoxWithConstraints(modifier.fillMaxSize()) {
        // Parent applies safe insets and desired horizontal padding.
        val cardWidthDp = maxWidth.value.toInt()
        if (cardWidthDp > 0) {
            key(cardWidthDp, adUnitId) {
                AndroidView(
                    modifier = Modifier.fillMaxSize(),
                    factory = { context -> FeedHostView(context, cardWidthDp, adUnitId) },
                    onReset = null,
                    onRelease = { it.release() },
                    update = {},
                )
            }
        }
    }
}
```

Give the host a bounded viewport. Keep load calls and adapter assignment out
of `AndroidView.update`; it runs on recomposition. The stable key deliberately
recreates the session when width or ad unit changes.

## Feed after app content

Use one scrolling RecyclerView with
`ConcatAdapter(contentAdapter, feedAdapter)`, as in the Views guide, when
the screen already uses or can reasonably host RecyclerView content. Pass
that content adapter through the host's session.

Do not embed an unbounded, vertically scrolling feed RecyclerView as one
item in `LazyColumn` and disable its scrolling to measure the whole feed.
For an existing Compose-only list, evaluate the screen design before
changing its scroll architecture: use a bounded Feed region, or agree on
hosting the combined content in one RecyclerView. If the requirement is
actually individual ads between content rows, use
`yandex-mobile-ads-native` instead. Do not silently switch ad formats.

## Verify

In addition to the Views checks, exercise recomposition, navigation
disposal/recreation, resizing and scroll behavior with surrounding Compose
content. Confirm that recomposition neither preloads again nor replaces the
adapter. Build the actual app target and report device checks separately.

## Sources

- [Android Views interoperability](https://developer.android.com/develop/ui/compose/migrate/interoperability-apis/views-in-compose)
- [Feed integration](https://ads.yandex.com/helpcenter/en/dev/android/feed-ad?utm_source=agent-skills&utm_medium=content&utm_campaign=yandex-mobile-ads-skills&utm_content=yandex-mobile-ads-feed)
