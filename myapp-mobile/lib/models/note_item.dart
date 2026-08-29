enum NoteKind { memo, diary, task }

/// Labのメモ / 日記 / タスク（期限日あり）を一覧・カレンダーでまとめて扱う
class NoteItem {
  final NoteKind kind;
  final int id;
  final DateTime date;
  final String title;
  final String content;
  final String? status;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteItem({
    required this.kind,
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  String get kindLabel {
    switch (kind) {
      case NoteKind.diary:
        return '日記';
      case NoteKind.task:
        return 'タスク';
      case NoteKind.memo:
        return 'メモ';
    }
  }

  factory NoteItem.fromMemoJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['created_at'] as String);
    final dateRaw = json['date'];
    final date = dateRaw is String && dateRaw.isNotEmpty
        ? DateTime.parse(dateRaw)
        : createdAt;
    return NoteItem(
      kind: NoteKind.memo,
      id: json['id'] as int,
      date: DateTime(date.year, date.month, date.day),
      title: (json['title'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      createdAt: createdAt,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  factory NoteItem.fromDiaryJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['date'] as String);
    return NoteItem(
      kind: NoteKind.diary,
      id: json['id'] as int,
      date: DateTime(date.year, date.month, date.day),
      title: (json['title'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// 期限日（due_date）が設定されているタスクのみをカレンダー表示対象として変換する
  factory NoteItem.fromTaskJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['due_date'] as String);
    return NoteItem(
      kind: NoteKind.task,
      id: json['id'] as int,
      date: DateTime(date.year, date.month, date.day),
      title: (json['title'] as String?) ?? '',
      content: (json['description'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'todo',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
