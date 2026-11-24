// Fix: one trigger on open. The bloc loads once when it's created, and there's no show().
@override
void initState() {
  super.initState();
  // 1. Load once, when the bloc is created: the ONE trigger on open.
  //    (droppable() in FeedBloc drops extra refreshes while one runs.)
  _bloc = FeedBloc(getIt<FeedRepository>(), dropDuplicateRefreshes: true)
    ..add(const FeedStarted());
  // 2. No show() on open: the skeleton already says "loading".
}
