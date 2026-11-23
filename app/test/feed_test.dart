import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:brief/app/di.dart';
import 'package:brief/data/models/story.dart';
import 'package:brief/data/repository/feed_repository.dart';
import 'package:brief/features/feed/bloc/feed_bloc.dart';
import 'package:brief/features/feed/view/feed_bug.dart';
import 'package:brief/features/feed/view/feed_fix.dart';

class _MockRepo extends Mock implements FeedRepository {}

Story story(String id) => Story(
  id: id,
  title: 'Story $id',
  summary: 'Summary $id',
  body: const ['One.', 'Two.', 'Three.'],
  category: 'tech',
  source: 'The Meridian Post',
  author: 'Mara Ellison',
  publishedAt: DateTime(2026, 11, 23, 9),
  readMinutes: 3,
  imageUrl: 'http://brief.test/images/$id.jpg',
);

void main() {
  final first = [story('a'), story('b'), story('c')];
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    when(() => repo.load(any())).thenAnswer((_) async => first);
    getIt.registerSingleton<FeedRepository>(repo);
  });

  tearDown(() => getIt.reset());

  Future<void> open(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: page)));
    await tester.pumpAndSettle();
  }

  testWidgets('With bug: opening the feed loads it TWICE', (tester) async {
    await open(tester, const FeedPageBug());
    // initState load + show() -> onRefresh -> a second load.
    verify(() => repo.load('top')).called(2);
    expect(find.text('Story a'), findsOneWidget);
  });

  testWidgets('With fix: opening loads once; rapid refreshes add at most one', (
    tester,
  ) async {
    await open(tester, const FeedPageFix());
    verify(() => repo.load('top')).called(1);

    // From now on the server is slow: the refresh stays in flight.
    final slow = Completer<List<Story>>();
    when(() => repo.load(any())).thenAnswer((_) => slow.future);

    final onRefresh = tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh;
    var finished = 0;
    for (var i = 0; i < 3; i++) {
      unawaited(onRefresh().then((_) => finished++));
    }
    await tester.pump();

    // droppable(): only the first of the three reached the repository...
    verify(() => repo.load('top')).called(1);
    // ...and none of the spinners has stopped: the data isn't here yet.
    expect(finished, 0);

    slow.complete([story('new'), ...first]);
    await tester.pumpAndSettle();
    expect(finished, 3); // all three complete when the one load finishes
    expect(find.text('1 new story'), findsOneWidget);
  });

  group('FeedBloc', () {
    blocTest<FeedBloc, FeedState>(
      'initial -> loading -> loaded',
      build: () => FeedBloc(repo),
      act: (bloc) => bloc.add(const FeedStarted()),
      expect: () => [
        const FeedState(status: FeedStatus.loading),
        FeedState(status: FeedStatus.loaded, stories: first),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'refresh puts new stories at the top and counts them',
      build: () => FeedBloc(repo),
      seed: () => FeedState(status: FeedStatus.loaded, stories: first),
      setUp: () =>
          when(() => repo.load(any()))
              .thenAnswer((_) async => [story('x'), story('y'), ...first]),
      act: (bloc) => bloc.add(const FeedRefreshed()),
      expect: () => [
        FeedState(status: FeedStatus.loaded, stories: first, refreshing: true),
        FeedState(
          status: FeedStatus.loaded,
          stories: [story('x'), story('y'), ...first],
          newCount: 2,
        ),
      ],
    );
  });
}
