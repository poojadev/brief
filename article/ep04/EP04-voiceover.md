# EP04 voiceover: "Pull-to-refresh + initState: the duplicate fetch in almost every app"

Timed to `brief-ep04-live-coding.mp4` (2:34). The video already has this voiceover, synthesised
with the macOS voice **Samantha** at a slightly relaxed pace. To record your own voice, read each line at
its start time; every line fits its section with room to breathe.

---

**0:00 · Title** (6.0 s)
> Episode four. Pull to refresh, init state, and the duplicate fetch hiding in almost every app.

**0:08 · The hook** (7.0 s)
> I open my news app once. And my server gets the same request twice. Look. Times two, in two seconds.

**0:22 · Cause 1: two triggers on open** (14.3 s)
> Here's why. I load the feed in init state. Then, to show a spinner on open, I call show, on the refresh indicator. But show doesn't just draw the spinner. It runs on refresh. That's a second load, while the first one is still in flight.

**0:40 · Cause 2: the spinner that lies** (9.1 s)
> Now look at on refresh. Bloc dot add returns immediately. So the future completes right away, and the spinner vanishes, long before the data arrives.

**0:52 · Impatient users** (8.7 s)
> So I think nothing happened, and I pull again. And again. Every pull is another request. One open, three pulls, five requests.

**1:09 · Fix 1: one trigger, droppable()** (6.1 s)
> The fix is three small changes. One. Tell the bloc to drop duplicate refreshes, with droppable.

**1:28 · Fix 2: no show()** (3.8 s)
> Two. Delete the show call. The skeleton already says loading.

**1:32 · Fix 3: a real Future** (4.4 s)
> Three. Make on refresh wait. It completes only when the data has arrived.

**1:45 · Save and hot restart** (3.7 s)
> Save, and hot restart, because init state has to run again.

**1:54 · The proof** (7.9 s)
> One request on open. Now when I pull, the spinner stays, until the stories are on screen. And a pull during a refresh does nothing.

**2:12 · The numbers** (5.3 s)
> Same test. Five requests became three. And the server flagged zero duplicates.

**2:24 · Outro** (6.3 s)
> One trigger on open, and an on refresh that tells the truth. Next time: the stream you forgot to cancel.

---

## Recording tips
- At 1:08 the fix is typed in three steps. Each line starts as its step begins, so pause between them.
- "Save, and hot restart" lands just before the app restarts on screen at 1:50.
- At 1:54 wait for the pull (about 1:57) before saying "the spinner stays".
- The narration spells words the way they should be said ("init state", "on refresh", "bloc dot add"), so a speech engine pronounces them well. Read them naturally.
