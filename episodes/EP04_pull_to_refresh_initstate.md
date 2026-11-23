# Episode 4: "Pull-to-refresh + initState: the duplicate fetch in almost every app"

**Length:** ~2:00 · **Format:** 16:9, editor font 20pt+, app on the right, code on the left
**Repo:** `poojadev/brief`, branch `main`. Tap the **Lab** pill in the top-right to switch the
feed between **With bug** (`feed_bug.dart`) and **With fix** (`feed_fix.dart`).

---

## 1. Understand it first (read this before recording)

**The app:** Brief, a calm news reader. The Today screen loads `GET /feed`, and you can pull
to refresh. The server answers after 700 ms (on purpose), and every page-1 request
"publishes" 1–3 new stories, so a refresh visibly brings fresh content.

**Bug 1: two loads every time the screen opens.** It's two reasonable ideas combined:

```dart
@override
void initState() {
  super.initState();
  // 1. Load on open: request #1.
  _bloc = FeedBloc(getIt<FeedRepository>())..add(const FeedStarted());
  // 2. ...and also show the spinner on open. But show() runs onRefresh
  //    too: request #2, for the same feed, while #1 is still loading.
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => _refreshKey.currentState?.show(),
  );
}
```

`RefreshIndicator.show()` doesn't just *draw* the spinner. It runs the same `onRefresh`
callback a pull would. So "load in initState" plus "show the spinner on open" is two loads.

**Bug 2: the spinner that lies.**

```dart
// 3. Returns at once, before the data arrives: the spinner vanishes
//    early, users pull again, and every pull is another request.
onRefresh: () async => _bloc.add(const FeedRefreshed()),
```

`RefreshIndicator` keeps spinning until the `Future` from `onRefresh` completes.
`bloc.add()` returns immediately, so this `Future` completes immediately. The spinner
disappears long before the 700 ms response. Users think nothing happened, so they pull
again, and each pull is another request. With concurrent handlers, the responses can even
arrive out of order (try `--jitter-ms 600`).

**The fix (`feed_fix.dart`):** three small changes, same file shape.

```dart
@override
void initState() {
  super.initState();
  // 1. Load once, when the bloc is created: the ONE trigger on open.
  //    (droppable() ignores extra refreshes while one is running.)
  _bloc = FeedBloc(getIt<FeedRepository>(), dropDuplicateRefreshes: true)
    ..add(const FeedStarted());
  // 2. No show() on open: the skeleton already says "loading".
}

// 3. Completes only when the load has finished, so the spinner
//    stays up exactly as long as the request does.
onRefresh: () async {
  final done = _bloc.stream.firstWhere((s) => s.settled);
  _bloc.add(const FeedRefreshed());
  await done;
},
```

And in the bloc, the refresh handler uses `droppable()` from `bloc_concurrency`:

```dart
on<FeedRefreshed>(
  _onRefreshed,
  transformer: dropDuplicateRefreshes ? droppable() : null,
);
```

**How we measure it:**
- The **debug strip** at the bottom (Lab → "Show debug strip") shows
  **`requests: N · redundant: M`** for `GET /feed`, from waste_lens_dio's
  `RedundantCallInterceptor`. It updates after each frame, never during a build, and resets
  when you switch modes.
- The **server log** is the independent check: every `/feed` request, a `<-- x2 in 2s` flag
  when the same URL arrives twice within 2 seconds, and a completion line
  (`[#11] 200 after 700ms  +1 new`) so you can see requests overlapping.

**One honest note about "redundant":** waste_lens_dio flags a request only if an identical
one has already **finished** within the last 2 seconds (we found this in Episode 3). So:
- The two requests on open overlap, and the interceptor **can't** flag them. The server log does.
- A deliberate pull that starts within 2 s of the previous load finishing **is** flagged,
  even in the fixed app. The interceptor can't tell a duplicate from a user who really wants
  fresh news.

---

## 2. Measured numbers (iPhone 17 Pro Simulator, debug, server defaults: 700 ms latency)

Each mode: open the feed once, then pull to refresh 3 times as fast as possible (each pull
started about 0.5 s after the previous swipe ended).

| | With bug | With fix |
|---|---|---|
| `/feed` requests on open | **2** | **1** |
| Requests from 3 fast pulls | **3** (every pull got through) | **2** (one pull refused: the spinner was still up) |
| **Total `/feed` requests** | **5** | **3** |
| Server log `<-- x2 in 2s` | **3** | **0** |
| Debug strip | `requests: 5 · redundant: 2` | `requests: 3 · redundant: 1` |
| Spinner vs data | Spinner gone ~instantly, data 700 ms later | Spinner stays until the data is on screen |

Server log, **With bug**:

```
[#10] GET /feed?category=top&page=1
[#11] GET /feed?category=top&page=1   <-- x2 in 2s     ← show() on open, while #10 is in flight
       [#10] 200 after 700ms  +1 new
       [#11] 200 after 700ms  +1 new
[#12] GET /feed?category=top&page=1                    ← pull 1
       [#12] 200 after 700ms  +1 new
[#13] GET /feed?category=top&page=1   <-- x2 in 2s     ← pull 2
       [#13] 200 after 700ms  +1 new
[#14] GET /feed?category=top&page=1   <-- x2 in 2s     ← pull 3
       [#14] 200 after 700ms  +3 new
```

Server log, **With fix**:

```
[#15] GET /feed?category=top&page=1                    ← open: one request
       [#15] 200 after 700ms  +3 new
[#16] GET /feed?category=top&page=1                    ← pull 1 (pull 2 refused: still refreshing)
       [#16] 200 after 700ms  +3 new
[#17] GET /feed?category=top&page=1                    ← pull 3, after #16 had finished
       [#17] 200 after 700ms  +2 new
```

How to read them:
- **The open:** the bug sends two requests within the same moment. The second arrives
  while the first is still being served.
- **The pulls:** with the bug, the spinner vanishes immediately, so every pull fires
  another request. With the fix, the spinner stays up until the data lands, so a pull
  during a refresh does nothing. Each request that did go out returned genuinely new stories.
- **The fix's `redundant: 1`** is #16: a real pull that started within 2 s of #15 finishing.
  It's the interceptor's time-window rule, not a duplicate.

---

## 3. The fix, and what each part does

| Part | What it fixes | Is it enough on its own? |
|---|---|---|
| **One trigger on open** (load in the bloc, no `show()`) | The 2 requests on every open | Yes, for the open. Doesn't touch pulls. |
| **`onRefresh` returns a real Future** (`await stream.firstWhere(settled)`) | The spinner that lies. Users can't pull again until the data is on screen | Yes, for pulls from the UI. This is the main fix. |
| **`droppable()` on the refresh event** | Extra refresh events while one is running (code paths outside the indicator: a button, a timer, a test) | **No.** A safety net. With the lying `onRefresh`, pulls arrive after the spinner is gone; droppable only drops what overlaps. |

---

## 4. Questions viewers (and interviewers) will ask

**"Why not just disable the indicator while loading?"**
You'd be re-implementing what `RefreshIndicator` already does. It refuses new pulls while
its Future is pending. The bug isn't that the indicator allows pulls; it's that we told it
the refresh was done after 0 ms. Return a Future that completes when the data does, and the
indicator handles the rest.

**"Isn't droppable enough on its own?"**
No. `droppable()` drops events that arrive *while a handler is still running*. With the
lying `onRefresh`, the spinner is gone, the user waits a moment and pulls again, and if the
previous load has finished by then, nothing is dropped. It also does nothing about the
`show()`-on-open duplicate, which comes from a different event. Keep it as a safety net.

**"What about FutureBuilder?"**
Same trap, different shape. `FutureBuilder(future: repo.load())` in `build()` starts a new
request on every rebuild, and `RefreshIndicator(onRefresh: () async => setState(...))` lies
the same way. If you use `FutureBuilder`, create the Future once, keep it in state, and return
that same Future from `onRefresh`.

---

## 5. Recording checklist

1. Override the simulator status bar:
   `xcrun simctl status_bar booted override --time "10:30" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3`
2. `cd server && dart run bin/server.dart`. Keep the terminal visible: its log is the hook.
   Optional: `--jitter-ms 600` to show responses arriving out of order.
3. `cd app && flutter run` (**debug mode**: waste_lens is off in release)
4. The app opens in **With bug**. Point at the server log: two requests on open, the second
   flagged `<-- x2 in 2s`. A "new stories" pill even appears on open, brought by the duplicate.
5. Pull to refresh 3 times quickly: the spinner vanishes at once, every pull is a request.
6. Lab → **With fix**. One request on open. Pull 3 times quickly: the spinner stays until the
   data arrives, and pulls during it do nothing.
7. Read the debug strip on camera: `requests: 5 · redundant: 2` vs `requests: 3 · redundant: 1`.
8. When you're done: `xcrun simctl status_bar booted clear`

---

## 6. Script (~2:00)

| Time | Beat | Screen | Voiceover |
|---|---|---|---|
| 0:00 | **Hook** | Server log: two `GET /feed` on one open | "I open my news app once. My server gets the same request twice. And when I pull to refresh, it gets worse." |
| 0:10 | **The open** | `feed_bug.dart`: initState load + `show()` | "I load the feed in initState. And to show a spinner on open, I call show() on the refresh indicator. But show() doesn't just draw the spinner. It runs onRefresh. That's a second load." |
| 0:30 | **The lie** | `onRefresh: () async => bloc.add(...)`; app: spinner gone instantly | "And look at onRefresh. bloc.add returns immediately, so the spinner vanishes before the data arrives. I think nothing happened, so I pull again. And again." |
| 0:50 | **The numbers** | Debug strip `requests: 5`, server log `x2` ×3 | "One open, three pulls: five requests. Three flagged by the server as duplicates." |
| 1:05 | **The fix** | `feed_fix.dart` side by side | "The fix is three small changes. Load once, when the bloc is created. Don't call show() on open, the skeleton already says loading. And make onRefresh wait: it completes only when the data has arrived." |
| 1:25 | **Safety net** | `droppable()` in the bloc | "Then droppable, from bloc_concurrency: if another refresh arrives while one is running, it's dropped. A safety net, not the fix." |
| 1:35 | **After** | Lab → With fix; pull fast; spinner holds | "Same test. One request on open. And now the spinner stays until the stories are on screen, so the extra pull does nothing. Three requests, zero duplicates." |
| 1:50 | **Rule + teaser** | Outro card | "One trigger on open, and an onRefresh that tells the truth. Next time: the stream you forgot to cancel." |

**Title options:** "Pull-to-refresh + initState: the duplicate fetch in almost every app" ·
"Your pull-to-refresh is lying to your users"

**Description links:** pub.dev/packages/waste_lens · pub.dev/packages/waste_lens_dio ·
github.com/poojadev/brief

---

## 7. Notes
- waste_lens **0.2.0** with the overlay on. The main measurement here is requests, not rebuilds.
- `FeedCallStats` (`lib/app/feed_call_stats.dart`) wraps the `RedundantCallInterceptor` and
  counts only `GET /feed`. Image requests aren't counted (and are quiet in the server log;
  add `--log-images` to see them).
- The Lab mode lives in memory and resets to **With bug** on every app start.
