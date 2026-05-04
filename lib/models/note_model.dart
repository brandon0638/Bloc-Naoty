class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int backgroundColor;
  final int textColor;
  final bool isPinned;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.backgroundColor = 0xFFFFFFFF,
    this.textColor = 0xFF000000,
    this.isPinned = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'isPinned': isPinned,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      backgroundColor: json['backgroundColor'],
      textColor: json['textColor'],
      isPinned: json['isPinned'],
    );
  }
}