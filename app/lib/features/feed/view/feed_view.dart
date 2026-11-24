import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/format.dart';
import '../../../app/theme.dart';
import '../../../data/models/story.dart';
import '../../story/story_page.dart';
import '../bloc/feed_bloc.dart';
import '../widgets/category_chips.dart';
import '../widgets/error_view.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/hero_story.dart';
import '../widgets/new_stories_pill.dart';
import '../widgets/shimmer.dart';
import '../widgets/story_card.dart';

/// Everything the Today feed draws. Shared by the "With bug" and "With fix"
/// screens, so those two files differ only in WHEN and HOW they load.
class FeedView extends StatefulWidget {
  const FeedView({
    super.key,
    required this.refreshKey,
    required this.onRefresh,
  });

  final GlobalKey<RefreshIndicatorState> refreshKey;
  final RefreshCallback onRefresh;

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _open(Story story) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => StoryPage(story: story)));

  void _showNew() {
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
    context.read<FeedBloc>().add(const FeedNewStoriesSeen());
  }

  @override
  Widget build(BuildContext context) {
    final c = BriefColors.of(context);
    return BlocConsumer<FeedBloc, FeedState>(
      // A refresh that failed keeps the old stories on screen: say so.
      listenWhen: (before, now) =>
          before.refreshing && !now.refreshing && now.error != null,
      listener: (context, state) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("Couldn't refresh. Pull to try again.")),
        ),
      builder: (context, state) => Stack(
        children: [
          RefreshIndicator(
            key: widget.refreshKey,
            color: c.accent,
            backgroundColor: c.card,
            onRefresh: () {
              HapticFeedback.mediumImpact();
              return widget.onRefresh();
            },
            child: CustomScrollView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _Header(category: state.category)),
                ..._content(context, state),
                const SliverToBoxAdapter(child: SizedBox(height: Space.xl)),
              ],
            ),
          ),
          Positioned(
            top: Space.s,
            left: 0,
            right: 0,
            child: Center(
              child: NewStoriesPill(count: state.newCount, onTap: _showNew),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _content(BuildContext context, FeedState state) {
    switch (state.status) {
      case FeedStatus.initial:
      case FeedStatus.loading:
        return const [SliverToBoxAdapter(child: FeedSkeleton())];
      case FeedStatus.failure:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: FeedErrorView(
                onRetry: () =>
                    context.read<FeedBloc>().add(const FeedStarted()),
              ),
            ),
          ),
        ];
      case FeedStatus.loaded:
        if (state.stories.isEmpty) {
          return const [
            SliverToBoxAdapter(child: Center(child: Text('Nothing new yet.'))),
          ];
        }
        final lead = state.stories.first;
        final rest = state.stories.sublist(1);
        return [
          SliverToBoxAdapter(
            child: FadeSlideIn(
              key: ValueKey('hero-${lead.id}'),
              child: HeroStory(story: lead, onTap: () => _open(lead)),
            ),
          ),
          const SliverToBoxAdapter(child: _SectionTitle('Latest')),
          SliverList.builder(
            itemCount: rest.length,
            // Keep each card's element (and its entrance animation) attached
            // to its story when new stories push everything down.
            findChildIndexCallback: (key) {
              final id = (key as ValueKey<String>).value;
              final i = rest.indexWhere((s) => s.id == id);
              return i < 0 ? null : i;
            },
            itemBuilder: (context, i) => FadeSlideIn(
              key: ValueKey(rest[i].id),
              delay: Duration(milliseconds: 40 * min(i, 6)),
              child: StoryCard(story: rest[i], onTap: () => _open(rest[i])),
            ),
          ),
        ];
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = BriefColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.m,
            Space.s,
            Space.m,
            Space.m,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  longDate(DateTime.now()),
                  style: text.displaySmall!.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(height: Space.xs + 2),
              Text(
                'The stories worth your time today.',
                style: text.bodyLarge!.copyWith(color: c.muted),
              ),
            ],
          ),
        ),
        CategoryChips(
          selected: category,
          onSelected: (cat) =>
              context.read<FeedBloc>().add(FeedCategorySelected(cat)),
        ),
        const SizedBox(height: Space.m),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.m, Space.l, Space.m, Space.s),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge!
              .copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
