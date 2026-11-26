import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:brief_server/cover.dart';
import 'package:brief_server/live.dart';
import 'package:brief_server/news.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Brief mock news server.
///
///   dart run bin/server.dart                       # defaults
///   dart run bin/server.dart --jitter-ms 600       # responses can overtake each other
Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('port', defaultsTo: '8081')
    ..addOption('latency-ms',
        defaultsTo: '700', help: 'Delay on every /feed response (the "spinner that lies")')
    ..addOption('jitter-ms',
        defaultsTo: '0', help: 'Extra random 0..N ms per /feed response, so they can arrive out of order')
    ..addOption('seed', defaultsTo: '42')
    ..addFlag('log-images', help: 'Also log every /images request')
    ..addFlag('help', abbr: 'h', negatable: false);
  final opts = parser.parse(args);
  if (opts['help'] as bool) {
    stdout.writeln(parser.usage);
    return;
  }

  final port = int.parse(opts['port'] as String);
  final latency = int.parse(opts['latency-ms'] as String);
  final jitter = int.parse(opts['jitter-ms'] as String);
  final logImages = opts['log-images'] as bool;
  final news = Newsroom(seed: int.parse(opts['seed'] as String));
  final timing = Random(); // timing only; the content stays deterministic
  final live = LiveReaders(seed: int.parse(opts['seed'] as String));
  final clock = DateTime.now();
  final sockets = _SocketLog();

  final router = Router()
    ..get('/health', (Request _) => _json({'ok': true}))
    // GET /feed?category=top&page=1
    ..get('/feed', (Request req) async {
      final category = req.url.queryParameters['category'] ?? 'top';
      final page = int.tryParse(req.url.queryParameters['page'] ?? '1') ?? 1;
      final n = req.context['brief.n'];
      final delay = latency + (jitter > 0 ? timing.nextInt(jitter + 1) : 0);
      await Future<void>.delayed(Duration(milliseconds: delay));
      // The app's Lab switch "Server returns errors" adds ?fail=1.
      if (req.url.queryParameters['fail'] == '1') {
        stdout.writeln('       [#$n] 503 after ${delay}ms  (Lab: server returns errors)');
        return _json({'error': 'Simulated outage'}, status: 503);
      }
      // Page 1 is "what's new now": publish 1-3 fresh stories first.
      final fresh = page == 1 ? news.publish() : 0;
      stdout.writeln('       [#$n] 200 after ${delay}ms${fresh > 0 ? '  +$fresh new' : ''}');
      return _json(news.feed(category, page));
    })
    // WS /live/<storyId>: {"storyId", "readers"} once a second (Episode 5).
    ..get('/live/<storyId>', (Request req, String storyId) {
      return webSocketHandler((WebSocketChannel ws, String? _) {
        sockets.open(storyId);
        final started = DateTime.now();
        void send() {
          final tick = DateTime.now().difference(clock).inSeconds;
          ws.sink.add(jsonEncode({'storyId': storyId, 'readers': live.at(storyId, tick)}));
        }

        send();
        final timer = Timer.periodic(const Duration(seconds: 1), (_) => send());
        // The client cancelled (or vanished): stop sending, close our side.
        ws.stream.listen(
          (_) {},
          onDone: () {
            timer.cancel();
            ws.sink.close();
            sockets.close(storyId, DateTime.now().difference(started));
          },
          onError: (_) {},
          cancelOnError: false,
        );
      })(req);
    })
    ..get('/images/<file>', (Request req, String file) {
      final id = file.replaceAll('.jpg', '');
      return Response.ok(coverJpg(id), headers: {
        'content-type': 'image/jpeg',
        'cache-control': 'public, max-age=86400',
      });
    });

  final handler = const Pipeline()
      .addMiddleware(_requestLog(logImages: logImages))
      .addHandler(router.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln('''
Brief mock news on http://${server.address.host}:${server.port}
  latency=${latency}ms  jitter=${jitter}ms  images ${logImages ? 'logged' : 'quiet'}
  iOS simulator:     http://localhost:$port
  Android emulator:  http://10.0.2.2:$port
''');
}

Response _json(Object body, {int status = 200}) => Response(
      status,
      body: jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );

/// Logs every API request and flags repeats of the same URL within 2 seconds:
/// the server-side view of duplicate fetches. Images stay quiet unless asked.
Middleware _requestLog({required bool logImages}) {
  final recent = <String, List<DateTime>>{};
  var n = 0;
  return (inner) => (req) async {
        if (req.url.path.startsWith('live/')) return inner(req); // [ws] lines
        final isImage = req.url.path.startsWith('images/');
        if (isImage) {
          if (logImages) stdout.writeln('  · ${req.url.path}');
          return inner(req);
        }
        final key = '${req.method} /${req.url}';
        final now = DateTime.now();
        final hits = recent.putIfAbsent(key, () => [])
          ..removeWhere((t) => now.difference(t) > const Duration(seconds: 2))
          ..add(now);
        n++;
        final dup = hits.length > 1 ? '   <-- x${hits.length} in 2s' : '';
        stdout.writeln('[#$n] $key$dup');
        return inner(req.change(context: {'brief.n': n}));
      };
}

/// Logs live sockets opening and closing, with how many are open right now.
class _SocketLog {
  var _open = 0;

  void open(String storyId) {
    _open++;
    stdout.writeln('[ws] +1 /live/$storyId   open sockets: $_open');
  }

  void close(String storyId, Duration lived) {
    _open--;
    stdout.writeln('[ws] -1 /live/$storyId   open sockets: $_open'
        '   (after ${lived.inSeconds}s)');
  }
}
