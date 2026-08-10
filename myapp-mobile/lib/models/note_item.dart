enum NoteKind { memo, diary }

/// Labのメモ / 日記を一覧でまとめて扱う
class NoteItem {
  final NoteKind kind;
  final int id;
  final DateTime date;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteItem({
    required this.kind,
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  String get kindLabel => kind == NoteKind.diary ? '日記' : 'メモ';

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
}
