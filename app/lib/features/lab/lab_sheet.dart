import 'package:material_ui/material_ui.dart';

import '../../app/di.dart';
import '../../app/feed_call_stats.dart';
import '../../app/lab.dart';
import '../../app/theme.dart';

/// Episode 4's controls, out of the way of the design.
Future<void> showLabSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  builder: (_) => const _LabSheet(),
);

class _LabSheet extends StatelessWidget {
  const _LabSheet();

  @override
  Widget build(BuildContext context) {
    final lab = getIt<LabSettings>();
    final text = Theme.of(context).textTheme;
    final c = BriefColors.of(context);
    return ListenableBuilder(
      listenable: lab,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lab',
                style: text.headlineSmall!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Space.xs),
              Text(
                'Episode 4: pull-to-refresh + initState. Switch the feed between '
                'the buggy and the fixed version.',
                style: text.bodyMedium!.copyWith(color: c.muted, height: 1.45),
              ),
              const SizedBox(height: Space.l - 4),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<LabMode>(
                  segments: const [
                    ButtonSegment(
                      value: LabMode.bug,
                      icon: Icon(Icons.bug_report_outlined),
                      label: Text('With bug'),
                    ),
                    ButtonSegment(
                      value: LabMode.fix,
                      icon: Icon(Icons.check_circle_outline),
                      label: Text('With fix'),
                    ),
                  ],
                  selected: {lab.mode},
                  onSelectionChanged: (s) {
                    // Count the new mode's requests from zero.
                    getIt<FeedCallStats>().startRun();
                    lab.mode = s.first;
                  },
                ),
              ),
              const SizedBox(height: Space.m),
              Text(
                lab.mode == LabMode.bug
                    ? 'Loads in initState AND calls show() on open. onRefresh '
                          'returns immediately, so the spinner disappears before the data.'
                    : 'Loads once when opened. onRefresh waits for the data, and '
                          'extra refreshes are dropped while one is running.',
                style: text.bodySmall!.copyWith(color: c.muted, height: 1.45),
              ),
              const SizedBox(height: Space.s),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show debug strip'),
                subtitle: const Text(
                  '/feed requests, counted by waste_lens_dio',
                ),
                value: lab.showStrip,
                onChanged: (v) => lab.showStrip = v,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
