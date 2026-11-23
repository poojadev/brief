import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../data/models/story.dart';

/// Horizontally scrolling categories. The selected chip fills with ink.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48, // full 48 px tap target
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.m),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: Space.s),
        itemBuilder: (context, i) => _Chip(
          label: categoryLabel(categories[i]),
          selected: categories[i] == selected,
          onTap: () => onSelected(categories[i]),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = BriefColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: Space.m,
              vertical: Space.s,
            ),
            decoration: BoxDecoration(
              color: selected ? c.ink : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: selected ? c.ink : c.hairline),
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: selected ? c.paper : c.ink,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
