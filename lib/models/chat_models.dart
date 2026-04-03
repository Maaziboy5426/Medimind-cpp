/// Single chat message for UI and persistence.
class ChatMessage {
  const ChatMessage({
    required this.messageID,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  final String messageID;
  final String role; // 'user' or 'ai'
  final String content;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'messageID': messageID,
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  static ChatMessage fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageID: json['messageID'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class ChatRole {
  static const String user = 'user';
  static const String ai = 'ai';
}
