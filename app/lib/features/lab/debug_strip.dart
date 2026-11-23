import 'package:material_ui/material_ui.dart';

import '../../app/di.dart';
import '../../app/feed_call_stats.dart';
import '../../app/lab.dart';
import '../../app/theme.dart';

/// Slim strip at the bottom: "requests: N · redundant: M" for /feed.
class DebugStrip extends StatelessWidget {
  const DebugStrip({super.key, required this.mode});

  final LabMode mode;

  @override
  Widget build(BuildContext context) {
    final stats = getIt<FeedCallStats>();
    final c = BriefColors.of(context);
    final bug = mode == LabMode.bug;
    final style = Theme.of(context).textTheme.labelMedium!.copyWith(
      color: c.paper,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Container(
      color: c.ink,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 36,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.m),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: bug
                        ? const Color(0xFFE0A52E)
                        : const Color(0xFF3FB97A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: Space.s),
                Text(
                  bug ? 'With bug' : 'With fix',
                  style: style.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: Space.m),
                // Left-aligned: the waste_lens bubble lives bottom-right.
                ListenableBuilder(
                  listenable: stats,
                  builder: (context, _) => Text(
                    'requests: ${stats.requests} · redundant: ${stats.redundant}',
                    style: style,
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
