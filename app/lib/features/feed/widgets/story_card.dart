import 'package:material_ui/material_ui.dart';

import '../../../app/format.dart';
import '../../../app/theme.dart';
import '../../../data/models/story.dart';
import 'cover_image.dart';
import 'pressable.dart';

/// One story in the list: thumbnail, source, time, 2-line serif headline.
class StoryCard extends StatelessWidget {
  const StoryCard({super.key, required this.story, required this.onTap});

  final Story story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = BriefColors.of(context);
    return Pressable(
      onTap: onTap,
      label: story.title,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: Space.m,
          vertical: Space.s - 2,
        ),
        padding: const EdgeInsets.all(Space.s + 4),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 92,
                height: 92,
                child: Hero(
                  tag: 'cover-${story.id}',
                  child: CoverImage(story: story, decodeWidth: 300),
                ),
              ),
            ),
            const SizedBox(width: Space.m - 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${story.source.toUpperCase()} · ${timeAgo(story.publishedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall!.copyWith(
                      color: c.muted,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Space.xs + 2),
                  Text(
                    story.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleLarge!.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.22,
                    ),
                  ),
                  const SizedBox(height: Space.s),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 14, color: c.muted),
                      const SizedBox(width: Space.xs),
                      Text(
                        '${story.readMinutes} min read',
                        style: text.bodySmall!.copyWith(color: c.muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
