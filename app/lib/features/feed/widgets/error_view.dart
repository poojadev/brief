import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';

/// Friendly failure state with a Retry button.
class FeedErrorView extends StatelessWidget {
  const FeedErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = BriefColors.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: c.skeleton,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              size: 44,
              color: c.accent,
              semanticLabel: 'Offline',
            ),
          ),
          const SizedBox(height: Space.l),
          Text(
            'The news is running late',
            style: text.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.s),
          Text(
            "We couldn't reach the Brief server. Is it running?\n"
            'cd server && dart run bin/server.dart',
            textAlign: TextAlign.center,
            style: text.bodyMedium!.copyWith(color: c.muted, height: 1.5),
          ),
          const SizedBox(height: Space.l),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
            style: FilledButton.styleFrom(minimumSize: const Size(160, 48)),
          ),
        ],
      ),
    );
  }
}
