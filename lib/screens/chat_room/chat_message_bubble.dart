// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';

class ChatColors {
  static const primaryGreen = Color(0xFF2E7D66);
  static const lightGreen = Color(0xFF4CAF50);
  static const darkGreen = Color(0xFF1B5E20);
  static const paleGreen = Color(0xFFE8F7E8);
  static const softGreen = Color(0xFF66BB6A);
  static const backgroundGreen = Color(0xFFF1F8E9);
}

// --- تایپر برای متن بات ---
class TypewriterText extends StatefulWidget {
  final String text;
  final Duration duration;
  final TextStyle? style;
  final bool shouldAnimate;

  const TypewriterText({
    super.key,
    required this.text,
    this.duration = const Duration(milliseconds: 50),
    this.style,
    this.shouldAnimate = true,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;
  String displayText = '';

  @override
  void initState() {
    super.initState();
    if (!widget.shouldAnimate) {
      displayText = widget.text;
      _controller = AnimationController(duration: const Duration(milliseconds: 1), vsync: this);
      return;
    }
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.text.length * widget.duration.inMilliseconds),
      vsync: this,
    );
    _animation = IntTween(begin: 0, end: widget.text.length)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _animation.addListener(() {
      if (mounted) setState(() => displayText = widget.text.substring(0, _animation.value));
    });
    _controller.forward();
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text && widget.shouldAnimate) {
      _controller.reset();
      displayText = '';
      _animation = IntTween(begin: 0, end: widget.text.length)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.forward();
    } else if (!widget.shouldAnimate) {
      displayText = widget.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectableText(displayText, style: widget.style, textDirection: Directionality.of(context));
  }
}

class ChatMessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final int index;
  final VoidCallback onDelete;
  final Set<String> animatedMessages;

  const ChatMessageBubble({
    super.key,
    required this.msg,
    required this.index,
    required this.onDelete,
    required this.animatedMessages,
  });

  String _formatTime(DateTime ts) => DateFormat('HH:mm').format(ts);

  @override
  Widget build(BuildContext context) {
    final isUser = msg['sender'] == 'user';
    final isTyping = msg['isTyping'] == true;
    final messageId = msg['id']?.toString() ?? '';
    final hasBeenAnimated = animatedMessages.contains(messageId);

    final List<dynamic> images = (msg['images'] ?? []) as List<dynamic>;
    final List<String> imagesB64 = images.map((e) => e.toString()).toList();

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
    );

    final BoxDecoration botGlassDecoration = BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: borderRadius,
      boxShadow: [
        BoxShadow(
          color: ChatColors.primaryGreen.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      border: Border.all(color: ChatColors.lightGreen.withOpacity(0.3)),
    );

    return Slidable(
      key: ValueKey('${msg['id']}_$index'),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'حذف',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: AnimationConfiguration.staggeredList(
        position: index,
        duration: const Duration(milliseconds: 240),
        child: SlideAnimation(
          verticalOffset: 32,
          child: FadeInAnimation(
            child: Align(
              alignment: isUser
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  end: isUser ? 6 : 60,
                  start: isUser ? 60 : 6,
                  top: 2,
                  bottom: 2,
                ),
                child: GestureDetector(
                  onTap: () {
                    final time = _formatTime(DateTime.parse(msg['timestamp']));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ارسال‌شده در $time'),
                        duration: const Duration(milliseconds: 1200),
                        backgroundColor: Colors.black87,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.symmetric(horizontal: 80, vertical: 12),
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: isUser
                        ? BoxDecoration(
                            gradient: LinearGradient(
                              colors: [ChatColors.primaryGreen, ChatColors.darkGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: borderRadius,
                            boxShadow: [
                              BoxShadow(
                                color: ChatColors.primaryGreen.withOpacity(0.3),
                                blurRadius: 7,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          )
                        : botGlassDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- تصویر کوچک داخل بابل (فقط اولین تصویر نمایش داده می‌شود)
                        if (imagesB64.isNotEmpty) ...[
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  base64Decode(imagesB64.first),
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (imagesB64.length > 1)
                                Positioned(
                                  bottom: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '+${imagesB64.length - 1}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],

                        // --- متن پیام
                        if (isUser || !isTyping)
                          SelectableText(
                            msg['text'] ?? '',
                            style: TextStyle(
                              color: isUser ? Colors.white : ChatColors.darkGreen,
                              fontSize: 16,
                              height: 1.45,
                              fontFamily: 'Vazirmatn',
                            ),
                            textDirection: Directionality.of(context),
                          )
                        else
                          TypewriterText(
                            text: msg['text'] ?? '',
                            duration: const Duration(milliseconds: 30),
                            shouldAnimate: !hasBeenAnimated,
                            style: TextStyle(
                              color: ChatColors.darkGreen,
                              fontSize: 16,
                              height: 1.45,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),

                        const SizedBox(height: 6),

                        // --- زمان و وضعیت
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          textDirection: Directionality.of(context),
                          children: [
                            Text(
                              _formatTime(DateTime.parse(msg['timestamp'])),
                              style: TextStyle(
                                color: isUser ? Colors.white70 : ChatColors.primaryGreen.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                            if (isUser) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.done_all, size: 14, color: Colors.white70),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}