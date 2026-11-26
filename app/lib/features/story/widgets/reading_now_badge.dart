import 'package:material_ui/material_ui.dart';

import '../../../app/format.dart';
import '../../../app/theme.dart';

/// "● 1,204 reading now": a small pill under the byline.
///
/// [readers] null means unknown (not connected yet, or the socket failed):
/// the pill fades out but keeps its space, so nothing below it jumps.
class ReadingNowBadge extends StatelessWidget {
  const ReadingNowBadge({super.key, required this.readers});

  final int? readers;

  static const height = 30.0;

  @override
  Widget build(BuildContext context) {
    final c = BriefColors.of(context);
    final readers = this.readers;
    final still = MediaQuery.disableAnimationsOf(context);
    final style = Theme.of(context).textTheme.labelLarge!.copyWith(
      color: c.ink,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return SizedBox(
      height: height,
      child: AnimatedOpacity(
        opacity: readers == null ? 0 : 1,
        duration: still ? Duration.zero : const Duration(milliseconds: 250),
        child: readers == null
            ? const SizedBox.shrink()
            : Semantics(
                label: '${grouped(readers)} people reading now',
                excludeSemantics: true,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: c.hairline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PulsingDot(color: c.accent, still: still),
                        const SizedBox(width: Space.s),
                        _RollingNumber(
                          text: grouped(readers),
                          style: style.copyWith(fontWeight: FontWeight.w700),
                          still: still,
                        ),
                        Text(
                          ' reading now',
                          style: style.copyWith(color: c.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// The number slides up and fades in when it changes.
class _RollingNumber extends StatelessWidget {
  const _RollingNumber({
    required this.text,
    required this.style,
    required this.still,
  });

  final String text;
  final TextStyle style;
  final bool still;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSwitcher(
        duration: still ? Duration.zero : const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.centerRight,
          children: [...previous, ?current],
        ),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.6),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: Text(text, key: ValueKey(text), style: style),
      ),
    );
  }
}

/// A soft "live" dot: a solid core with a halo that breathes.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color, required this.still});

  final Color color;
  final bool still;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.still) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingDot old) {
    super.didUpdateWidget(old);
    if (widget.still) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 14,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_pulse.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 8 + 6 * t,
                height: 8 + 6 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.28 * (1 - t)),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
