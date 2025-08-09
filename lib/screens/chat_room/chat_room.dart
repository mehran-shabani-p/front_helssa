// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:share_plus/share_plus.dart';

import '../../utils/snackbar.dart';
import '../../constants.dart';
import 'chat_message_bubble.dart';
import 'chat_input_area.dart';

class ChatColors {
  static const primaryGreen = Color(0xFF2E7D66);
  static const lightGreen = Color(0xFF4CAF50);
  static const darkGreen = Color(0xFF1B5E20);
  static const paleGreen = Color(0xFFE8F7E8);
  static const softGreen = Color(0xFF66BB6A);
  static const backgroundGreen = Color(0xFFF1F8E9);
}

// --- Animated AppBar Title ---
class GradientTween extends Tween<Gradient> {
  GradientTween({required Gradient begin, required Gradient end}) : super(begin: begin, end: end);
  @override
  Gradient lerp(double t) {
    if (begin is LinearGradient && end is LinearGradient) {
      final b = begin as LinearGradient;
      final e = end as LinearGradient;
      return LinearGradient(
        begin: Alignment.lerp(b.begin as Alignment?, e.begin as Alignment?, t)!,
        end: Alignment.lerp(b.end as Alignment?, e.end as Alignment?, t)!,
        colors: List.generate(b.colors.length, (i) => Color.lerp(b.colors[i], e.colors[i], t)!),
        stops: b.stops ?? e.stops,
      );
    }
    return t < 0.5 ? begin! : end!;
  }
}

class AnimatedTitle extends StatefulWidget {
  const AnimatedTitle({super.key});
  @override
  State<AnimatedTitle> createState() => _AnimatedTitleState();
}

class _AnimatedTitleState extends State<AnimatedTitle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Gradient> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _gradientAnimation = GradientTween(
      begin: LinearGradient(colors: [ChatColors.lightGreen, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
      end: LinearGradient(colors: [Colors.white, ChatColors.softGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  void _handleTap() { if (_controller.status != AnimationStatus.forward) { _controller.forward().then((_) => _controller.reverse()); } }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Row(
        children: [
          CircleAvatar(backgroundColor: ChatColors.paleGreen, radius: 18, child: Icon(Icons.auto_awesome, color: ChatColors.darkGreen, size: 20)),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _gradientAnimation,
            builder: (context, child) => ShaderMask(
              shaderCallback: (r) => _gradientAnimation.value.createShader(Rect.fromLTWH(0, 0, r.width, r.height)),
              child: child,
            ),
            child: const Text('DocAI Assistant', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// --- Background Particles ---
class AnimatedBackground extends StatefulWidget { const AnimatedBackground({super.key}); @override State<AnimatedBackground> createState() => _AnimatedBackgroundState(); }
class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();
  Size? _screenSize;

  @override
  void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat(); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _initializeParticles(Size size) {
    if (size == _screenSize) return;
    _screenSize = size; _particles.clear();
    for (int i = 0; i < 30; i++) { _particles.add(_createParticle(size)); }
  }

  Particle _createParticle(Size size) => Particle(
    position: Offset(_random.nextDouble()*size.width, _random.nextDouble()*size.height),
    color: ChatColors.lightGreen.withOpacity(_random.nextDouble()*0.1 + 0.05),
    radius: _random.nextDouble()*20 + 10,
    velocity: Offset((_random.nextDouble()-0.5)*0.4, (_random.nextDouble()-0.5)*0.4),
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight); _initializeParticles(size);
      return AnimatedBuilder(animation: _controller, builder: (_, __) => CustomPaint(painter: BackgroundPainter(_particles, _random), child: Container()));
    });
  }
}

class Particle { Offset position; Color color; double radius; Offset velocity;
  Particle({required this.position, required this.color, required this.radius, required this.velocity}); }
class BackgroundPainter extends CustomPainter {
  final List<Particle> particles; final Random random;
  BackgroundPainter(this.particles, this.random);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint(); if (particles.isEmpty) return;
    for (var p in particles) {
      p.position += p.velocity;
      if (p.position.dx < -p.radius) { p.position = Offset(size.width + p.radius, random.nextDouble()*size.height); }
      else if (p.position.dx > size.width + p.radius) { p.position = Offset(-p.radius, random.nextDouble()*size.height); }
      if (p.position.dy < -p.radius) { p.position = Offset(random.nextDouble()*size.width, size.height + p.radius); }
      else if (p.position.dy > size.height + p.radius) { p.position = Offset(random.nextDouble()*size.width, -p.radius); }
      paint.color = p.color; canvas.drawCircle(p.position, p.radius, paint);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ChatRoom extends StatefulWidget { const ChatRoom({super.key}); @override State<ChatRoom> createState() => _ChatRoomState(); }

class _ChatRoomState extends State<ChatRoom> with TickerProviderStateMixin {
  static const double _kAppBarHeight = 56;

  final TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final Set<String> _animatedMessages = <String>{};

  Map<String, List<Map<String, dynamic>>> chatsByDate = {};
  String currentDate = '';
  List<Map<String, dynamic>> currentMessages = [];
  bool isTyping = false;
  bool _showScrollButton = false;

  @override
  void initState() {
    super.initState();
    currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadMessages();
    _scrollController.addListener(() => setState(() => _showScrollButton = _scrollController.offset >= 400));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    chatsByDate[currentDate] = currentMessages;
    await prefs.setString('chats_by_date', jsonEncode(chatsByDate));
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString('chats_by_date');
    if (encoded == null) return;
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    setState(() {
      chatsByDate = decoded.map((k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v)));
      currentMessages = chatsByDate[currentDate] ?? [];
      for (var msg in currentMessages) {
        if (msg['sender'] == 'bot' && msg['id'] != null) {
          _animatedMessages.add(msg['id'].toString());
        }
      }
    });
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _shareChat() {
    if (currentMessages.isEmpty) {
      CustomSnackBar.show('چتی برای اشتراک‌گذاری وجود ندارد.', context);
      return;
    }
    final chatText = currentMessages
        .map((m) => '${m['sender']}: ${m['text']}${(m['images'] != null && (m['images'] as List).isNotEmpty) ? ' [تصویر]' : ''}')
        .join('\n');
    Share.share(chatText, subject: 'چت من با DocAI');
  }

  Future<void> _showClearChatConfirmationDialog() async {
    if (currentMessages.isEmpty) {
      CustomSnackBar.show('چت در حال حاضر خالی است.', context);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('پاک کردن چت'),
        content: const Text('آیا مطمئن هستید که می‌خواهید کل تاریخچه این چت را پاک کنید؟'),
        actions: [
          TextButton(child: const Text('لغو'), onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            child: Text('پاک کردن', style: TextStyle(color: Colors.red.shade600)),
            onPressed: () {
              setState(() {
                currentMessages.clear();
                _animatedMessages.clear();
                _saveMessages();
              });
              Navigator.of(ctx).pop();
              CustomSnackBar.show('چت با موفقیت پاک شد.', context);
            },
          ),
        ],
      ),
    );
  }

  PreferredSize _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(_kAppBarHeight),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [ChatColors.primaryGreen, ChatColors.darkGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: ChatColors.primaryGreen.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AnimatedTitle(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: _shareChat, splashRadius: 22),
                  IconButton(icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white), onPressed: _showClearChatConfirmationDialog, splashRadius: 22),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          CircleAvatar(radius: 14, backgroundColor: ChatColors.paleGreen, child: Icon(Icons.auto_awesome, size: 16, color: ChatColors.darkGreen)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: DefaultTextStyle(
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              child: AnimatedTextKit(repeatForever: true, animatedTexts: [WavyAnimatedText('...')], isRepeatingAnimation: true),
            ),
          ),
        ],
      ),
    );
  }

  /// onSend از ChatInputArea: متن و لیست تصاویر Base64
  Future<void> sendMessage(String text, List<String> imagesB64) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      CustomSnackBar.show('ارسال تصویر بدون متن مجاز نیست.', context, isError: true);
      return;
    }

    final DateTime now = DateTime.now();
    final userMessage = {
      'id': now.toIso8601String(),
      'text': trimmed,
      'sender': 'user',
      'timestamp': now.toIso8601String(),
      'images': imagesB64, // ذخیره برای نمایش در بابل
    };

    setState(() {
      currentMessages.add(userMessage);
      isTyping = true;
    });

    messageController.clear();
    _scrollToBottom();
    await _saveMessages();

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    if (accessToken == null || accessToken.isEmpty) {
      CustomSnackBar.show('توکن دسترسی پیدا نشد.', context, isError: true);
      setState(() => isTyping = false);
      return;
    }

    try {
      // آدرس جدید: baseUrl/chat/msg  (بدون /api)
      final uri = Uri.parse('$baseUrl/chat/msg/');

      final payload = <String, dynamic>{'message': trimmed};
      if (imagesB64.isNotEmpty) {
        // منطق: message یا image + message (ارسال تصویر اختیاری، اما هرگز تنها نیست)
        payload['images'] = imagesB64; // اگر بک‌اند شما تک‌تصویر می‌خواهد، یک کلید 'image' بفرستید.
      }

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 60));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final botText = (data['answer'] ?? '').toString();

        final botMessageId = DateTime.now().toIso8601String();
        final botMessage = {
          'id': botMessageId,
          'text': botText,
          'sender': 'bot',
          'timestamp': DateTime.now().toIso8601String(),
          'isTyping': true,
          'images': (data['images'] ?? []) as List<dynamic>, // در صورت وجود
        };

        setState(() {
          currentMessages.add(botMessage);
          isTyping = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _animatedMessages.add(botMessageId);
        });

        await _saveMessages();
        _scrollToBottom();
      } else {
        CustomSnackBar.show('خطا در ارسال پیام. کد: ${response.statusCode}', context, isError: true);
        setState(() => isTyping = false);
      }
    } on TimeoutException {
      if (mounted) {
        CustomSnackBar.show('زمان انتظار به پایان رسید. لطفاً دوباره تلاش کنید.', context, isError: true);
      }
      setState(() => isTyping = false);
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show('خطا در اتصال: $e', context, isError: true);
      }
      setState(() => isTyping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChatColors.backgroundGreen,
      appBar: _buildAppBar(),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            const Positioned.fill(child: AnimatedBackground()),
            Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(top: 16, bottom: 20),
                        itemCount: currentMessages.length,
                        itemBuilder: (ctx, idx) => ChatMessageBubble(
                          msg: currentMessages[idx],
                          index: idx,
                          animatedMessages: _animatedMessages,
                          onDelete: () {
                            setState(() {
                              final removed = currentMessages.removeAt(idx);
                              if (removed['id'] != null) {
                                _animatedMessages.remove(removed['id'].toString());
                              }
                              _saveMessages();
                            });
                          },
                        ),
                      ),
                      if (_showScrollButton)
                        Positioned(
                          right: 16,
                          bottom: 20,
                          child: FloatingActionButton(
                            mini: true,
                            backgroundColor: ChatColors.primaryGreen,
                            elevation: 4,
                            onPressed: _scrollToBottom,
                            child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isTyping) _buildTypingIndicator(),
                ChatInputArea(
                  messageController: messageController,
                  focusNode: _focusNode,
                  onSend: sendMessage, // ← اکنون (text, imagesB64) می‌گیرد
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}