import 'dart:convert';

class Note {
  final String id;
  final String uid;
  final String createdAt;
  final String title;
  final String description;

  Note({
    required this.id,
    required this.uid,
    required this.createdAt,
    required this.title,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      createdAt: map['created_at'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Note.fromJson(String source) => Note.fromMap(json.decode(source));
}
