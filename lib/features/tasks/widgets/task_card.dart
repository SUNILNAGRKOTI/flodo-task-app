import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../data/task_model.dart';
import '../providers/task_provider.dart';

class TaskCard extends ConsumerWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.allTasks,
  });

  final TaskModel task;
  final List<TaskModel> allTasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? AppColors.cardBackgroundDark
        : AppColors.cardBackgroundLight;
    final borderColor = isDark
        ? Colors.white.withAlpha((255 * 0.15).round())
        : Colors.black.withAlpha((255 * 0.08).round());
    final descriptionColor = isDark
        ? Colors.white.withAlpha((255 * 0.65).round())
        : Colors.black.withAlpha((255 * 0.55).round());
    final captionColor = isDark
        ? Colors.white.withAlpha((255 * 0.55).round())
        : Colors.black.withAlpha((255 * 0.45).round());

    TaskModel? blocker;
    if (task.blockedById != null) {
      for (final t in allTasks) {
        if (t.id == task.blockedById) {
          blocker = t;
          break;
        }
      }
    }

    final blockerTitle = blocker?.title;
    final isBlocked = blocker != null && blocker.status != TaskStatus.done;

    final accentColor = task.status.color;
    final dueLabel = DateFormat('MMM dd, yyyy').format(task.dueDate);

    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white.withAlpha(230)
                                : Colors.black.withAlpha(230),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _statusPill(context, task.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (task.description.isNotEmpty)
                    Text(
                      task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: descriptionColor,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: captionColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dueLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: captionColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isBlocked) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Blocked by: ${blockerTitle ?? 'Unknown'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusBlocked,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Opacity(
      opacity: isBlocked ? 0.45 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/form', extra: task),
        onLongPress: () async {
          showDialog<void>(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: const Text('Delete task?'),
                content: const Text('This action cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await ref.read(taskRepositoryProvider).deleteTask(task.id);
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            },
          );
        },
        child: Stack(
          children: [
            card,
            if (isBlocked)
              Positioned(
                top: 8,
                right: 10,
                child: Icon(
                  Icons.lock_outline,
                  color: AppColors.statusBlocked,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(BuildContext context, TaskStatus status) {
    final bg = switch (status) {
      TaskStatus.todo => AppColors.statusToDo.withAlpha((255 * 0.12).round()),
      TaskStatus.inProgress => AppColors.statusInProgress
          .withAlpha((255 * 0.12).round()),
      TaskStatus.done => AppColors.statusDone.withAlpha((255 * 0.12).round()),
    };

    final fg = switch (status) {
      TaskStatus.todo => AppColors.statusToDo,
      TaskStatus.inProgress => const Color(0xFFB45309),
      TaskStatus.done => const Color(0xFF047857),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
          height: 1.1,
        ),
      ),
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../data/task_model.dart';
import '../providers/task_provider.dart';

class TaskCard extends ConsumerWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.allTasks,
  });

  final TaskModel task;
  final List<TaskModel> allTasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? AppColors.cardBackgroundDark
        : AppColors.cardBackgroundLight;
    final borderColor = isDark
        ? Colors.white.withAlpha((255 * 0.15).round())
        : Colors.black.withAlpha((255 * 0.08).round());
    final descriptionColor = isDark
        ? Colors.white.withAlpha((255 * 0.65).round())
        : Colors.black.withAlpha((255 * 0.55).round());
    final captionColor = isDark
        ? Colors.white.withAlpha((255 * 0.55).round())
        : Colors.black.withAlpha((255 * 0.45).round());

    TaskModel? blocker;
    if (task.blockedById != null) {
      for (final t in allTasks) {
        if (t.id == task.blockedById) {
          blocker = t;
          break;
        }
      }
    }
    final blockerTitle = blocker?.title;
    final isBlocked = blocker != null && blocker!.status != TaskStatus.done;

    final accentColor = task.status.color;
    final dueLabel = DateFormat('MMM dd, yyyy').format(task.dueDate);

    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left colored accent border
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white.withAlpha(230)
                                : Colors.black.withAlpha(230),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _statusPill(context, task.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (task.description.isNotEmpty)
                    Text(
                      task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: descriptionColor,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: captionColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dueLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: captionColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isBlocked) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Blocked by: ${blockerTitle ?? 'Unknown'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusBlocked,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Opacity(
      opacity: isBlocked ? 0.45 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/form', extra: task),
        onLongPress: () async {
          showDialog<void>(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: const Text('Delete task?'),
                content: const Text('This action cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await ref.read(taskRepositoryProvider).deleteTask(task.id);
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            },
          );
        },
        child: Stack(
          children: [
            card,
            if (isBlocked)
              Positioned(
                top: 8,
                right: 10,
                child: Icon(
                  Icons.lock_outline,
                  color: AppColors.statusBlocked,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(BuildContext context, TaskStatus status) {
    final bg = switch (status) {
      TaskStatus.todo => AppColors.statusToDo.withAlpha((255 * 0.12).round()),
      TaskStatus.inProgress => AppColors.statusInProgress.withAlpha(
          (255 * 0.12).round()),
      TaskStatus.done =>
        AppColors.statusDone.withAlpha((255 * 0.12).round()),
    };

    final fg = switch (status) {
      TaskStatus.todo => AppColors.statusToDo,
      TaskStatus.inProgress => const Color(0xFFB45309),
      TaskStatus.done => const Color(0xFF047857),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
          height: 1.1,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../data/task_model.dart';
import '../providers/task_provider.dart';

class TaskCard extends ConsumerWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.allTasks,
  });

  final TaskModel task;
  final List<TaskModel> allTasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? AppColors.cardBackgroundDark
        : AppColors.cardBackgroundLight;
    final borderColor = isDark
        ? Colors.white.withAlpha((255 * 0.15).round())
        : Colors.black.withAlpha((255 * 0.08).round());
    final descriptionColor = isDark
        ? Colors.white.withAlpha((255 * 0.65).round())
        : Colors.black.withAlpha((255 * 0.55).round());
    final captionColor = isDark
        ? Colors.white.withAlpha((255 * 0.55).round())
        : Colors.black.withAlpha((255 * 0.45).round());

    TaskModel? blocker;
    if (task.blockedById != null) {
      for (final t in allTasks) {
        if (t.id == task.blockedById) {
          blocker = t;
          break;
        }
      }
    }

    final blockerTitle = blocker?.title;
    final isBlocked = blocker != null && blocker.status != TaskStatus.done;

    final accentColor = task.status.color;
    final dueLabel = DateFormat('MMM dd, yyyy').format(task.dueDate);

    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left colored accent border
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white.withAlpha(230)
                                : Colors.black.withAlpha(230),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _statusPill(context, task.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (task.description.isNotEmpty)
                    Text(
                      task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: descriptionColor,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: captionColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dueLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: captionColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isBlocked) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Blocked by: ${blockerTitle ?? 'Unknown'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusBlocked,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Opacity(
      opacity: isBlocked ? 0.45 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/form', extra: task),
        onLongPress: () async {
          showDialog<void>(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: const Text('Delete task?'),
                content: const Text('This action cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await ref.read(taskRepositoryProvider).deleteTask(task.id);
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            },
          );
        },
        child: Stack(
          children: [
            card,
            if (isBlocked)
              Positioned(
                top: 8,
                right: 10,
                child: Icon(
                  Icons.lock_outline,
                  color: AppColors.statusBlocked,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(BuildContext context, TaskStatus status) {
    final bg = switch (status) {
      TaskStatus.todo => AppColors.statusToDo.withAlpha((255 * 0.12).round()),
      TaskStatus.inProgress =>
        AppColors.statusInProgress.withAlpha((255 * 0.12).round()),
      TaskStatus.done => AppColors.statusDone.withAlpha((255 * 0.12).round()),
    };

    final fg = switch (status) {
      TaskStatus.todo => AppColors.statusToDo,
      TaskStatus.inProgress => const Color(0xFFB45309),
      TaskStatus.done => const Color(0xFF047857),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
          height: 1.1,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../data/task_model.dart';
import '../providers/task_provider.dart';

class TaskCard extends ConsumerWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.index,
    this.isDraggable = false,
    this.isBlocked = false,
    this.blockerTitle,
  });

  final TaskModel task;
  final int index;
  final bool isDraggable;
  final bool isBlocked;
  final String? blockerTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? AppColors.cardBackgroundDark
        : AppColors.cardBackgroundLight;
    final borderColor = isDark
        ? Colors.white.withAlpha((255 * 0.15).round())
        : Colors.black.withAlpha((255 * 0.08).round());
    final descriptionColor = isDark
        ? Colors.white.withAlpha((255 * 0.65).round())
        : Colors.black.withAlpha((255 * 0.55).round());
    final captionColor = isDark
        ? Colors.white.withAlpha((255 * 0.55).round())
        : Colors.black.withAlpha((255 * 0.45).round());

    final accentColor = task.status.color;
    final dueLabel = DateFormat('MMM dd, yyyy').format(task.dueDate);

    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        // In a vertical `ListView`, item height is unbounded during layout.
        // Using `stretch` on the cross-axis forces an infinite height constraint.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left colored accent border
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white.withAlpha(230)
                                : Colors.black.withAlpha(230),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _statusPill(context, task.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (task.description.isNotEmpty)
                    Text(
                      task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: descriptionColor,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: captionColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dueLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: captionColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isDraggable)
                        ReorderableDragStartListener(
                          index: index,
                          child: Icon(
                            Icons.drag_handle,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  if (isBlocked) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Blocked by: ${blockerTitle ?? 'Unknown'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusBlocked,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Opacity(
      opacity: isBlocked ? 0.45 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/form', extra: task),
        onLongPress: () async {
          showDialog<void>(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: const Text('Delete task?'),
                content: const Text('This action cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await ref.read(taskRepositoryProvider).deleteTask(task.id);
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            },
          );
        },
        child: Stack(
          children: [
            card,
            if (isBlocked)
              Positioned(
                top: 8,
                right: 10,
                child: Icon(
                  Icons.lock_outline,
                  color: AppColors.statusBlocked,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(BuildContext context, TaskStatus status) {
    final bg = switch (status) {
      TaskStatus.todo => AppColors.statusToDo.withAlpha((255 * 0.12).round()),
      TaskStatus.inProgress => AppColors.statusInProgress
          .withAlpha((255 * 0.12).round()),
      TaskStatus.done => AppColors.statusDone.withAlpha((255 * 0.12).round()),
    };

    final fg = switch (status) {
      TaskStatus.todo => AppColors.statusToDo,
      TaskStatus.inProgress => const Color(0xFFB45309),
      TaskStatus.done => const Color(0xFF047857),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
          height: 1.1,
        ),
      ),
    );
  }

  // Date formatting is handled via intl in build() (no local helper needed).
}
*/

