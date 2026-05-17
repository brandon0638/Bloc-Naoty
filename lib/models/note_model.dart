class Note {
  final String id;
  final String title;
  final String content;  // Contenu HTML pour formatage
  final DateTime createdAt;
  final DateTime updatedAt;
  final int backgroundColor;
  final int textColor;
  final bool isPinned;
  final bool isArchived;
  final bool isFavorite;
  final List<String> tags;
  final String? folderId;
  final String? imagePath;      // Image de fond personnalisée
  final List<String> attachments; // Images, audios, fichiers
  final String? reminderDate;    // Date de rappel
  final bool isLocked;           // Note privée
  final String? fontFamily;      // Police personnalisée
  final double fontSize;         // Taille du texte

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.backgroundColor = 0xFFFFFFFF,
    this.textColor = 0xFF000000,
    this.isPinned = false,
    this.isArchived = false,
    this.isFavorite = false,
    this.tags = const [],
    this.folderId,
    this.imagePath,
    this.attachments = const [],
    this.reminderDate,
    this.isLocked = false,
    this.fontFamily,
    this.fontSize = 16.0,
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
      'isArchived': isArchived,
      'isFavorite': isFavorite,
      'tags': tags,
      'folderId': folderId,
      'imagePath': imagePath,
      'attachments': attachments,
      'reminderDate': reminderDate,
      'isLocked': isLocked,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
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
      isPinned: json['isPinned'] ?? false,
      isArchived: json['isArchived'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      folderId: json['folderId'],
      imagePath: json['imagePath'],
      attachments: List<String>.from(json['attachments'] ?? []),
      reminderDate: json['reminderDate'],
      isLocked: json['isLocked'] ?? false,
      fontFamily: json['fontFamily'],
      fontSize: json['fontSize']?.toDouble() ?? 16.0,
    );
  }
}

class Folder {
  final String id;
  final String name;
  final int color;
  final int icon;

  Folder({
    required this.id,
    required this.name,
    this.color = 0xFF6366F1,
    this.icon = Icons.folder.codePoint,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color,
    'icon': icon,
  };

  factory Folder.fromJson(Map<String, dynamic> json) => Folder(
    id: json['id'],
    name: json['name'],
    color: json['color'],
    icon: json['icon'],
  );
}

class Tag {
  final String id;
  final String name;
  final int color;

  Tag({
    required this.id,
    required this.name,
    this.color = 0xFF6366F1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color,
  };

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
    id: json['id'],
    name: json['name'],
    color: json['color'],
  );
}