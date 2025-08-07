// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- رنگ‌های سبز ---
class ChatColors {
  static const primaryGreen = Color(0xFF2E7D66);
  static const lightGreen = Color(0xFF4CAF50);
  static const darkGreen = Color(0xFF1B5E20);
  static const paleGreen = Color(0xFFE8F7E8);
  static const softGreen = Color(0xFF66BB6A);
  static const backgroundGreen = Color(0xFFF1F8E9);
}

class ChatInputArea extends StatefulWidget {
  final TextEditingController messageController;
  final FocusNode focusNode;
  final VoidCallback onSend;

  const ChatInputArea({
    super.key,
    required this.messageController,
    required this.focusNode,
    required this.onSend,
  });

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    widget.messageController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    widget.messageController.removeListener(_onInputChanged);
    super.dispose();
  }

  bool get hasText => widget.messageController.text.trim().isNotEmpty;

  void _onInputChanged() => setState(() {});

  void _toggleEmojiPicker() {
    setState(() => _showEmojiPicker = !_showEmojiPicker);
    if (!_showEmojiPicker) FocusScope.of(context).requestFocus(widget.focusNode);
  }

  void _handleSend() {
    if (!hasText) return;
    widget.onSend();
    HapticFeedback.lightImpact();
    setState(() => _showEmojiPicker = false);
  }

  void _handlePaste() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      final text = data!.text!;
      final selection = widget.messageController.selection;
      final newText = widget.messageController.text.replaceRange(
        selection.start, selection.end, text,
      );
      widget.messageController.value = widget.messageController.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(12, 10, 12, 16),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: ChatColors.lightGreen.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: ChatColors.primaryGreen.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Emoji Picker Button
                IconButton(
                  icon: Icon(
                    Icons.emoji_emotions_outlined, 
                    color: ChatColors.primaryGreen, 
                    size: 26
                  ),
                  splashRadius: 22,
                  tooltip: 'ایموجی',
                  onPressed: _toggleEmojiPicker,
                ),
                // File/Image Attachment
                IconButton(
                  icon: Icon(
                    Icons.attach_file, 
                    color: ChatColors.primaryGreen, 
                    size: 24
                  ),
                  splashRadius: 22,
                  tooltip: 'پیوست',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('امکان ارسال فایل به زودی...')),
                    );
                  },
                ),
                // Expanded Input
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: Scrollbar(
                      child: TextField(
                        controller: widget.messageController,
                        focusNode: widget.focusNode,
                        textInputAction: TextInputAction.send,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'پیام خود را بنویسید…',
                          hintStyle: TextStyle(color: ChatColors.primaryGreen.withOpacity(0.5)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        ),
                        style: TextStyle(
                          fontSize: 16, 
                          color: ChatColors.darkGreen
                        ),
                        textDirection: TextDirection.rtl,
                        onSubmitted: (_) => _handleSend(),
                        onTap: () => setState(() => _showEmojiPicker = false),
                        enableSuggestions: true,
                        autocorrect: true,
                        onEditingComplete: () {
                          if (Theme.of(context).platform == TargetPlatform.windows ||
                              Theme.of(context).platform == TargetPlatform.macOS) {
                            _handleSend();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                // Paste action
                IconButton(
                  icon: Icon(
                    Icons.content_paste_go, 
                    size: 23, 
                    color: ChatColors.primaryGreen
                  ),
                  splashRadius: 22,
                  tooltip: 'چسباندن',
                  onPressed: _handlePaste,
                ),
                // Animated Send Button
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: hasText
                      ? Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _handleSend,
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [ChatColors.primaryGreen, ChatColors.darkGreen],
                                ),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: ChatColors.primaryGreen.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(12),
                              child: const Icon(
                                Icons.send_rounded, 
                                color: Colors.white, 
                                size: 22
                              ),
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.send_rounded, 
                            color: Colors.grey.shade300, 
                            size: 22
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
