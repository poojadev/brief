import 'dart:async';

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
    //    (droppable() in FeedBloc drops extra refreshes while one runs.)
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
          // settled = loaded OR failed, so errors stop the spinner too.
          final done = _bloc.stream.firstWhere((s) => s.settled);
          // Already loading (e.g. the first load)? Wait for it instead.
          if (_bloc.state.settled) _bloc.add(const FeedRefreshed());
          try {
            await done.timeout(const Duration(seconds: 15));
          } on TimeoutException {
            // Never spin forever: stop the spinner, the load may still land.
          }
        },
      ),
    );
  }
}
