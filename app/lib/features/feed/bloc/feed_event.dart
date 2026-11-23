part of 'feed_bloc.dart';

sealed class FeedEvent extends Equatable {
  const FeedEvent();

  @override
  List<Object?> get props => [];
}

/// Load the feed (shows the skeleton).
final class FeedStarted extends FeedEvent {
  const FeedStarted();
}

/// Pull-to-refresh (keeps the current stories on screen).
final class FeedRefreshed extends FeedEvent {
  const FeedRefreshed();
}

final class FeedCategorySelected extends FeedEvent {
  const FeedCategorySelected(this.category);

  final String category;

  @override
  List<Object?> get props => [category];
}

/// The "N new stories" pill was tapped.
final class FeedNewStoriesSeen extends FeedEvent {
  const FeedNewStoriesSeen();
}
