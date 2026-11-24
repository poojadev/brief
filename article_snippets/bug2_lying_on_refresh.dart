// Bug 2: onRefresh completes at once, so the spinner vanishes before the data arrives.
FeedView(
  refreshKey: _refreshKey,
  // 3. Returns at once, before the data arrives: the spinner vanishes
  //    early, users pull again, and every pull is another request.
  onRefresh: () async => _bloc.add(const FeedRefreshed()),
)
