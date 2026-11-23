import 'package:dio/dio.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:waste_lens/waste_lens.dart';
import 'package:waste_lens_dio/waste_lens_dio.dart';

/// GET /feed traffic, as waste_lens_dio's RedundantCallInterceptor sees it.
///
/// "redundant" is the interceptor's own verdict: an identical request that
/// starts within 2 s of a previous one FINISHING. Duplicates that are both
/// in flight at the same time are not flagged (waste_lens_dio 0.1.x only
/// catches those in coalesce mode). The server log sees everything.
class FeedCallStats extends ChangeNotifier {
  FeedCallStats({DiagnosticsBus? bus})
    : _inner = RedundantCallInterceptor(bus: bus);

  final RedundantCallInterceptor _inner;
  ({int requests, int redundant}) _base = (requests: 0, redundant: 0);
  bool _notifyScheduled = false;

  /// Add this to Dio once.
  Interceptor get interceptor => _Forwarder(this);

  ({int requests, int redundant}) get _total {
    var requests = 0, redundant = 0;
    for (final e in _inner.report.endpoints) {
      if (e.endpoint == 'GET /feed') {
        requests += e.total;
        redundant += e.redundant;
      }
    }
    return (requests: requests, redundant: redundant);
  }

  /// /feed requests since the current run started (e.g. since the Lab mode
  /// was switched).
  int get requests => _total.requests - _base.requests;
  int get redundant => _total.redundant - _base.redundant;

  /// Start counting from zero.
  void startRun() {
    _base = _total;
    _notifyAfterFrame();
  }

  /// Counters change while requests are in flight, often mid-frame: update
  /// listeners once, after the frame, never during a build.
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
}

class _Forwarder extends Interceptor {
  _Forwarder(this._stats);

  final FeedCallStats _stats;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _stats._inner.onRequest(options, handler);
    _stats._notifyAfterFrame();
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _stats._inner.onResponse(response, handler);
    _stats._notifyAfterFrame();
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _stats._inner.onError(err, handler);
    _stats._notifyAfterFrame();
  }
}
