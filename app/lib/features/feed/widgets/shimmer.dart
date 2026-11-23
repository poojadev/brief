import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';

/// A light band that sweeps across its child. Our own, no package needed.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = BriefColors.of(context).skeleton;
    final highlight = Color.lerp(base, Colors.white, 0.35)!;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) {
          final dx = rect.width * (_c.value * 2 - 0.5);
          return LinearGradient(
            colors: [base, highlight, base],
            stops: const [0.35, 0.5, 0.65],
            transform: _Slide(dx),
          ).createShader(rect);
        },
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _Slide extends GradientTransform {
  const _Slide(this.dx);

  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(dx - bounds.width / 2, 0, 0);
}

/// A rounded placeholder block.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: BriefColors.of(context).skeleton,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// The whole feed, as placeholders: one hero, then a few cards.
class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading stories',
      child: Shimmer(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(height: 300, radius: 20),
              const SizedBox(height: Space.l),
              for (var i = 0; i < 4; i++) ...[
                const Row(
                  children: [
                    SkeletonBox(width: 96, height: 96, radius: 14),
                    SizedBox(width: Space.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 90, height: 10),
                          SizedBox(height: Space.s),
                          SkeletonBox(height: 16),
                          SizedBox(height: Space.xs + 2),
                          SkeletonBox(width: 160, height: 16),
                          SizedBox(height: Space.s),
                          SkeletonBox(width: 70, height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.m),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
