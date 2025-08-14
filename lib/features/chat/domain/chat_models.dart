class ChatMessage {
  final String id;
  final String sender; // 'user' | 'bot'
  final String text;
  final DateTime timestamp;
  final List<String> imagesB64;
  final bool isTyping;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.imagesB64 = const [],
    this.isTyping = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'images': imagesB64,
        'isTyping': isTyping,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'],
        sender: j['sender'],
        text: j['text'] ?? '',
        timestamp: DateTime.parse(j['timestamp']),
        imagesB64: (j['images'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        isTyping: j['isTyping'] == true,
      );
}
