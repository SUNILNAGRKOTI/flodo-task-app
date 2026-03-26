import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../core/theme/colors.dart';

enum TaskStatus {
  todo,
  inProgress,
  done,
}

extension TaskStatusX on TaskStatus {
  String get label {
    return switch (this) {
      TaskStatus.todo => 'To-Do',
      TaskStatus.inProgress => 'In Progress',
      TaskStatus.done => 'Done',
    };
  }

  Color get color {
    return switch (this) {
      TaskStatus.todo => AppColors.statusToDo,
      TaskStatus.inProgress => AppColors.statusInProgress,
      TaskStatus.done => AppColors.statusDone,
    };
  }
}

/// App domain model persisted in Hive.
class TaskModel {
  const TaskModel({
    this.id = 0,
    required this.title,
    required this.description,
    required this.dueDate,
    this.status = TaskStatus.todo,
    this.blockedById,
    this.sortOrder = 0,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskStatus status;
  final int? blockedById;
  final int sortOrder;
  final DateTime createdAt;

  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    int? blockedById,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      blockedById: blockedById ?? this.blockedById,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class TaskDraft {
  TaskDraft({
    this.title = '',
    this.description = '',
    DateTime? dueDate,
    this.status = TaskStatus.todo,
    this.blockedById,
    this.sortOrder = 0,
    DateTime? createdAt,
  })  : dueDate = dueDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  final String title;
  final String description;
  final DateTime dueDate;
  final TaskStatus status;
  final int? blockedById;
  final int sortOrder;
  final DateTime createdAt;

  TaskDraft copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    int? blockedById,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return TaskDraft(
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      blockedById: blockedById ?? this.blockedById,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'blockedById': blockedById,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static TaskDraft fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] as String?) ?? TaskStatus.todo.name;
    return TaskDraft(
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      dueDate: DateTime.tryParse(json['dueDate'] as String? ?? '') ??
          DateTime.now(),
      status: switch (rawStatus) {
        'todo' => TaskStatus.todo,
        'inProgress' => TaskStatus.inProgress,
        'done' => TaskStatus.done,
        _ => TaskStatus.todo,
      },
      blockedById: json['blockedById'] as int?,
      sortOrder: (json['sortOrder'] as int?) ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

// -------------------------
// Hive schema (adapter)
// -------------------------

const String tasksBoxName = 'tasks';
const String taskMetaBoxName = 'task_meta';

/// We implement a manual adapter so we don't rely on code generation.
class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 1;

  @override
  TaskModel read(BinaryReader reader) {
    final id = reader.readInt();
    final title = reader.readString();
    final description = reader.readString();
    final dueDate = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final statusIndex = reader.readInt();
    final blockedRaw = reader.readInt();
    final blockedById = blockedRaw < 0 ? null : blockedRaw;
    final sortOrder = reader.readInt();
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(reader.readInt());

    final statusValues = TaskStatus.values;
    final status = statusIndex >= 0 && statusIndex < statusValues.length
        ? statusValues[statusIndex]
        : TaskStatus.todo;

    return TaskModel(
      id: id,
      title: title,
      description: description,
      dueDate: dueDate,
      status: status,
      blockedById: blockedById,
      sortOrder: sortOrder,
      createdAt: createdAt,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.description);
    writer.writeInt(obj.dueDate.millisecondsSinceEpoch);
    writer.writeInt(obj.status.index);
    writer.writeInt(obj.blockedById ?? -1); // -1 => null
    writer.writeInt(obj.sortOrder);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}
