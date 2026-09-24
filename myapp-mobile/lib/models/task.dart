enum TaskStatus { todo, inProgress, review, done, onHold, cancelled }

extension TaskStatusX on TaskStatus {
  static TaskStatus fromApi(String value) {
    switch (value) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'review':
        return TaskStatus.review;
      case 'done':
        return TaskStatus.done;
      case 'on_hold':
        return TaskStatus.onHold;
      case 'cancelled':
        return TaskStatus.cancelled;
      default:
        return TaskStatus.todo;
    }
  }

  String get apiValue {
    switch (this) {
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.review:
        return 'review';
      case TaskStatus.done:
        return 'done';
      case TaskStatus.onHold:
        return 'on_hold';
      case TaskStatus.cancelled:
        return 'cancelled';
      case TaskStatus.todo:
        return 'todo';
    }
  }

  String get label {
    switch (this) {
      case TaskStatus.inProgress:
        return '進行中';
      case TaskStatus.review:
        return 'レビュー中';
      case TaskStatus.done:
        return '完了';
      case TaskStatus.onHold:
        return '保留';
      case TaskStatus.cancelled:
        return '中止';
      case TaskStatus.todo:
        return '未着手';
    }
  }
}

enum TaskPriority { low, medium, high, urgent }

extension TaskPriorityX on TaskPriority {
  static TaskPriority fromApi(String value) {
    switch (value) {
      case 'low':
        return TaskPriority.low;
      case 'high':
        return TaskPriority.high;
      case 'urgent':
        return TaskPriority.urgent;
      default:
        return TaskPriority.medium;
    }
  }

  String get apiValue => name;

  String get label {
    switch (this) {
      case TaskPriority.low:
        return '低';
      case TaskPriority.medium:
        return '中';
      case TaskPriority.high:
        return '高';
      case TaskPriority.urgent:
        return '緊急';
    }
  }

  /// 並び替え用（大きいほど優先）
  int get rank => index + 1;
}

/// タスク管理のタスク。Web の ToDo（カンバン）と WBS（階層）で同じデータを使う。
class Task {
  final int id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? startDate;
  final DateTime? dueDate;
  final double? durationDays;
  final int progress;
  final int? parentId;
  final int order;
  final List<int> dependencies;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.priority = TaskPriority.medium,
    this.startDate,
    this.dueDate,
    this.durationDays,
    this.progress = 0,
    this.parentId,
    this.order = 0,
    this.dependencies = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isClosed => status == TaskStatus.done || status == TaskStatus.cancelled;

  factory Task.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) {
      final raw = json[key] as String?;
      return raw != null && raw.isNotEmpty ? DateTime.parse(raw) : null;
    }

    final duration = json['duration_days'];
    return Task(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      status: TaskStatusX.fromApi((json['status'] as String?) ?? 'todo'),
      priority: TaskPriorityX.fromApi((json['priority'] as String?) ?? 'medium'),
      startDate: date('start_date'),
      dueDate: date('due_date'),
      durationDays: duration == null ? null : double.tryParse(duration.toString()),
      progress: (json['progress'] as int?) ?? 0,
      parentId: json['parent'] as int?,
      order: (json['order'] as int?) ?? 0,
      dependencies: ((json['dependencies'] as List?) ?? const []).cast<int>(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// 開始日〜終了日（両端含む）の稼働日数。Web と同じく土日を除く。
int countWorkingDays(DateTime start, DateTime end) {
  var count = 0;
  for (var d = DateTime(start.year, start.month, start.day);
      !d.isAfter(end);
      d = DateTime(d.year, d.month, d.day + 1)) {
    if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) count++;
  }
  return count;
}

/// WBS 表示用の1行
class TaskRow {
  final Task task;
  final int level;
  final String wbsNo;
  final bool hasChildren;

  const TaskRow(this.task, this.level, this.wbsNo, this.hasChildren);
}

/// parent を辿ってツリー順に並べる。親が見つからないタスクはトップレベル扱い。
List<TaskRow> buildTaskRows(List<Task> tasks, {Set<int> collapsed = const {}}) {
  final ids = tasks.map((t) => t.id).toSet();
  final children = <int?, List<Task>>{};
  for (final task in tasks) {
    final key = task.parentId != null && ids.contains(task.parentId) ? task.parentId : null;
    children.putIfAbsent(key, () => []).add(task);
  }
  for (final list in children.values) {
    list.sort((a, b) => a.order != b.order ? a.order.compareTo(b.order) : a.id.compareTo(b.id));
  }

  final rows = <TaskRow>[];
  void walk(int? parentId, int level, String prefix) {
    final list = children[parentId] ?? const <Task>[];
    for (var i = 0; i < list.length; i++) {
      final task = list[i];
      final wbsNo = prefix.isEmpty ? '${i + 1}' : '$prefix.${i + 1}';
      final hasChildren = (children[task.id]?.isNotEmpty) ?? false;
      rows.add(TaskRow(task, level, wbsNo, hasChildren));
      if (hasChildren && !collapsed.contains(task.id)) walk(task.id, level + 1, wbsNo);
    }
  }

  walk(null, 0, '');
  return rows;
}

/// 自分自身と子孫のID（親タスクの候補から除外するため）
Set<int> descendantIds(List<Task> tasks, int rootId) {
  final result = {rootId};
  var added = true;
  while (added) {
    added = false;
    for (final task in tasks) {
      if (task.parentId != null && result.contains(task.parentId) && !result.contains(task.id)) {
        result.add(task.id);
        added = true;
      }
    }
  }
  return result;
}
