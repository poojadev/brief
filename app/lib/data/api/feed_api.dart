import 'package:dio/dio.dart';

import '../models/story.dart';

/// REST client for the Brief mock server.
class FeedApi {
  FeedApi(this._dio);

  final Dio _dio;

  /// GET /feed?category=top&page=1
  Future<List<Story>> fetchFeed(String category, {int page = 1}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/feed',
      queryParameters: {'category': category, 'page': page},
    );
    return [
      for (final s in res.data!['stories'] as List<dynamic>)
        Story.fromJson(s as Map<String, dynamic>),
    ];
  }
}
