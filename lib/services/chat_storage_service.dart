import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat_models.dart';

class ChatStorageService {
  static const String chatHistoryBoxName = 'chatHistoryBox';

  static Future<void> init() async {
    await Hive.openBox(chatHistoryBoxName);
  }

  Future<List<ChatMessage>> loadMessages() async {
    try {
      final box = Hive.box(chatHistoryBoxName);
      final List<dynamic> data = box.get('history', defaultValue: []);
      return data.map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMessages(List<ChatMessage> messages) async {
    final box = Hive.box(chatHistoryBoxName);
    final data = messages.map((e) => e.toJson()).toList();
    await box.put('history', data);
  }

  Future<void> clearHistory() async {
    final box = Hive.box(chatHistoryBoxName);
    await box.clear();
  }
}

