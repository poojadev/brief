import 'package:flutter/foundation.dart';
import 'package:leak_tracker/leak_tracker.dart';

/// Which version runs: the buggy one or the fixed one.
enum LabMode { bug, fix }

/// Which episode the Lab (and the debug strip) is about.
enum LabEpisode { refresh, streams }

class LabSettings extends ChangeNotifier {
  LabEpisode _episode = LabEpisode.refresh;
  LabMode _mode = LabMode.bug;
  LabMode _liveMode = LabMode.bug;
  bool _showStrip = true;
  bool _serverErrors = false;

  LabEpisode get episode => _episode;

  /// Episode 4: the feed screen.
  LabMode get mode => _mode;

  /// Episode 5: the story page's live "reading now" badge.
  LabMode get liveMode => _liveMode;
  bool get showStrip => _showStrip;

  /// Ask the mock server to fail every /feed request (503 after its usual
  /// delay), to check that the spinner still stops.
  bool get serverErrors => _serverErrors;

  set episode(LabEpisode value) {
    if (value == _episode) return;
    _episode = value;
    // Episode 5 also needs "not-gced" leaks (disposed, but still held in
    // memory), which leak_tracker ignores by default: a forgotten
    // subscription keeps a closed page's State alive. Objects created from
    // now on are tracked this way; Episode 4 keeps the defaults.
    LeakTracking.phase = value == LabEpisode.streams
        ? const PhaseSettings(
            ignoredLeaks: IgnoredLeaks(experimentalNotGCed: IgnoredLeaksSet()),
          )
        : const PhaseSettings();
    notifyListeners();
  }

  set liveMode(LabMode value) {
    if (value == _liveMode) return;
    _liveMode = value;
    notifyListeners();
  }

  set mode(LabMode value) {
    if (value == _mode) return;
    _mode = value;
    notifyListeners();
  }

  set showStrip(bool value) {
    if (value == _showStrip) return;
    _showStrip = value;
    notifyListeners();
  }

  set serverErrors(bool value) {
    if (value == _serverErrors) return;
    _serverErrors = value;
    notifyListeners();
  }
}
