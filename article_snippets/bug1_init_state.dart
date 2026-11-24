// Bug 1: initState loads the feed, and show() on the RefreshIndicator loads it again.
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
