import 'package:material_ui/material_ui.dart';

import '../../../app/di.dart';
import '../../../data/api/live_readers.dart';
import '../../../data/models/story.dart';
import '../story_page.dart';
import '../widgets/reading_now_badge.dart';

/// EPISODE 5, THE BUG: a live stream that nobody ever cancels.
class StoryLiveBug extends StatefulWidget {
  const StoryLiveBug({super.key, required this.story});

  final Story story;

  @override
  State<StoryLiveBug> createState() => _StoryLiveBugState();
}

class _StoryLiveBugState extends State<StoryLiveBug> {
  int? _readers;

  @override
  void initState() {
    super.initState();
    // 1. Subscribe on open: this opens a live socket for the story.
    //    BUG: the StreamSubscription is thrown away, so nothing can cancel it.
    getIt<LiveReaders>().watch(widget.story.id).listen((readers) {
      // 2. BUG: no mounted check. After the page closes this still runs,
      //    every second: "setState() called after dispose()".
      setState(() => _readers = readers);
    });
  }

  // 3. BUG: no dispose(). Closing the page leaves the socket open, and the
  //    subscription keeps this State (and its page) alive.

  @override
  Widget build(BuildContext context) {
    return StoryPage(
      story: widget.story,
      readingNow: ReadingNowBadge(readers: _readers),
    );
  }
}
