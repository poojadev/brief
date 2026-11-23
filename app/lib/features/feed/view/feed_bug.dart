import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/di.dart';
import '../../../data/repository/feed_repository.dart';
import '../bloc/feed_bloc.dart';
import 'feed_view.dart';

/// EPISODE 4, THE BUG: two loads on open, and a refresh that lies.
class FeedPageBug extends StatefulWidget {
  const FeedPageBug({super.key});

  @override
  State<FeedPageBug> createState() => _FeedPageBugState();
}

class _FeedPageBugState extends State<FeedPageBug> {
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  late final FeedBloc _bloc;

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
        // 3. Returns at once, before the data arrives: the spinner vanishes
        //    early, users pull again, and every pull is another request.
        onRefresh: () async => _bloc.add(const FeedRefreshed()),
      ),
    );
  }
}
