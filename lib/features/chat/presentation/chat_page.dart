// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/chat_models.dart';
import '../domain/chat_session.dart';
import '../data/chat_api.dart';
import '../data/ocr_service.dart';
import '../data/pdf_service.dart';
import '../data/session_storage.dart';
import 'session_drawer.dart';
import 'widgets/chat_input_area.dart';
import 'widgets/message_bubble.dart';

class ChatPage extends StatefulWidget {
  final String sessionId; // از /chat/:sessionId
  const ChatPage({super.key, required this.sessionId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();

  final _storage = SessionStorage();
  final _ocr = OcrService();
  final _pdf = PdfService();

  List<ChatSession> _sessions = [];
  ChatSession? _active;
  bool _typing = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    final all = await _storage.loadAll();
    final activeId = widget.sessionId == 'new' ? await _storage.getActiveId() : widget.sessionId;

    setState(() => _sessions = all);

    if (activeId != null && all.any((s) => s.id == activeId)) {
      _active = all.firstWhere((s) => s.id == activeId);
    } else {
      _active = _newSessionSync();
      await _persist();
    }
    if (widget.sessionId != _active!.id) context.go('/chat/${_active!.id}');
  }

  ChatSession _newSessionSync() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final s = ChatSession(id: id, title: 'جلسه جدید', createdAt: DateTime.now(), messages: []);
    _sessions.insert(0, s);
    _active = s;
    return s;
  }

  Future<void> _newSession() async {
    _newSessionSync();
    await _persist();
    if (!mounted) return;
    context.go('/chat/${_active!.id}');
    setState(() {});
  }

  Future<void> _renameSession(ChatSession s) async {
    final c = TextEditingController(text: s.title);
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('نام‌گذاری جلسه'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('لغو')),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('ذخیره')),
        ],
      ),
    );
    if (title == null || title.isEmpty) return;
    setState(() => s.title = title);
    await _persist();
  }

  Future<void> _deleteSession(ChatSession s) async {
    if (_sessions.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حداقل یک جلسه باید باقی بماند.')));
      return;
    }
    _sessions.removeWhere((e) => e.id == s.id);
    if (_active?.id == s.id) _active = _sessions.first;
    await _persist();
    if (!mounted) return;
    context.go('/chat/${_active!.id}');
    setState(() {});
  }

  Future<void> _persist() async {
    await _storage.saveAll(_sessions);
    if (_active != null) await _storage.setActiveId(_active!.id);
  }

  void _shareSession() {
    if (_active == null || _active!.messages.isEmpty) return;
    final text = _active!.messages.map((m) => '${m.sender}: ${m.text}${m.imagesB64.isNotEmpty ? ' [تصویر]' : ''}').join('\n');
    Share.share(text, subject: _active!.title);
  }

  Future<void> _send(String text, {List<String> imagesB64 = const [], String? pdfText}) async {
    if (_active == null) return;

    if (pdfText != null && pdfText.isNotEmpty) {
      final extracted = await _pdf.extract(Uint8List.fromList(base64Decode(pdfText)));
      text = '$text\n\n[متن PDF]\n$extracted';
      imagesB64 = const [];
    }

    if (imagesB64.isNotEmpty) {
      final first = base64Decode(imagesB64.first);
      final extracted = await _ocr.extract(first);
      if (extracted.length >= 24) {
        text = '$text\n\n[متن تصویر]\n$extracted';
        imagesB64 = const [];
      }
    }

    final now = DateTime.now();
    final user = ChatMessage(id: now.toIso8601String(), sender: 'user', text: text.isEmpty ? '(بدون متن)' : text, timestamp: now, imagesB64: imagesB64);

    setState(() { _active!.messages.add(user); _typing = true; });
    await _persist();
    _scrollToBottom();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      setState(() => _typing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('توکن دسترسی یافت نشد.')));
      return;
    }

    try {
      final api = ChatApi(token);
      final resp = await api.send(text: user.text, imagesB64: imagesB64);
      final botText = (resp['answer'] ?? '').toString();
      final images = ((resp['images'] as List?) ?? const <dynamic>[]).map((e) => e.toString()).toList();

      setState(() {
        _active!.messages.add(ChatMessage(id: DateTime.now().toIso8601String(), sender: 'bot', text: botText, timestamp: DateTime.now(), imagesB64: images));
        _typing = false;
        if (_active!.title == 'جلسه جدید' && user.text.trim().isNotEmpty) {
          _active!.title = user.text.trim().split('\n').first.take(30);
        }
      });
      await _persist();
      _scrollToBottom();
    } catch (e) {
      setState(() => _typing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در ارسال: $e')));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_active?.title ?? 'چت'),
        actions: [IconButton(onPressed: _shareSession, icon: const Icon(Icons.share))],
      ),
      drawer: SessionDrawer(
        sessions: _sessions,
        activeId: _active?.id,
        onCreate: _newSession,
        onRename: _renameSession,
        onDelete: _deleteSession,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                itemCount: _active?.messages.length ?? 0,
                itemBuilder: (_, i) {
                  final m = _active!.messages[i];
                  return MessageBubble(
                    msg: m,
                    onCopy: () => Clipboard.setData(ClipboardData(text: m.text)),
                    onDelete: () async { setState(() => _active!.messages.removeAt(i)); await _persist(); },
                  );
                },
              ),
            ),
            if (_typing) const Padding(padding: EdgeInsets.only(bottom: 6), child: Text('در حال نوشتن...', style: TextStyle(color: Colors.grey))),
            Padding(
              padding: EdgeInsets.only(left: 8, right: 8, bottom: MediaQuery.of(context).padding.bottom + 8),
              child: ChatInputArea(controller: _controller, focus: _focus, onSend: _send),
            ),
          ],
        ),
      ),
    );
  }
}

extension on String {
  String take(int n) => length <= n ? this : substring(0, n);
}
