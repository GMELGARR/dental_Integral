import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/odontogram.dart';
import 'tooth_widget.dart';

/// Horizontal scrollable palette to select a tooth condition.
class ConditionPalette extends StatelessWidget {
  const ConditionPalette({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ToothCondition selected;
  final ValueChanged<ToothCondition> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ToothCondition.values.map((condition) {
            final isSelected = condition == selected;
            final color = conditionColor(condition);
            final displayColor =
                condition == ToothCondition.sano
                    ? (isDark ? Colors.white60 : Colors.black38)
                    : color;

            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => onSelected(condition),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? displayColor.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: AppSpacing.borderRadiusLg,
                    border: Border.all(
                      color: isSelected
                          ? displayColor
                          : (isDark ? Colors.white12 : Colors.black12),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Colors.white30 : Colors.black26,
                          ),
                        ),
                        child: condition == ToothCondition.extraccion
                            ? const Icon(Icons.close, size: 10, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        condition.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? displayColor
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
