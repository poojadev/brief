import 'package:flutter/foundation.dart';

/// Episode 4's Lab: which version of the feed screen runs.
enum LabMode { bug, fix }

class LabSettings extends ChangeNotifier {
  LabMode _mode = LabMode.bug;
  bool _showStrip = true;

  LabMode get mode => _mode;
  bool get showStrip => _showStrip;

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
}
