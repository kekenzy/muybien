class Memo {
  final int id;
  final DateTime? date;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Memo({
    required this.id,
    this.date,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 一覧カード先頭に出す日付（カレンダー日付優先、なければ作成日）
  DateTime get displayDate => date ?? createdAt;

  factory Memo.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value);
      }
      return null;
    }

    return Memo(
      id: json['id'] as int,
      date: parseDate(json['date']),
      title: (json['title'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        if (date != null) 'date': _ymd(date!),
        'title': title,
        'content': content,
      };

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
