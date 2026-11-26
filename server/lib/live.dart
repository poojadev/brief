import 'dart:math';

/// "Reading now" numbers for Episode 5: deterministic per story, gently
/// fluctuating over time, in the 800-2,500 range.
class LiveReaders {
  LiveReaders({required this.seed});

  final int seed;

  /// Readers of [storyId] at [tick] (one tick per second since the server
  /// started). Same seed, story and tick: same number.
  int at(String storyId, int tick) {
    final h = _fnv1a('$seed/$storyId');
    final base = 900 + h % 1400; // 900..2,299
    final phase = (h >> 11) % 628 / 100;
    final wave = 70 * sin(tick / 9 + phase); // slow swell
    final jitter = Random(h ^ tick).nextInt(25) - 12; // small, per second
    return (base + wave + jitter).round().clamp(800, 2500);
  }

  /// FNV-1a: a stable string hash (String.hashCode may change between runs).
  static int _fnv1a(String s) {
    var h = 0x811c9dc5;
    for (final unit in s.codeUnits) {
      h = ((h ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return h;
  }
}
