import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/di.dart';
import '../../../data/repository/feed_repository.dart';
import '../bloc/feed_bloc.dart';
import 'feed_view.dart';

/// EPISODE 4, THE FIX: one load on open, and a refresh that waits.
class FeedPageFix extends StatefulWidget {
  const FeedPageFix({super.key});

  @override
  State<FeedPageFix> createState() => _FeedPageFixState();
}

class _FeedPageFixState extends State<FeedPageFix> {
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  late final FeedBloc _bloc;

  @override
  void initState() {
    super.initState();
    // 1. Load once, when the bloc is created: the ONE trigger on open.
    //    (droppable() ignores extra refreshes while one is running.)
    _bloc = FeedBloc(getIt<FeedRepository>(), dropDuplicateRefreshes: true)
      ..add(const FeedStarted());
    // 2. No show() on open: the skeleton already says "loading".
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: FeedView(
        refreshKey: _refreshKey,
        // 3. Completes only when the load has finished, so the spinner
        //    stays up exactly as long as the request does.
        onRefresh: () async {
          final done = _bloc.stream.firstWhere((s) => s.settled);
          _bloc.add(const FeedRefreshed());
          await done;
        },
      ),
    );
  }
}
