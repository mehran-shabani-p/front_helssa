import 'dart:convert';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/chat_api.dart';
import '../../data/ocr_service.dart';
import '../../data/pdf_service.dart';
import '../../data/session_storage.dart';
import '../../domain/chat_models.dart';
import '../../domain/chat_session.dart';

class ChatState extends Equatable {
  final List<ChatSession> sessions;
  final String? activeId;
  final bool isTyping;
  final String? errorMessage;

  const ChatState({
    this.sessions = const [],
    this.activeId,
    this.isTyping = false,
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatSession>? sessions,
    String? activeId,
    bool? isTyping,
    String? errorMessage,
  }) {
    return ChatState(
      sessions: sessions ?? this.sessions,
      activeId: activeId ?? this.activeId,
      isTyping: isTyping ?? this.isTyping,
      errorMessage: errorMessage,
    );
  }

  ChatSession? get active {
    if (sessions.isEmpty) return null;
    try {
      return sessions.firstWhere((s) => s.id == activeId);
    } catch (_) {
      return sessions.first;
    }
  }

  @override
  List<Object?> get props => [sessions, activeId, isTyping, errorMessage];
}

class ChatCubit extends Cubit<ChatState> {
  final SessionStorage _storage;
  final OcrService _ocr;
  final PdfService _pdf;

  ChatCubit(this._storage, this._ocr, this._pdf) : super(const ChatState());

  Future<void> load({String? initialSessionId}) async {
    final all = await _storage.loadAll();
    String? active = initialSessionId == 'new' ? await _storage.getActiveId() : initialSessionId;
    if (active != null && all.any((s) => s.id == active)) {
      emit(state.copyWith(sessions: all, activeId: active));
    } else {
      final s = _newSessionSync(all);
      await _persist(all, s.id);
      emit(state.copyWith(sessions: all, activeId: s.id));
    }
  }

  ChatSession _newSessionSync(List<ChatSession> list) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final s = ChatSession(id: id, title: 'جلسه جدید', createdAt: DateTime.now(), messages: []);
    list.insert(0, s);
    return s;
  }

  Future<void> createNewSession() async {
    final list = [...state.sessions];
    final s = _newSessionSync(list);
    await _persist(list, s.id);
    emit(state.copyWith(sessions: list, activeId: s.id));
  }

  Future<void> renameSession(ChatSession session, String newTitle) async {
    if (newTitle.trim().isEmpty) return;
    final list = [...state.sessions];
    final idx = list.indexWhere((e) => e.id == session.id);
    if (idx < 0) return;
    list[idx] = ChatSession(id: session.id, title: newTitle.trim(), createdAt: session.createdAt, messages: session.messages);
    await _persist(list, state.activeId);
    emit(state.copyWith(sessions: list));
  }

  Future<void> deleteSession(ChatSession session) async {
    final list = [...state.sessions];
    if (list.length == 1) return;
    list.removeWhere((e) => e.id == session.id);
    final newActive = state.activeId == session.id ? list.first.id : state.activeId;
    await _persist(list, newActive);
    emit(state.copyWith(sessions: list, activeId: newActive));
  }

  Future<void> send(String text, {List<String> imagesB64 = const [], String? pdfText}) async {
    final act = state.sessions.firstWhere((s) => s.id == state.activeId, orElse: () => state.sessions.first);
    var messageText = text;
    var images = imagesB64;

    if (pdfText != null && pdfText.isNotEmpty) {
      final extracted = await _pdf.extract(Uint8List.fromList(base64Decode(pdfText)));
      messageText = '$messageText\n\n[متن PDF]\n$extracted';
      images = const [];
    }

    if (images.isNotEmpty) {
      final first = base64Decode(images.first);
      final extracted = await _ocr.extract(first);
      if (extracted.length >= 24) {
        messageText = '$messageText\n\n[متن تصویر]\n$extracted';
        images = const [];
      }
    }

    final now = DateTime.now();
    final user = ChatMessage(id: now.toIso8601String(), sender: 'user', text: messageText.isEmpty ? '(بدون متن)' : messageText, timestamp: now, imagesB64: images);

    final list = [...state.sessions];
    final idx = list.indexWhere((s) => s.id == state.activeId);
    if (idx < 0) return;
    final active = list[idx];
    active.messages.add(user);
    emit(state.copyWith(sessions: list, isTyping: true));
    await _persist(list, active.id);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      emit(state.copyWith(isTyping: false, errorMessage: 'توکن دسترسی یافت نشد.'));
      return;
    }

    try {
      final api = ChatApi(token);
      final resp = await api.send(text: user.text, imagesB64: images);
      final botText = (resp['answer'] ?? '').toString();
      final respImages = ((resp['images'] as List?) ?? const <dynamic>[]) .map((e) => e.toString()).toList();
      active.messages.add(ChatMessage(id: DateTime.now().toIso8601String(), sender: 'bot', text: botText, timestamp: DateTime.now(), imagesB64: respImages));
      if (active.title == 'جلسه جدید' && user.text.trim().isNotEmpty) {
        active.title = user.text.trim().split('\n').first.take(30);
      }
      emit(state.copyWith(sessions: list, isTyping: false));
      await _persist(list, active.id);
    } catch (e) {
      emit(state.copyWith(isTyping: false, errorMessage: 'خطا در ارسال: $e'));
    }
  }

  Future<void> removeMessageAt(int index) async {
    final list = [...state.sessions];
    final idx = list.indexWhere((s) => s.id == state.activeId);
    if (idx < 0) return;
    final active = list[idx];
    if (index < 0 || index >= active.messages.length) return;
    active.messages.removeAt(index);
    await _persist(list, active.id);
    emit(state.copyWith(sessions: list));
  }

  Future<void> _persist(List<ChatSession> list, String? activeId) async {
    await _storage.saveAll(list);
    if (activeId != null) await _storage.setActiveId(activeId);
  }

  void clearError() => emit(state.copyWith(errorMessage: null));
}

extension on String {
  String take(int n) => length <= n ? this : substring(0, n);
}