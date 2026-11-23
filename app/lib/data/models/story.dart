import 'package:equatable/equatable.dart';

import '../../app/config.dart';

class Story extends Equatable {
  const Story({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    required this.category,
    required this.source,
    required this.author,
    required this.publishedAt,
    required this.readMinutes,
    required this.imageUrl,
  });

  factory Story.fromJson(Map<String, dynamic> json) => Story(
    id: json['id'] as String,
    title: json['title'] as String,
    summary: json['summary'] as String,
    body: [for (final p in json['body'] as List<dynamic>) p as String],
    category: json['category'] as String,
    source: json['source'] as String,
    author: json['author'] as String,
    publishedAt: DateTime.parse(json['publishedAt'] as String),
    readMinutes: json['readMinutes'] as int,
    imageUrl: '${AppConfig.baseUrl}${json['imageUrl']}',
  );

  final String id;
  final String title;
  final String summary;
  final List<String> body;
  final String category;
  final String source;
  final String author;
  final DateTime publishedAt;
  final int readMinutes;
  final String imageUrl;

  @override
  List<Object?> get props => [id, title, publishedAt];
}

/// The categories the server knows, in chip order.
const categories = ['top', 'tech', 'markets', 'health', 'science', 'culture'];

String categoryLabel(String c) =>
    c == 'top' ? 'Top' : '${c[0].toUpperCase()}${c.substring(1)}';
