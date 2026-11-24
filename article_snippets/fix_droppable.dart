// Safety net: droppable() ignores FeedRefreshed events while a refresh is already running.
import 'package:bloc_concurrency/bloc_concurrency.dart';

// In FeedBloc's constructor:
if (dropDuplicateRefreshes) {
  // With fix: while a refresh is running, drop any more FeedRefreshed.
  on<FeedRefreshed>(_onRefreshed, transformer: droppable());
} else {
  // With bug: Bloc's default, every refresh runs, concurrently.
  on<FeedRefreshed>(_onRefreshed);
}
