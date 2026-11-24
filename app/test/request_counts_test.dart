// Re-checks the article's numbers: open the feed once, then pull to refresh
// three times, against a repository that takes 700 ms like the mock server.
//
// The pulls are real drag gestures, so RefreshIndicator itself decides which
// ones it accepts (it ignores a drag until its previous refresh, including
// the short dismiss animation, has finished).
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:brief/app/di.dart';
import 'package:brief/data/models/story.dart';
import 'package:brief/data/repository/feed_repository.dart';
import 'package:brief/features/feed/view/feed_bug.dart';
import 'package:brief/features/feed/view/feed_fix.dart';

class _MockRepo extends Mock implements FeedRepository {}

const latency = Duration(milliseconds: 700);
const frame = Duration(milliseconds: 16);

Story story(String id) => Story(
  id: id,
  title: 'Story $id',
  summary: 'Summary $id',
  body: const ['One.'],
  category: 'top',
  source: 'The Meridian Post',
  author: 'Mara Ellison',
  publishedAt: DateTime(2026, 11, 23, 9),
  readMinutes: 3,
  imageUrl: 'http://brief.test/images/$id.jpg',
);

void main() {
  late _MockRepo repo;
  late int requests;

  setUp(() {
    requests = 0;
    repo = _MockRepo();
    // Like the server: 700 ms per request, one fresh story each time.
    when(() => repo.load(any())).thenAnswer((_) {
      final n = ++requests;
      return Future.delayed(latency, () => [story('s$n'), story('base')]);
    });
    getIt.registerSingleton<FeedRepository>(repo);
  });

  tearDown(() => getIt.reset());

  /// Let [time] pass frame by frame, so animations and the fake 700 ms
  /// requests advance together, like on a device.
  Future<void> frames(WidgetTester tester, Duration time) async {
    for (var t = Duration.zero; t < time; t += frame) {
      await tester.pump(frame);
    }
  }

  Future<void> open(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: page)));
    await frames(tester, const Duration(seconds: 2));
  }

  bool spinnerVisible() =>
      find.byType(RefreshProgressIndicator).evaluate().isNotEmpty;

  /// One pull-to-refresh gesture.
  Future<void> pull(WidgetTester tester) async {
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 400),
      1000,
    );
    await tester.pump();
  }

  /// Pull three times, each as soon as the indicator is idle again.
  Future<void> pullThreeTimesAsFastAsAllowed(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await pull(tester);
      while (spinnerVisible()) {
        await tester.pump(frame);
      }
    }
    await frames(tester, const Duration(seconds: 2));
  }

  /// Pull three times about a second apart, spinner or not, like the
  /// recorded demo (each drag takes ~0.4 s, then a 0.6 s pause).
  Future<void> pullThreeTimesAboutASecondApart(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await pull(tester);
      await frames(tester, const Duration(milliseconds: 600));
    }
    await frames(tester, const Duration(seconds: 2));
  }

  group('as fast as the indicator allows', () {
    testWidgets('With bug: 2 on open + 3 pulls = 5', (tester) async {
      await open(tester, const FeedPageBug());
      expect(requests, 2);
      await pullThreeTimesAsFastAsAllowed(tester);
      expect(requests, 5);
    });

    testWidgets('With fix: 1 on open + 3 pulls = 4', (tester) async {
      await open(tester, const FeedPageFix());
      expect(requests, 1);
      await pullThreeTimesAsFastAsAllowed(tester);
      expect(requests, 4);
    });
  });

  group('pulls about a second apart, spinner or not (the article run)', () {
    testWidgets('With bug: every pull is accepted = 5', (tester) async {
      await open(tester, const FeedPageBug());
      await pullThreeTimesAboutASecondApart(tester);
      expect(requests, 5);
    });

    testWidgets('With fix: the pull during the spinner is refused = 3', (
      tester,
    ) async {
      await open(tester, const FeedPageFix());
      await pullThreeTimesAboutASecondApart(tester);
      expect(requests, 3);
    });
  });

  group('With fix: a pull while the first load is still running', () {
    Future<void> pullDuringFirstLoad(WidgetTester tester, Widget page) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: page)));
      await tester.pump(frame); // skeleton on screen, first load in flight
      await pull(tester);
      await frames(tester, const Duration(seconds: 2));
    }

    testWidgets('waits for that load, no new request = 1', (tester) async {
      await pullDuringFirstLoad(tester, const FeedPageFix());
      expect(requests, 1);
      expect(spinnerVisible(), isFalse);
    });
  });

  group('With fix: the spinner always stops', () {
    testWidgets('when the request fails', (tester) async {
      await open(tester, const FeedPageFix());
      when(() => repo.load(any()))
          .thenAnswer((_) => Future.delayed(latency, () => throw 'HTTP 503'));

      await pull(tester);
      await frames(tester, const Duration(milliseconds: 600));
      expect(spinnerVisible(), isTrue); // still waiting for the data
      await frames(tester, const Duration(milliseconds: 600));
      expect(spinnerVisible(), isFalse);
      expect(find.text("Couldn't refresh. Pull to try again."), findsOneWidget);
      expect(find.text('Story s1'), findsOneWidget); // old stories stay

      await frames(tester, const Duration(seconds: 5)); // snackbar leaves
    });

    testWidgets('after 15 s, even if the request never answers', (
      tester,
    ) async {
      await open(tester, const FeedPageFix());
      when(() => repo.load(any()))
          .thenAnswer((_) => Completer<List<Story>>().future);

      final onRefresh = tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh;
      var stopped = false;
      unawaited(onRefresh().then((_) => stopped = true));

      await tester.pump(const Duration(seconds: 14));
      expect(stopped, isFalse);
      await tester.pump(const Duration(seconds: 1));
      expect(stopped, isTrue); // the TimeoutException was caught
    });
  });
}
