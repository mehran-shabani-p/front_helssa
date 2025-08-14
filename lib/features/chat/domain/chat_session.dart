import 'chat_models.dart';

class ChatSession {
  final String id;
  String title;
  final DateTime createdAt;
  final List<ChatMessage> messages;

  ChatSession(
      {required this.id,
      required this.title,
      required this.createdAt,
      required this.messages});

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'messages': messages.map((e) => e.toJson()).toList(),
      };

  factory ChatSession.fromJson(Map<String, dynamic> j) => ChatSession(
        id: j['id'],
        title: (j['title'] ?? 'جلسه جدید').toString(),
        createdAt: DateTime.parse(j['createdAt']),
        messages: ((j['messages'] as List?) ?? const [])
            .map((e) =>
                ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
