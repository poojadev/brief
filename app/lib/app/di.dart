import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:waste_lens/waste_lens.dart';

import '../data/api/feed_api.dart';
import '../data/repository/feed_repository.dart';
import 'config.dart';
import 'feed_call_stats.dart';
import 'lab.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  // Lazy on purpose: first resolved when the feed opens, inside the WasteLens
  // tree, so WasteLens.current exists and the interceptor reports to it.
  getIt
    ..registerLazySingleton<FeedCallStats>(
      () => FeedCallStats(bus: WasteLens.current?.bus),
    )
    ..registerLazySingleton<Dio>(
      () => Dio(
        BaseOptions(
          baseUrl: AppConfig.baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 15),
        ),
      )..interceptors.add(getIt<FeedCallStats>().interceptor),
    )
    ..registerLazySingleton<FeedApi>(() => FeedApi(getIt<Dio>()))
    ..registerLazySingleton<FeedRepository>(
      () => FeedRepository(getIt<FeedApi>()),
    )
    ..registerLazySingleton<LabSettings>(LabSettings.new);
}
