import 'package:leak_tracker/leak_tracker.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/di.dart';
import '../../app/feed_call_stats.dart';
import '../../app/lab.dart';
import '../../app/live_stats.dart';
import '../../app/theme.dart';

/// The episodes' controls, out of the way of the design.
Future<void> showLabSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  // As tall as its content (it scrolls if a small phone needs it).
  isScrollControlled: true,
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
        child: SingleChildScrollView(
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
                const SizedBox(height: Space.m),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<LabEpisode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: LabEpisode.refresh,
                        label: Text('Ep 4 · refresh'),
                      ),
                      ButtonSegment(
                        value: LabEpisode.streams,
                        label: Text('Ep 5 · streams'),
                      ),
                    ],
                    selected: {lab.episode},
                    onSelectionChanged: (s) => lab.episode = s.first,
                  ),
                ),
                const SizedBox(height: Space.l - 4),
                if (lab.episode == LabEpisode.refresh)
                  ..._episode4(lab, text, c)
                else
                  ..._episode5(lab, text, c),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _episode4(LabSettings lab, TextTheme text, BriefColors c) => [
    Text(
      'Episode 4: pull-to-refresh + initState. Switch the feed between '
      'the buggy and the fixed version.',
      style: text.bodyMedium!.copyWith(color: c.muted, height: 1.45),
    ),
    const SizedBox(height: Space.m),
    _ModeButtons(
      selected: lab.mode,
      onChanged: (mode) {
        // Count the new mode's requests from zero.
        getIt<FeedCallStats>().startRun();
        lab.mode = mode;
      },
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
      subtitle: const Text('/feed requests, counted by waste_lens_dio'),
      value: lab.showStrip,
      onChanged: (v) => lab.showStrip = v,
    ),
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: const Text('Server returns errors'),
      subtitle: const Text(
        'Every /feed request fails with a 503 after the usual delay',
      ),
      value: lab.serverErrors,
      onChanged: (v) => lab.serverErrors = v,
    ),
  ];

  List<Widget> _episode5(LabSettings lab, TextTheme text, BriefColors c) => [
    Text(
      'Episode 5: the stream you forgot to cancel. Opening a story uses '
      'this mode for its live "reading now" badge.',
      style: text.bodyMedium!.copyWith(color: c.muted, height: 1.45),
    ),
    const SizedBox(height: Space.m),
    _ModeButtons(
      selected: lab.liveMode,
      onChanged: (mode) {
        // Count the new mode's sockets and leaks from zero.
        getIt<LiveStats>().startRun();
        lab.liveMode = mode;
      },
    ),
    const SizedBox(height: Space.m),
    Text(
      lab.liveMode == LabMode.bug
          ? 'The story page subscribes in initState and never cancels. '
                'Every story you close leaves its socket open.'
          : 'A cubit owns the subscription and cancels it in close(). '
                'BlocProvider closes the cubit when you leave the story.',
      style: text.bodySmall!.copyWith(color: c.muted, height: 1.45),
    ),
    const SizedBox(height: Space.s),
    ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Run garbage collection'),
      subtitle: const Text(
        'Then waste_lens re-checks: closed story pages still held in memory '
        'are reported as not-gced leaks',
      ),
      trailing: Icon(Icons.recycling_rounded, color: c.accent),
      // leak_tracker only judges objects after garbage collection; on its
      // own the Dart VM may not collect for minutes. Force 3 full cycles.
      onTap: () => forceGC(fullGcCycles: 3),
    ),
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: const Text('Show debug strip'),
      subtitle: const Text('Open live sockets, and waste_lens leak reports'),
      value: lab.showStrip,
      onChanged: (v) => lab.showStrip = v,
    ),
  ];
}

/// "With bug" / "With fix", the same control for every episode.
class _ModeButtons extends StatelessWidget {
  const _ModeButtons({required this.selected, required this.onChanged});

  final LabMode selected;
  final ValueChanged<LabMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
        selected: {selected},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}
