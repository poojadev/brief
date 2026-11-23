import 'package:material_ui/material_ui.dart';

import '../../../app/format.dart';
import '../../../app/theme.dart';
import '../../../data/models/story.dart';
import 'cover_image.dart';
import 'pressable.dart';

/// The lead story: full-bleed cover, gradient scrim, serif headline.
class HeroStory extends StatelessWidget {
  const HeroStory({super.key, required this.story, required this.onTap});

  final Story story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = BriefColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.m),
      child: Pressable(
        onTap: onTap,
        label: 'Lead story: ${story.title}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: c.shadow,
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: 1.08,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'cover-${story.id}',
                  child: CoverImage(story: story, decodeWidth: 1000),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0x33000000),
                        Color(0xD9000000),
                      ],
                      stops: [0.35, 0.55, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(Space.l - 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label(categoryLabel(story.category)),
                      const SizedBox(height: Space.s + 4),
                      Text(
                        story.title,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: text.headlineMedium!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: Space.s + 4),
                      Text(
                        '${story.source} · ${timeAgo(story.publishedAt)} · ${story.readMinutes} min read',
                        style: text.bodySmall!.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: BriefColors.of(context).accent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
