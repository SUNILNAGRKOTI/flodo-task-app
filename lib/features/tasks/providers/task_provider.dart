import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/task_model.dart';
import '../data/task_repository.dart';

/// Primary repository provider (Hive + simulated delays).
final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => const TaskRepository(),
);

/// Watches all tasks as a stream.
final tasksStreamProvider = StreamProvider<List<TaskModel>>(
  (ref) => ref.watch(taskRepositoryProvider).watchAllTasks(),
);

/// Simple loading flag for UI actions.
final taskLoadingProvider = StateProvider<bool>((ref) => false);

// UI state for search + filter chips.
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedFilterProvider = StateProvider<String>((ref) => 'All');

final taskDraftProvider = NotifierProvider<TaskDraftController, TaskDraftState>(
  TaskDraftController.new,
);

class TaskDraftState {
  TaskDraftState({
    TaskDraft? draft,
    this.isLoading = false,
    this.errorMessage,
  }) : draft = draft ?? TaskDraft();

  final TaskDraft draft;
  final bool isLoading;
  final String? errorMessage;

  TaskDraftState copyWith({
    TaskDraft? draft,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TaskDraftState(
      draft: draft ?? this.draft,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class TaskDraftController extends Notifier<TaskDraftState> {
  TaskDraftController();

  late final TaskRepository _repository;

  @override
  TaskDraftState build() {
    _repository = ref.read(taskRepositoryProvider);
    return TaskDraftState();
  }

  Future<TaskDraft?> loadDraft() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final loaded = await _repository.loadDraft();
      state = state.copyWith(
        isLoading: false,
        draft: loaded ?? TaskDraft(),
      );
      return loaded;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  void setTitle(String value) {
    state = state.copyWith(draft: state.draft.copyWith(title: value));
  }

  void setDescription(String value) {
    state = state.copyWith(draft: state.draft.copyWith(description: value));
  }

  void setStatus(TaskStatus value) {
    state = state.copyWith(draft: state.draft.copyWith(status: value));
  }

  void setDueDate(DateTime value) {
    state = state.copyWith(draft: state.draft.copyWith(dueDate: value));
  }

  void setBlockedById(int? value) {
    state =
        state.copyWith(draft: state.draft.copyWith(blockedById: value));
  }

  Future<void> saveDraft() async {
    await _repository.saveDraft(state.draft);
  }

  Future<void> clearDraft() async {
    await _repository.clearDraft();
    state = state.copyWith(draft: TaskDraft());
  }
}

