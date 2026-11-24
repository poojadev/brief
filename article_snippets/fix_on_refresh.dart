// Fix: an onRefresh that completes when the data (or an error) arrives, and never spins forever.
import 'dart:async';

FeedView(
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
)
