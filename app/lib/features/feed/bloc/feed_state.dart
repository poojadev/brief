part of 'feed_bloc.dart';

enum FeedStatus { initial, loading, loaded, failure }

final class FeedState extends Equatable {
  const FeedState({
    this.status = FeedStatus.initial,
    this.category = 'top',
    this.stories = const [],
    this.refreshing = false,
    this.newCount = 0,
    this.error,
  });

  final FeedStatus status;
  final String category;
  final List<Story> stories;

  /// A pull-to-refresh is in flight (the stories stay on screen).
  final bool refreshing;

  /// How many stories the last refresh added at the top.
  final int newCount;
  final String? error;

  /// True once a load or refresh has finished (successfully or not).
  bool get settled =>
      !refreshing &&
      (status == FeedStatus.loaded || status == FeedStatus.failure);

  FeedState copyWith({
    FeedStatus? status,
    bool? refreshing,
    int? newCount,
    String? error,
  }) => FeedState(
    status: status ?? this.status,
    category: category,
    stories: stories,
    refreshing: refreshing ?? this.refreshing,
    newCount: newCount ?? this.newCount,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => [
    status,
    category,
    stories,
    refreshing,
    newCount,
    error,
  ];
}
