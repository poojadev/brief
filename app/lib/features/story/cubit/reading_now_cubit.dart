import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../data/api/live_readers.dart';

/// The ONE owner of a story's live "reading now" subscription.
/// State: the latest readers count, or null while unknown (badge hidden).
class ReadingNowCubit extends Cubit<int?> {
  ReadingNowCubit(LiveReaders live, String storyId) : super(null) {
    // Subscribes when created...
    _sub = live
        .watch(storyId)
        .listen(
          emit,
          onDone: () => emit(null), // socket gone: hide the badge quietly
        );
  }

  late final StreamSubscription<int> _sub;

  /// ...and cancels in close(). BlocProvider calls close() for you when the
  /// page goes away.
  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
