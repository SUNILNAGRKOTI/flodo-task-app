import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../data/task_model.dart';
import '../providers/task_provider.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key, this.task});

  final TaskModel? task;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen>
    with WidgetsBindingObserver {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late TextInputType _titleInputType;

  late DateTime _dueDate;
  late TaskStatus _status;
  int? _blockedById;

  bool _submitting = false;
  bool _draftCleared = false;
  bool _isDirty = false;
  bool _handlingPop = false;
  late final TaskDraftController _draftController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _titleInputType = TextInputType.text;

    _draftController = ref.read(taskDraftProvider.notifier);
    _initFromTaskAndDraft();
  }

  Future<void> _initFromTaskAndDraft() async {
    final isEdit = widget.task != null;

    if (isEdit) {
      final t = widget.task!;
      _titleController.text = t.title;
      _descriptionController.text = t.description;
      _dueDate = t.dueDate;
      _status = t.status;
      _blockedById = t.blockedById;
    } else {
      _titleController.text = '';
      _descriptionController.text = '';
      _dueDate = DateTime.now();
      _status = TaskStatus.todo;
      _blockedById = null;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final restored = !isEdit ? await _draftController.loadDraft() : null;

      if (!mounted) return;

      if (!isEdit && restored != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft restored')),
        );

        _titleController.text = restored.title;
        _descriptionController.text = restored.description;
        _dueDate = restored.dueDate;
        _status = restored.status;
        _blockedById = restored.blockedById;
      }

      _draftController.setDueDate(_dueDate);
      _draftController.setStatus(_status);
      _draftController.setBlockedById(_blockedById);
      _draftController.setTitle(_titleController.text);
      _draftController.setDescription(_descriptionController.text);
      setState(() {
        _isDirty = false;
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_draftController.saveDraft());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_draftController.saveDraft());
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.task != null;
    final tasksAsync = ref.watch(tasksStreamProvider);
    final notifier = ref.read(taskDraftProvider.notifier);

    final appBarTitle = Text(isEdit ? 'Edit Task' : 'New Task');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (_draftCleared || _handlingPop) return;
        unawaited(_handleBackRequest());
      },
      child: Scaffold(
        appBar: AppBar(
          title: appBarTitle,
          leading: IconButton(
            tooltip: 'Back (saves draft)',
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () async {
              await _handleBackRequest();
            },
          ),
        ),
        body: SafeArea(
          child: tasksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load tasks: $err'),
              ),
            ),
            data: (tasks) {
              // Build blocked by options
              final blockedOptions = <DropdownMenuItem<int?>>[];
              blockedOptions.add(
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('None'),
                ),
              );

              for (final t in tasks) {
                if (widget.task != null && t.id == widget.task!.id) {
                  continue;
                }
                blockedOptions.add(
                  DropdownMenuItem<int?>(
                    value: t.id,
                    child: Text(t.title),
                  ),
                );
              }

              // FIX: make sure _blockedById value exists in options
              // If not found in list, reset to null to avoid crash
              final safeBlockedById = blockedOptions
                  .any((item) => item.value == _blockedById)
                  ? _blockedById
                  : null;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    TextField(
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      keyboardType: _titleInputType,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                        hintText: 'Task title',
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      onChanged: (value) async {
                        setState(() => _isDirty = true);
                        notifier.setTitle(value);
                        unawaited(notifier.saveDraft());
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextField(
                      controller: _descriptionController,
                      minLines: 3,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                      onChanged: (value) async {
                        setState(() => _isDirty = true);
                        notifier.setDescription(value);
                        unawaited(notifier.saveDraft());
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),

                    // Due date
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickDueDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _formatDate(_dueDate),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Status
                    DropdownButtonFormField<TaskStatus>(
                      value: _status,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Status',
                      ),
                      items: TaskStatus.values.map((s) {
                        return DropdownMenuItem<TaskStatus>(
                          value: s,
                          child: Row(
                            children: [
                              _statusDot(s),
                              const SizedBox(width: 10),
                              Text(s.label),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _status = value;
                          _isDirty = true;
                        });
                        notifier.setStatus(value);
                        unawaited(notifier.saveDraft());
                      },
                    ),
                    const SizedBox(height: 12),

                    // Blocked By — uses safeBlockedById to prevent crash
                    DropdownButtonFormField<int?>(
                      value: safeBlockedById,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Blocked By',
                      ),
                      items: blockedOptions,
                      onChanged: (value) {
                        setState(() {
                          _blockedById = value;
                          _isDirty = true;
                        });
                        notifier.setBlockedById(value);
                        unawaited(notifier.saveDraft());
                      },
                    ),
                    const SizedBox(height: 20),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _submitting
                            ? null
                            : () async {
                          final title =
                          _titleController.text.trim();
                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text('Title is required'),
                              ),
                            );
                            return;
                          }

                          setState(() => _submitting = true);
                          try {
                            await Future.delayed(
                              const Duration(seconds: 2),
                            );

                            final repo =
                            ref.read(taskRepositoryProvider);

                            if (widget.task == null) {
                              final all = await repo.getAllTasks();
                              final nextSortOrder = all.isEmpty
                                  ? 0
                                  : all
                                  .map((t) => t.sortOrder)
                                  .reduce((a, b) =>
                              a > b ? a : b) +
                                  1;

                              final newTask = TaskModel(
                                title: _titleController.text
                                    .trim(),
                                description: _descriptionController
                                    .text
                                    .trim(),
                                dueDate: _dueDate,
                                status: _status,
                                blockedById: _blockedById,
                                sortOrder: nextSortOrder,
                                createdAt: DateTime.now(),
                              );

                              await repo.createTask(newTask);
                            } else {
                              final updated =
                              widget.task!.copyWith(
                                title: _titleController.text
                                    .trim(),
                                description: _descriptionController
                                    .text
                                    .trim(),
                                dueDate: _dueDate,
                                status: _status,
                                blockedById: _blockedById,
                                sortOrder: widget.task!.sortOrder,
                                createdAt: widget.task!.createdAt,
                              );
                              await repo.updateTask(updated);
                            }

                            await notifier.clearDraft();
                            _draftCleared = true;
                            _isDirty = false;

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  widget.task == null
                                      ? 'Task created'
                                      : 'Task updated',
                                ),
                              ),
                            );
                            context.pop();
                          } finally {
                            if (mounted) {
                              setState(
                                      () => _submitting = false);
                            }
                          }
                        },
                        child: _submitting
                            ? const Center(
                          child: SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                              AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        )
                            : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleBackRequest() async {
    if (!mounted) return;
    if (_draftCleared) return;
    if (_handlingPop) return;

    if (!_isDirty) {
      unawaited(_draftController.saveDraft());
      if (!mounted) return;
      _handlingPop = true;
      Navigator.of(context).pop();
      return;
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('Your draft will be saved.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Discard',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDiscard == true) {
      unawaited(_draftController.saveDraft());
      if (!mounted) return;
      _handlingPop = true;
      Navigator.of(context).pop();
    }
  }

  Widget _statusDot(TaskStatus status) {
    final color = status.color;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() {
      _dueDate = picked;
      _isDirty = true;
    });
    ref.read(taskDraftProvider.notifier).setDueDate(picked);
    unawaited(ref.read(taskDraftProvider.notifier).saveDraft());
  }

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}