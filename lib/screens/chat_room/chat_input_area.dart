// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

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
  final void Function(String, List<String>) onSend;

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
  
  final ImagePicker _picker = ImagePicker();
  final List<String> _selectedImages = [];  // Base64 strings

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
  bool get hasMedia => _selectedImages.isNotEmpty;

  void _onInputChanged() => setState(() {});

  

  Future<void> _pickImage(ImageSource src) async {
    final XFile? img = await _picker.pickImage(source: src, imageQuality: 65);
    if (img == null) return;
    final bytes = await img.readAsBytes();
    setState(() => _selectedImages.add(base64Encode(bytes)));
  }

  void _handleSend() {
    if (!hasText && !hasMedia) return;
    widget.onSend(widget.messageController.text.trim(), _selectedImages);
    HapticFeedback.lightImpact();
    setState(() {
      _showEmojiPicker = false;
      _selectedImages.clear();
    });
  }

  void _handlePaste() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      final text = data!.text!;
      final selection = widget.messageController.selection;
      final newText = widget.messageController.text.replaceRange(
        selection.start, selection.end, text,
      );
      widget.messageController.text = newText;
      widget.messageController.selection = TextSelection.collapsed(
        offset: selection.start + text.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: ChatColors.backgroundGreen,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
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
          if (_selectedImages.isNotEmpty)
            Container(
              height: 70,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        base64Decode(_selectedImages[i]),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _selectedImages.removeAt(i)),
                      child: const CircleAvatar(
                        radius: 9,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Emoji Picker Button
                 // File/Image Attachment (New)
                 IconButton(
                   icon: Icon(Icons.attach_file, color: ChatColors.primaryGreen, size: 24),
                   splashRadius: 22,
                   tooltip: 'پیوست',
                   onPressed: () async { await _pickImage(ImageSource.gallery); },
                 ),
                 Expanded(
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
                     keyboardType: TextInputType.multiline,
                   ),
                 ),
                 // Send Button
                 InkWell(
                   onTap: _handleSend,
                   child: hasText || hasMedia
                       ? Container(
                           padding: const EdgeInsets.all(12),
                           child: Icon(
                             Icons.send_rounded, 
                             color: ChatColors.primaryGreen, 
                             size: 22
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
