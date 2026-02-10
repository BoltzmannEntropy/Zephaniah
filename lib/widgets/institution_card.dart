import 'package:flutter/material.dart';
import '../models/models.dart';

class InstitutionCard extends StatelessWidget {
  final Institution institution;
  final bool isSelected;
  final VoidCallback onTap;

  const InstitutionCard({
    super.key,
    required this.institution,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: isSelected
          ? institution.color.withValues(alpha: 0.15)
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? institution.color
              : theme.colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: institution.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      institution.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? institution.color
                            : theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: institution.color,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                institution.urlPattern,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InstitutionCardsGrid extends StatelessWidget {
  final List<Institution> institutions;
  final Set<String> selectedIds;
  final void Function(Institution) onToggle;
  final String? filterCategory;

  const InstitutionCardsGrid({
    super.key,
    required this.institutions,
    required this.selectedIds,
    required this.onToggle,
    this.filterCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = filterCategory != null
        ? institutions.where((i) => i.category == filterCategory).toList()
        : institutions;

    // Group by category
    final grouped = <String, List<Institution>>{};
    for (final inst in filtered) {
      grouped.putIfAbsent(inst.category, () => []).add(inst);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((entry) {
        final category = entry.key;
        final items = entry.value;
        final categoryColor = items.first.color;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: categoryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${items.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: categoryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Institution cards
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((inst) {
                return SizedBox(
                  width: 180,
                  child: InstitutionCard(
                    institution: inst,
                    isSelected: selectedIds.contains(inst.id),
                    onTap: () => onToggle(inst),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }
}
