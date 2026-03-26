import 'dart:async';
import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import 'task_model.dart';

class TaskRepository {
  const TaskRepository();

  static const String _lastIdKey = 'lastId';

  Box<TaskModel> get _tasksBox => Hive.box<TaskModel>(tasksBoxName);
  Box<int> get _metaBox => Hive.box<int>(taskMetaBoxName);

  int _nextId() {
    final lastId = _metaBox.get(_lastIdKey, defaultValue: 0) ?? 0;
    final next = lastId + 1;
    _metaBox.put(_lastIdKey, next);
    return next;
  }

  List<TaskModel> _sorted(Iterable<TaskModel> items) {
    final list = items.toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  /// Watches all tasks as a stream.
  Stream<List<TaskModel>> watchAllTasks() async* {
    yield _sorted(_tasksBox.values);
    await for (final _ in _tasksBox.watch()) {
      yield _sorted(_tasksBox.values);
    }
  }

  Future<List<TaskModel>> getAllTasks() async {
    return _sorted(_tasksBox.values);
  }

  Future<void> createTask(TaskModel task) async {
    final id = task.id != 0 ? task.id : _nextId();
    final toPut = task.id == id ? task : task.copyWith(id: id);

    await _tasksBox.put(id, toPut);
  }

  Future<void> updateTask(TaskModel task) async {
    if (task.id == 0) {
      throw ArgumentError('updateTask requires task.id != 0');
    }
    await _tasksBox.put(task.id, task);
  }

  Future<void> deleteTask(int id) async {
    await _tasksBox.delete(id);
  }

  /// Persist multiple tasks at once (used for drag-and-drop reordering).
  /// Intentionally does NOT simulate delay, unlike [updateTask].
  Future<void> persistAllTasks(List<TaskModel> tasks) async {
    await Future.wait(tasks.map((t) {
      if (t.id == 0) {
        throw ArgumentError('persistAllTasks requires task.id != 0');
      }
      return _tasksBox.put(t.id, t);
    }));
  }

  // -------------------------
  // Draft persistence (prefs)
  // -------------------------

  Future<void> saveDraft(TaskDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.taskDraftStorageKey,
      jsonEncode(draft.toJson()),
    );
  }

  Future<TaskDraft?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.taskDraftStorageKey);
    if (raw == null) return null;

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return TaskDraft.fromJson(decoded);
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.taskDraftStorageKey);
  }
}

