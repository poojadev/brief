import 'package:flutter/foundation.dart';

/// Episode 4's Lab: which version of the feed screen runs.
enum LabMode { bug, fix }

class LabSettings extends ChangeNotifier {
  LabMode _mode = LabMode.bug;
  bool _showStrip = true;
  bool _serverErrors = false;

  LabMode get mode => _mode;
  bool get showStrip => _showStrip;

  /// Ask the mock server to fail every /feed request (503 after its usual
  /// delay), to check that the spinner still stops.
  bool get serverErrors => _serverErrors;

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
