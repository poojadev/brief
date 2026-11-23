import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../data/models/story.dart';

/// A story's cover art. Fades in when it arrives, and falls back to a calm
/// block of colour if it can't load (offline, or in widget tests).
class CoverImage extends StatelessWidget {
  const CoverImage({super.key, required this.story, this.decodeWidth = 800});

  final Story story;

  /// Decode at roughly display size, not the full 1200 px.
  final int decodeWidth;

  @override
  Widget build(BuildContext context) {
    final c = BriefColors.of(context);
    return Image.network(
      story.imageUrl,
      fit: BoxFit.cover,
      cacheWidth: decodeWidth,
      semanticLabel: 'Illustration for "${story.title}"',
      frameBuilder: (context, child, frame, sync) => sync
          ? child
          : AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: child,
            ),
      errorBuilder: (context, _, _) => ColoredBox(color: c.skeleton),
    );
  }
}
