import 'package:material_ui/material_ui.dart';

import '../../app/format.dart';
import '../../app/theme.dart';
import '../../data/models/story.dart';
import '../feed/widgets/cover_image.dart';

/// Reading a story: collapsing cover, serif title, byline, body, and a thin
/// reading-progress bar along the top.
class StoryPage extends StatefulWidget {
  const StoryPage({super.key, required this.story, this.readingNow});

  final Story story;

  /// Episode 5's live "reading now" badge, shown under the byline.
  final Widget? readingNow;

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  final _scroll = ScrollController();
  final _progress = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final max = _scroll.position.maxScrollExtent;
      _progress.value = max <= 0 ? 0 : (_scroll.offset / max).clamp(0.0, 1.0);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final text = Theme.of(context).textTheme;
    final c = BriefColors.of(context);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverAppBar(
                expandedHeight: 360,
                pinned: true,
                stretch: true,
                backgroundColor: c.paper,
                leading: _RoundIcon(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                actions: [
                  _RoundIcon(
                    icon: Icons.ios_share_rounded,
                    tooltip: 'Share',
                    onPressed: () {}, // not wired up in this demo
                  ),
                  const SizedBox(width: Space.s),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Hero(
                    tag: 'cover-${story.id}',
                    child: CoverImage(story: story, decodeWidth: 1200),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Space.l,
                        Space.l,
                        Space.l,
                        Space.xl * 2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoryLabel(story.category).toUpperCase(),
                            style: text.labelMedium!.copyWith(
                              color: c.accent,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: Space.s + 4),
                          Semantics(
                            header: true,
                            child: Text(
                              story.title,
                              style: text.headlineLarge!.copyWith(
                                fontWeight: FontWeight.w600,
                                height: 1.12,
                              ),
                            ),
                          ),
                          const SizedBox(height: Space.m),
                          Text(
                            story.summary,
                            style: text.titleMedium!.copyWith(
                              color: c.muted,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: Space.l),
                          _Byline(story: story),
                          if (widget.readingNow case final badge?) ...[
                            const SizedBox(height: Space.s + 4),
                            badge,
                          ],
                          const SizedBox(height: Space.l),
                          Divider(color: c.hairline, height: 1),
                          const SizedBox(height: Space.l),
                          for (final p in story.body.skip(1)) ...[
                            Text(
                              p,
                              style: text.bodyLarge!.copyWith(
                                fontSize: 18,
                                height: 1.7,
                              ),
                            ),
                            const SizedBox(height: Space.m + 4),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Reading progress, just under the status bar.
          Positioned(
            top: top,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<double>(
              valueListenable: _progress,
              builder: (context, v, _) => Semantics(
                label: 'Reading progress ${(v * 100).round()} percent',
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: v,
                    child: Container(height: 3, color: c.accent),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Byline extends StatelessWidget {
  const _Byline({required this.story});

  final Story story;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = BriefColors.of(context);
    final initials = story.author.split(' ').map((w) => w[0]).take(2).join();
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: c.skeleton,
          child: Text(
            initials,
            style: text.labelLarge!.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: Space.s + 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'By ${story.author}',
                style: text.titleSmall!.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '${story.source} · ${timeAgo(story.publishedAt)} · ${story.readMinutes} min read',
                style: text.bodySmall!.copyWith(color: c.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Icon button with a soft backdrop, so it reads over any cover image.
class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = BriefColors.of(context);
    return Center(
      child: Material(
        color: c.card.withValues(alpha: 0.85),
        shape: const CircleBorder(),
        child: IconButton(
          icon: Icon(icon, color: c.ink),
          tooltip: tooltip,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
