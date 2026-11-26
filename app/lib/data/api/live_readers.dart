import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:waste_lens/waste_lens.dart';

import '../../app/live_stats.dart';

/// "Reading now" for a story, live: one number about once a second.
abstract interface class LiveReaders {
  /// Listening opens a live socket for [storyId]; cancelling closes it.
  /// If the socket fails, the stream just ends (no error event).
  Stream<int> watch(String storyId);
}

/// [LiveReaders] over the mock server's WS /live/{storyId}.
class SocketLiveReaders implements LiveReaders {
  SocketLiveReaders({required this.baseUrl, this.stats});

  /// e.g. ws://localhost:8081
  final String baseUrl;
  final LiveStats? stats;

  @override
  Stream<int> watch(String storyId) {
    LiveReadersSession? session;
    late final StreamController<int> out;
    out = StreamController<int>(
      onListen: () => session = LiveReadersSession(
        Uri.parse('$baseUrl/live/$storyId'),
        onReaders: out.add,
        onEnd: out.close,
        stats: stats,
      ),
      onCancel: () => session?.close(),
    );
    return out.stream;
  }
}

/// One live socket. Opens when created; [close] closes it.
///
/// DisposeGuard reports it to waste_lens (leak_tracker): trackCreation()
/// when the socket opens, trackDisposal() when it's closed.
class LiveReadersSession with DisposeGuard {
  LiveReadersSession(
    Uri url, {
    required this.onReaders,
    required this.onEnd,
    this.stats,
  }) : _run = stats?.run ?? 0 {
    trackCreation();
    stats?.socketOpened(_run);
    unawaited(_connect(url));
  }

  final void Function(int readers) onReaders;
  final void Function() onEnd;
  final LiveStats? stats;
  final int _run;
  WebSocket? _socket;
  bool _closed = false;

  Future<void> _connect(Uri url) async {
    try {
      final socket = await WebSocket.connect(url.toString());
      if (_closed) return unawaited(socket.close());
      _socket = socket;
      socket.listen(
        (message) {
          final readers = (jsonDecode(message as String) as Map)['readers'];
          if (!_closed && readers is int) onReaders(readers);
        },
        onDone: _ended,
        onError: (Object _) => _ended(),
        cancelOnError: true,
      );
    } on Object {
      _ended(); // no server, no badge: end quietly
    }
  }

  void _ended() {
    if (_closed) return;
    close();
    onEnd();
  }

  void close() {
    if (_closed) return;
    _closed = true;
    trackDisposal();
    stats?.socketClosed(_run);
    unawaited(_socket?.close());
  }
}
