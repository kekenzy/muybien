enum TaskStatus { todo, inProgress, done }

extension TaskStatusX on TaskStatus {
  static TaskStatus fromApi(String value) {
    switch (value) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      default:
        return TaskStatus.todo;
    }
  }

  String get apiValue {
    switch (this) {
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.done:
        return 'done';
      case TaskStatus.todo:
        return 'todo';
    }
  }

  String get label {
    switch (this) {
      case TaskStatus.inProgress:
        return '進行中';
      case TaskStatus.done:
        return '完了';
      case TaskStatus.todo:
        return '未着手';
    }
  }
}

class Task {
  final int id;
  final String title;
  final String description;
  final TaskStatus status;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    final dueRaw = json['due_date'] as String?;
    return Task(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      status: TaskStatusX.fromApi((json['status'] as String?) ?? 'todo'),
      dueDate: dueRaw != null && dueRaw.isNotEmpty ? DateTime.parse(dueRaw) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
