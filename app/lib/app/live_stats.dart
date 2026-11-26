import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:waste_lens/waste_lens.dart';

/// Episode 5's counters for the debug strip: "sockets: N · leaks: M".
///
/// sockets: live sessions opened in the current run that are still open,
///          on the client side (the server log counts them independently).
/// leaks:   waste_lens LeakReported events about Episode 5's objects since
///          the run started.
class LiveStats extends ChangeNotifier {
  LiveStats({DiagnosticsBus? bus}) {
    _leakSub = bus?.stream.where((e) => e is LeakReported).listen((e) {
      final leak = e as LeakReported;
      // Count only Episode 5's objects. Other reports (e.g. Flutter's own
      // route-transition CurvedAnimations) are real but unrelated noise.
      final ours = episode5Types.contains(leak.type);
      debugPrint(
        'waste_lens leak: ${leak.kind} ${leak.type}'
        '${ours ? '' : '  (not Episode 5, not counted)'}',
      );
      if (!ours) return;
      _leaks += leak.count;
      _notifyAfterFrame();
    });
  }

  /// The live session (DisposeGuard) and the buggy story page's State.
  static const episode5Types = {'LiveReadersSession', '_StoryLiveBugState'};

  StreamSubscription<DiagnosticEvent>? _leakSub;
  int _run = 0;
  int _sockets = 0;
  int _leaks = 0;
  int _leaksAtRunStart = 0;
  bool _notifyScheduled = false;

  /// The current run; a session remembers the run it was opened in.
  int get run => _run;
  int get sockets => _sockets;
  int get leaks => _leaks - _leaksAtRunStart;

  void socketOpened(int run) {
    if (run != _run) return;
    _sockets++;
    _notifyAfterFrame();
  }

  void socketClosed(int run) {
    if (run != _run) return;
    _sockets--;
    _notifyAfterFrame();
  }

  /// Count from zero (e.g. when the Lab mode changes). Sockets from earlier
  /// runs may still be open; the server log still shows them.
  void startRun() {
    _run++;
    _sockets = 0;
    _leaksAtRunStart = _leaks;
    _notifyAfterFrame();
  }

  /// Sockets open and close mid-frame: update listeners after the frame,
  /// never during a build.
  void _notifyAfterFrame() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        _notifyScheduled = false;
        notifyListeners();
      })
      ..ensureVisualUpdate();
  }

  @override
  void dispose() {
    unawaited(_leakSub?.cancel());
    super.dispose();
  }
}
