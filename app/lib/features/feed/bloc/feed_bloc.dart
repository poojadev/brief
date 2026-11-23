import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../../data/models/story.dart';
import '../../../data/repository/feed_repository.dart';

part 'feed_event.dart';
part 'feed_state.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  /// [dropDuplicateRefreshes]: the "With fix" safety net. While a refresh is
  /// running, further FeedRefreshed events are dropped (droppable()). Without
  /// it, every refresh runs, concurrently (Bloc's default).
  FeedBloc(this._repo, {bool dropDuplicateRefreshes = false})
    : super(const FeedState()) {
    on<FeedStarted>(_onStarted);
    on<FeedCategorySelected>(_onCategorySelected);
    on<FeedRefreshed>(
      _onRefreshed,
      transformer: dropDuplicateRefreshes ? droppable() : null,
    );
    on<FeedNewStoriesSeen>((_, emit) => emit(state.copyWith(newCount: 0)));
  }

  final FeedRepository _repo;

  Future<void> _onStarted(FeedStarted event, Emitter<FeedState> emit) =>
      _load(state.category, emit);

  Future<void> _onCategorySelected(
    FeedCategorySelected event,
    Emitter<FeedState> emit,
  ) => _load(event.category, emit);

  /// A full load: skeleton first, then the stories.
  Future<void> _load(String category, Emitter<FeedState> emit) async {
    emit(FeedState(status: FeedStatus.loading, category: category));
    try {
      final stories = await _repo.load(category);
      emit(
        FeedState(
          status: FeedStatus.loaded,
          category: category,
          stories: stories,
        ),
      );
    } catch (e) {
      emit(
        FeedState(status: FeedStatus.failure, category: category, error: '$e'),
      );
    }
  }

  /// Pull-to-refresh: keep showing the current stories, then put whatever is
  /// new at the top and count it for the "N new stories" pill.
  Future<void> _onRefreshed(
    FeedRefreshed event,
    Emitter<FeedState> emit,
  ) async {
    final before = state;
    emit(state.copyWith(refreshing: true));
    try {
      final stories = await _repo.load(before.category);
      final known = {for (final s in state.stories) s.id};
      final fresh = known.isEmpty
          ? 0
          : stories.takeWhile((s) => !known.contains(s.id)).length;
      emit(
        FeedState(
          status: FeedStatus.loaded,
          category: before.category,
          stories: stories,
          newCount: fresh,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: state.stories.isEmpty
              ? FeedStatus.failure
              : FeedStatus.loaded,
          refreshing: false,
          error: '$e',
        ),
      );
    }
  }
}
