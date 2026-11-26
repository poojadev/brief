import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:waste_lens/waste_lens.dart';

import '../data/api/feed_api.dart';
import '../data/api/live_readers.dart';
import '../data/repository/feed_repository.dart';
import 'config.dart';
import 'feed_call_stats.dart';
import 'lab.dart';
import 'live_stats.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  // Lazy on purpose: first resolved when the feed opens, inside the WasteLens
  // tree, so WasteLens.current exists and the interceptor reports to it.
  getIt
    ..registerLazySingleton<FeedCallStats>(
      () => FeedCallStats(bus: WasteLens.current?.bus),
    )
    ..registerLazySingleton<Dio>(_createDio)
    ..registerLazySingleton<FeedApi>(() => FeedApi(getIt<Dio>()))
    ..registerLazySingleton<FeedRepository>(
      () => FeedRepository(getIt<FeedApi>()),
    )
    ..registerLazySingleton<LiveStats>(
      () => LiveStats(bus: WasteLens.current?.bus),
    )
    ..registerLazySingleton<LiveReaders>(
      () => SocketLiveReaders(
        baseUrl: AppConfig.wsUrl,
        stats: getIt<LiveStats>(),
      ),
    )
    ..registerLazySingleton<LabSettings>(LabSettings.new);
}

Dio _createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  dio.interceptors
    ..add(_labFailures)
    ..add(getIt<FeedCallStats>().interceptor);
  return dio;
}

/// Lab: "Server returns errors" adds ?fail=1, the mock server's switch for a
/// 503 response.
final _labFailures = InterceptorsWrapper(
  onRequest: (options, handler) {
    if (getIt<LabSettings>().serverErrors) {
      options.queryParameters = {...options.queryParameters, 'fail': 1};
    }
    handler.next(options);
  },
);
