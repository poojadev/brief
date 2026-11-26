// Episode 5: does closing a story stop its live stream?
//
// A fake LiveReaders hands out one StreamController's stream. After the story
// page is popped, the controller still having a listener means the
// subscription (and, in the app, its socket) is still alive.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:brief/app/di.dart';
import 'package:brief/data/api/live_readers.dart';
import 'package:brief/data/models/story.dart';
import 'package:brief/features/story/cubit/reading_now_cubit.dart';
import 'package:brief/features/story/view/story_live_bug.dart';
import 'package:brief/features/story/view/story_live_fix.dart';

class _FakeLiveReaders implements LiveReaders {
  final controller = StreamController<int>();

  @override
  Stream<int> watch(String storyId) => controller.stream;
}

final story = Story(
  id: 'b3',
  title: 'A story worth reading',
  summary: 'Summary.',
  body: const ['One.', 'Two.'],
  category: 'tech',
  source: 'The Meridian Post',
  author: 'Mara Ellison',
  publishedAt: DateTime(2026, 11, 23, 9),
  readMinutes: 3,
  imageUrl: 'http://brief.test/images/b3.jpg',
);

void main() {
  late _FakeLiveReaders live;

  setUp(() {
    live = _FakeLiveReaders();
    getIt.registerSingleton<LiveReaders>(live);
  });

  tearDown(() => getIt.reset());

  /// Opens [page] on top of a home screen, shows one reading, then goes back.
  Future<void> openAndClose(
    WidgetTester tester,
    Widget page, {
    void Function()? beforeClose,
  }) async {
    // A phone-tall screen, so the badge under the byline is on screen.
    tester.view
      ..physicalSize = const Size(400, 1000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: nav, home: const SizedBox()),
    );
    unawaited(nav.currentState!.push(MaterialPageRoute(builder: (_) => page)));
    await tester.pumpAndSettle();
    expect(live.controller.hasListener, isTrue); // subscribed on open

    live.controller.add(1204);
    await tester.pump();
    // Two frames: the badge's fade-in ticker starts counting on its first tick.
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1,204'), findsOneWidget);
    final semantics = tester.ensureSemantics();
    await tester.pump();
    expect(find.bySemanticsLabel('1,204 people reading now'), findsOneWidget);
    semantics.dispose();

    beforeClose?.call();
    nav.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // route animation
    expect(find.byWidget(page), findsNothing);
  }

  testWidgets('With bug: after closing the story, the stream still has a '
      'listener, and it calls into a disposed State', (tester) async {
    late State page;
    await openAndClose(
      tester,
      StoryLiveBug(story: story),
      beforeClose: () => page = tester.state(find.byType(StoryLiveBug)),
    );

    expect(live.controller.hasListener, isTrue); // the leak
    expect(page.mounted, isFalse); // ...and what it calls setState on
    // The next reading would throw "setState() called after dispose()".
  });

  testWidgets('With fix: closing the story cancels the stream', (tester) async {
    await openAndClose(tester, StoryLiveFix(story: story));

    expect(live.controller.hasListener, isFalse); // cancelled in close()
  });

  group('ReadingNowCubit', () {
    blocTest<ReadingNowCubit, int?>(
      'emits each readers count',
      build: () => ReadingNowCubit(live, 'b3'),
      act: (_) => live.controller
        ..add(1204)
        ..add(1210),
      expect: () => [1204, 1210],
    );

    blocTest<ReadingNowCubit, int?>(
      'hides the badge (null) when the live stream ends',
      build: () => ReadingNowCubit(live, 'b3'),
      act: (_) async {
        live.controller.add(1204);
        await live.controller.close();
      },
      expect: () => [1204, null],
    );

    test('close() cancels the subscription', () async {
      final cubit = ReadingNowCubit(live, 'b3');
      expect(live.controller.hasListener, isTrue);
      await cubit.close();
      expect(live.controller.hasListener, isFalse);
    });
  });
}
