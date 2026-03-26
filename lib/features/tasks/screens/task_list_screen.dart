import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../data/task_model.dart';
import '../providers/task_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_card.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounceTimer;
  String _lastControllerText = '';

  @override
  void initState() {
    super.initState();
    _lastControllerText = _searchController.text.trim();
    _searchController.addListener(_handleSearchControllerChanged);
  }

  void _handleSearchControllerChanged() {
    // BUG 1 fix: only update when the user changes actual text.
    final text = _searchController.text.trim();
    if (text == _lastControllerText) return;
    _lastControllerText = text;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = text;
      });
    });
  }

  List<TaskModel> _getFilteredTasks(List<TaskModel> allTasks) {
    // IMPORTANT: if search is empty AND filter is All, show everything.
    if (_searchQuery.isEmpty && _selectedFilter == 'All') {
      return allTasks;
    }

    final hasSearch = _searchQuery.isNotEmpty;

    return allTasks.where((task) {
      final matchesSearch = !hasSearch ||
          task.title.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = _selectedFilter == 'All' ||
          (_selectedFilter == 'To-Do' && task.status == TaskStatus.todo) ||
          (_selectedFilter == 'In Progress' &&
              task.status == TaskStatus.inProgress) ||
          (_selectedFilter == 'Done' && task.status == TaskStatus.done);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_handleSearchControllerChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final tasksAsync = ref.watch(tasksStreamProvider);

    final effectiveBrightness = themeMode == ThemeMode.system
        ? Theme.of(context).brightness
        : themeMode == ThemeMode.dark
            ? Brightness.dark
            : Brightness.light;
    final isDark = effectiveBrightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Flodo',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: () {
              ref.read(themeModeProvider.notifier).state =
                  isDark ? ThemeMode.light : ThemeMode.dark;
            },
            icon: Icon(
              isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/form'),
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Failed to load tasks: $err'),
          ),
        ),
        data: (tasks) {
          final allTasks = [...tasks]
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          final filteredTasks = _getFilteredTasks(allTasks);

          final canReorder = _searchQuery.isEmpty && _selectedFilter == 'All';
          final Widget emptyWidget;
          if (filteredTasks.isEmpty) {
            if (_searchQuery.isEmpty && _selectedFilter == 'All') {
              emptyWidget = const EmptyState(
                title: 'No tasks yet',
                subtitle: 'Create your first task to get started.',
                icon: Icons.task_alt_outlined,
              );
            } else {
              emptyWidget = Center(
                child: Text(
                  'No results found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                ),
              );
            }
          } else {
            emptyWidget = const SizedBox.shrink();
          }

          Widget listWidget;
          if (canReorder) {
            listWidget = ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTasks.length,
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) async {
                final repo = ref.read(taskRepositoryProvider);

                final reordered = List<TaskModel>.from(filteredTasks);
                final item = reordered.removeAt(oldIndex);
                final adjustedNewIndex =
                    newIndex > oldIndex ? newIndex - 1 : newIndex;
                reordered.insert(adjustedNewIndex, item);

                for (var i = 0; i < reordered.length; i++) {
                  reordered[i] = reordered[i].copyWith(sortOrder: i);
                }

                await repo.persistAllTasks(reordered);
              },
              itemBuilder: (context, index) {
                final task = filteredTasks[index];

                return ListTile(
                  key: ValueKey(task.id),
                  contentPadding: EdgeInsets.zero,
                  title: TaskCard(task: task, allTasks: allTasks),
                  trailing: ReorderableDragStartListener(
                    index: index,
                    child: const Icon(
                      Icons.drag_handle,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
                );
              },
            );
          } else {
            listWidget = ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                return ListTile(
                  key: ValueKey(task.id),
                  contentPadding: EdgeInsets.zero,
                  title: TaskCard(task: task, allTasks: allTasks),
                );
              },
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tasks',
                    prefixIcon: const Icon(Icons.search_outlined),
                    suffixIcon: _searchController.text.trim().isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _debounceTimer?.cancel();
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _lastControllerText = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.only(top: 12, left: 8, right: 8),
                child: _buildFilterChips(),
              ),
              Expanded(child: filteredTasks.isEmpty ? emptyWidget : listWidget),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    const chips = <String>['All', 'To-Do', 'In Progress', 'Done'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((chip) {
          final selected = _selectedFilter == chip;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ChoiceChip(
              label: Text(chip),
              selected: selected,
              selectedColor: AppColors.primary,
              backgroundColor: Colors.transparent,
              side: BorderSide(
                color: selected
                    ? Colors.transparent
                    : Colors.grey.withAlpha((255 * 0.35).round()),
              ),
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.grey.withAlpha(230),
              ),
              onSelected: (_) {
                setState(() {
                  _selectedFilter = chip;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

