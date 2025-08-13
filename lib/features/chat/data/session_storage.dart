import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/chat_session.dart';

class SessionStorage {
  static const _kSessions = 'chat_sessions_v1';
  static const _kActiveId = 'chat_active_id_v1';

  Future<List<ChatSession>> loadAll() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kSessions);
    if (s == null) return [];
    final list = (jsonDecode(s) as List).map((e) => ChatSession.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    return list;
  }

  Future<void> saveAll(List<ChatSession> sessions) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kSessions, jsonEncode(sessions.map((e) => e.toJson()).toList()));
  }

  Future<String?> getActiveId() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kActiveId);
  }

  Future<void> setActiveId(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kActiveId, id);
  }
}
