
class Note {
  final String id;
  final String userId;
  String title;
  String content;
  DateTime createdAt;
  DateTime updatedAt;
  bool isPinned;
  List<String>? tags;
  String? color;

  Note({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isPinned = false,
    this.tags,
    this.color,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned,
      'tags': tags,
      'color': color,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      content: map['content'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      isPinned: map['isPinned'] ?? false,
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
      color: map['color'],
    );
  }

  Note copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
    bool? isPinned,
    List<String>? tags,
    String? color,
  }) {
    return Note(
      id: id,
      userId: userId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
      color: color ?? this.color,
    );
  }
}