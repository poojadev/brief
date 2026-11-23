import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';

/// "3 new stories ↑": slides in after a refresh brings new stories.
class NewStoriesPill extends StatelessWidget {
  const NewStoriesPill({super.key, required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = BriefColors.of(context);
    final visible = count > 0;
    final on = Theme.of(context).colorScheme.onPrimary;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, -1.4),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Material(
            color: c.accent,
            elevation: 6,
            shadowColor: c.shadow,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.m,
                    vertical: Space.s,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_upward_rounded,
                        size: 18,
                        color: on,
                      ),
                      const SizedBox(width: Space.s - 2),
                      Text(
                        '$count new ${count == 1 ? 'story' : 'stories'}',
                        style: Theme.of(context).textTheme.labelLarge!
                            .copyWith(color: on, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
