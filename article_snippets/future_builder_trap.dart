// The same trap with FutureBuilder: a new request on every rebuild, and a lying onRefresh.

// ❌ Trap: load() runs on EVERY build, and onRefresh returns before the data.
class FeedTrap extends StatefulWidget {
  const FeedTrap({super.key, required this.repo});

  final FeedRepository repo;

  @override
  State<FeedTrap> createState() => _FeedTrapState();
}

class _FeedTrapState extends State<FeedTrap> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}), // completes at once
      child: FutureBuilder<List<Story>>(
        future: widget.repo.load('top'), // a new request per rebuild
        builder: (context, snap) => StoryList(stories: snap.data ?? []),
      ),
    );
  }
}

// ✅ Fix: create the Future once, keep it in state, return it from onRefresh.
class FeedFixed extends StatefulWidget {
  const FeedFixed({super.key, required this.repo});

  final FeedRepository repo;

  @override
  State<FeedFixed> createState() => _FeedFixedState();
}

class _FeedFixedState extends State<FeedFixed> {
  late Future<List<Story>> _feed = widget.repo.load('top'); // once, on open

  Future<void> _refresh() {
    final next = widget.repo.load('top');
    setState(() => _feed = next);
    return next; // the spinner waits for this exact request
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Story>>(
        future: _feed,
        builder: (context, snap) => StoryList(stories: snap.data ?? []),
      ),
    );
  }
}
