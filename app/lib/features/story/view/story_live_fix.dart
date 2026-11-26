import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/di.dart';
import '../../../data/api/live_readers.dart';
import '../../../data/models/story.dart';
import '../cubit/reading_now_cubit.dart';
import '../story_page.dart';
import '../widgets/reading_now_badge.dart';

/// EPISODE 5, THE FIX: the stream has one owner, and the owner closes it.
class StoryLiveFix extends StatelessWidget {
  const StoryLiveFix({super.key, required this.story});

  final Story story;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // 1. Subscribe on open: the cubit opens the socket when it's created.
      // 2. No setState: the cubit emits, and only the badge listens.
      // 3. Leaving the page: BlocProvider calls close(), which cancels the
      //    subscription, which closes the socket.
      create: (_) => ReadingNowCubit(getIt<LiveReaders>(), story.id),
      child: StoryPage(
        story: story,
        readingNow: BlocBuilder<ReadingNowCubit, int?>(
          builder: (context, readers) => ReadingNowBadge(readers: readers),
        ),
      ),
    );
  }
}
