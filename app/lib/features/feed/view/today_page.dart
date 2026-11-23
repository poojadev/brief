import 'package:material_ui/material_ui.dart';

import '../../../app/di.dart';
import '../../../app/lab.dart';
import '../../../app/theme.dart';
import '../../lab/debug_strip.dart';
import '../../lab/lab_sheet.dart';
import 'feed_bug.dart';
import 'feed_fix.dart';

/// The Today screen. The Lab decides which version of the feed runs.
class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lab = getIt<LabSettings>();
    return ListenableBuilder(
      listenable: lab,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          titleSpacing: Space.m,
          title: const _Wordmark(),
          actions: [
            _LabPill(onTap: () => showLabSheet(context)),
            const SizedBox(width: Space.s),
          ],
        ),
        // Switching modes builds a brand-new feed screen, so "open" happens again.
        body: KeyedSubtree(
          key: ValueKey(lab.mode),
          child: lab.mode == LabMode.bug
              ? const FeedPageBug()
              : const FeedPageFix(),
        ),
        bottomNavigationBar: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: lab.showStrip
              ? DebugStrip(mode: lab.mode)
              : const SizedBox(width: double.infinity),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final c = BriefColors.of(context);
    return Semantics(
      label: 'Brief',
      header: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: c.accent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: Space.s),
          Text(
            'Brief',
            style: Theme.of(context).textTheme.titleLarge!
                .copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
          ),
        ],
      ),
    );
  }
}

class _LabPill extends StatelessWidget {
  const _LabPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = BriefColors.of(context);
    return Semantics(
      button: true,
      label: 'Open the Lab',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 48,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: c.hairline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.science_outlined, size: 16, color: c.accent),
                  const SizedBox(width: 6),
                  Text('Lab', style: Theme.of(context).textTheme.labelLarge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
