import 'package:flutter/material.dart';

import '../../ui/colors.dart';
import '../../ui/radii.dart';
import '../../ui/spacing.dart';

/// A single entry in the settings navigation.
class PhotonSettingsItem {
  const PhotonSettingsItem({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

/// The settings navigation panel.
///
/// On wide layouts it renders as a vertical sidebar of category tiles;
/// on mobile it collapses to a horizontally scrolling chip strip. Either
/// way it reports the selected index back through [onSelected].
class PhotonSettingsPanel extends StatelessWidget {
  const PhotonSettingsPanel({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
    this.horizontal = false,
  });

  final List<PhotonSettingsItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    if (horizontal) {
      return SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, i) => _Chip(
            item: items[i],
            selected: i == selectedIndex,
            onTap: () => onSelected(i),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, i) => _Tile(
        item: items[i],
        selected: i == selectedIndex,
        onTap: () => onSelected(i),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(
      {required this.item, required this.selected, required this.onTap,});

  final PhotonSettingsItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: AppRadii.mdRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 20, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  item.label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: selected ? theme.colorScheme.onSurface : color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.item, required this.selected, required this.onTap,});

  final PhotonSettingsItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.14)
          : AppColors.darkSurfaceElevated,
      borderRadius: AppRadii.pillRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 16, color: color),
              const SizedBox(width: AppSpacing.xs),
              Text(
                item.label,
                style: theme.textTheme.labelLarge?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
