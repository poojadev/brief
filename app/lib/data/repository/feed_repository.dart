import '../api/feed_api.dart';
import '../models/story.dart';

/// No cache and no de-duplication: every call is a network request.
/// (Episode 4 is about who triggers loads, not about hiding them here.)
class FeedRepository {
  FeedRepository(this._api);

  final FeedApi _api;

  Future<List<Story>> load(String category) => _api.fetchFeed(category);
}
