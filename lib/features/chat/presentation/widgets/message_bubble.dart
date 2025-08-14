import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/chat_models.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage msg;
  final VoidCallback onDelete;
  final VoidCallback onCopy;

  const MessageBubble(
      {super.key,
      required this.msg,
      required this.onDelete,
      required this.onCopy});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _showMenu = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.msg.sender == 'user';

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Align(
          alignment: isUser
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              end: isUser ? 16 : 80,
              start: isUser ? 80 : 16,
              top: 6,
              bottom: 6,
            ),
            child: GestureDetector(
              onLongPress: () {
                setState(() => _showMenu = true);
                HapticFeedback.mediumImpact();
              },
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                  minWidth: 80,
                ),
                decoration: BoxDecoration(
                  color: isUser
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: _getBorderRadius(isUser),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Theme.of(context).shadowColor.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Images section
                    if (widget.msg.imagesB64.isNotEmpty)
                      _buildImagesSection(context, isUser),

                    // Text content
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          16, widget.msg.imagesB64.isEmpty ? 12 : 8, 16, 8),
                      child: SelectableText(
                        widget.msg.text,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: isUser
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                              height: 1.4,
                            ),
                      ),
                    ),

                    // Footer with timestamp and actions
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Timestamp
                          Text(
                            _formatTimestamp(widget.msg.timestamp),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isUser
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                              .withValues(alpha: 0.7)
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.6),
                                      fontSize: 11,
                                    ),
                          ),

                          const SizedBox(width: 8),

                          // Action buttons (appear on hover/long press)
                          if (_showMenu ||
                              MediaQuery.of(context).size.width > 600)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildActionButton(
                                  context,
                                  icon: Icons.copy_rounded,
                                  onTap: () {
                                    widget.onCopy();
                                    HapticFeedback.lightImpact();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('متن کپی شد'),
                                        duration: Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  isUser: isUser,
                                ),
                                const SizedBox(width: 4),
                                _buildActionButton(
                                  context,
                                  icon: Icons.delete_outline_rounded,
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('حذف پیام'),
                                        content: const Text(
                                            'آیا از حذف این پیام مطمئن هستید؟'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('لغو'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            child: const Text('حذف'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      widget.onDelete();
                                    }
                                  },
                                  isUser: isUser,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BorderRadius _getBorderRadius(bool isUser) {
    return BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
      bottomRight:
          isUser ? const Radius.circular(4) : const Radius.circular(18),
    );
  }

  Widget _buildImagesSection(BuildContext context, bool isUser) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.memory(
              base64Decode(widget.msg.imagesB64.first),
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),

            // Multiple images indicator
            if (widget.msg.imagesB64.length > 1)
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.msg.imagesB64.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    required bool isUser,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2)
              : Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isUser
              ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8)
              : Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.7),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'الان';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} دقیقه پیش';
    } else if (difference.inDays < 1) {
      return TimeOfDay.fromDateTime(timestamp).format(context);
    } else if (difference.inDays == 1) {
      return 'دیروز ${TimeOfDay.fromDateTime(timestamp).format(context)}';
    } else {
      return '${timestamp.year}/${timestamp.month}/${timestamp.day}';
    }
  }
}
