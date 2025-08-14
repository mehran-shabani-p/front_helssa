// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/media_service.dart';

typedef OnSend = void Function(String text,
    {List<String> imagesB64, String? pdfText});

class ChatInputArea extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focus;
  final OnSend onSend;
  const ChatInputArea(
      {super.key,
      required this.controller,
      required this.focus,
      required this.onSend});

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea>
    with TickerProviderStateMixin {
  final _media = MediaService();
  final List<Uint8List> _images = [];
  String? _pdfText;
  bool _showAttachments = false;
  late AnimationController _attachmentController;
  late Animation<double> _attachmentAnimation;

  @override
  void initState() {
    super.initState();
    _attachmentController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _attachmentAnimation = CurvedAnimation(
      parent: _attachmentController,
      curve: Curves.easeInOut,
    );

    // Listen to text changes to show/hide send button
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _attachmentController.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  bool get _hasContent =>
      widget.controller.text.trim().isNotEmpty ||
      _images.isNotEmpty ||
      _pdfText != null;

  Future<void> _pick(ImageSource src) async {
    final b = await _media.pick(src);
    if (b != null) {
      setState(() => _images.add(b));
      _toggleAttachments(false);
    }
  }

  Future<void> _pickPdf() async {
    final res = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (res == null || res.files.single.bytes == null) return;
    setState(() => _pdfText = base64Encode(res.files.single.bytes!));
    _toggleAttachments(false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('PDF انتخاب شد'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleAttachments([bool? show]) {
    setState(() {
      _showAttachments = show ?? !_showAttachments;
      if (_showAttachments) {
        _attachmentController.forward();
      } else {
        _attachmentController.reverse();
      }
    });
  }

  void _attemptSend() {
    final txt = widget.controller.text.trim();
    if (!_hasContent) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً پیامی وارد کنید یا فایلی انتخاب کنید'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    widget.onSend(
      txt.isEmpty ? '(بدون متن)' : txt,
      imagesB64: _images.map((b) => base64Encode(b)).toList(),
      pdfText: _pdfText,
    );
    widget.controller.clear();
    setState(() {
      _images.clear();
      _pdfText = null;
      _showAttachments = false;
    });
    _attachmentController.reset();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Attachments preview
            if (_images.isNotEmpty || _pdfText != null)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'فایل‌های انتخاب شده:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Images
                        for (int i = 0; i < _images.length; i++)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Image.memory(
                                    _images[i],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      onPressed: () =>
                                          setState(() => _images.removeAt(i)),
                                      icon: const Icon(Icons.close,
                                          size: 16, color: Colors.white),
                                      constraints: const BoxConstraints(
                                          minWidth: 24, minHeight: 24),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // PDF
                        if (_pdfText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.picture_as_pdf,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'PDF انتخاب‌شده',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => setState(() => _pdfText = null),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

            // Attachment options (expandable)
            AnimatedBuilder(
              animation: _attachmentAnimation,
              builder: (context, child) {
                return Container(
                  height: _attachmentAnimation.value * 60,
                  child: _attachmentAnimation.value > 0 ? child : null,
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttachmentButton(
                      icon: Icons.camera_alt,
                      label: 'دوربین',
                      color: Colors.blue,
                      onTap: () => _pick(ImageSource.camera),
                    ),
                    _buildAttachmentButton(
                      icon: Icons.photo_library,
                      label: 'گالری',
                      color: Colors.green,
                      onTap: () => _pick(ImageSource.gallery),
                    ),
                    _buildAttachmentButton(
                      icon: Icons.picture_as_pdf,
                      label: 'PDF',
                      color: Colors.red,
                      onTap: _pickPdf,
                    ),
                  ],
                ),
              ),
            ),

            // Main input row
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  // Attachment button
                  IconButton(
                    onPressed: () => _toggleAttachments(),
                    icon: AnimatedRotation(
                      turns: _showAttachments ? 0.125 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(Icons.add),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _showAttachments
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      foregroundColor: _showAttachments
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Text input
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: TextField(
                        controller: widget.controller,
                        focusNode: widget.focus,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'پیام خود را بنویسید...',
                          hintStyle: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) {
                          if (_hasContent) _attemptSend();
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: _hasContent
                        ? IconButton(
                            onPressed: _attemptSend,
                            icon: const Icon(Icons.send_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              padding: const EdgeInsets.all(12),
                            ),
                          )
                        : IconButton(
                            onPressed: null,
                            icon: const Icon(Icons.send_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              foregroundColor: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.5),
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
