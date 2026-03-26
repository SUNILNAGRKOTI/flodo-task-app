import 'package:flutter/material.dart';

import '../data/task_model.dart';
import '../../../core/theme/colors.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    this.isBlocked = false,
  });

  final TaskStatus status;
  final bool isBlocked;

  @override
  Widget build(BuildContext context) {
    final chipColor = isBlocked ? AppColors.statusBlocked : status.color;
    final chipLabel = isBlocked ? 'Blocked' : status.label;

    return Chip(
      label: Text(
        chipLabel,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w600,
            ),
      ),
      backgroundColor: chipColor.withAlpha((255 * 0.12).round()),
      side: BorderSide(
        color: chipColor.withAlpha((255 * 0.35).round()),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    );
  }
}

