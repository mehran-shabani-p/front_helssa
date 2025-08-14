import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../domain/chat_session.dart';
import 'bloc/chat_cubit.dart';

class SessionDrawer extends StatelessWidget {
  final List<ChatSession> sessions;
  final String? activeId;
  final VoidCallback? onNavigate;

  const SessionDrawer({
    super.key,
    required this.sessions,
    required this.activeId,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.chat_bubble,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'هلسا چت',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                        ),
                        Text(
                          'پزشک هوش مصنوعی',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withValues(alpha: 0.8),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // New session button
            Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    onNavigate?.call();
                    await context.read<ChatCubit>().createNewSession();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('چت جدید'),
                ),
              ),
            ),

            const Divider(height: 1),

            // Sessions list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: sessions.length,
                itemBuilder: (_, i) {
                  final s = sessions[i];
                  final selected = s.id == activeId;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    elevation: selected ? 2 : 0,
                    color: selected
                        ? Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.3)
                        : null,
                    child: ListTile(
                      selected: selected,
                      leading: Icon(
                        Icons.chat_bubble_outline,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                      ),
                      title: Text(
                        s.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        _formatDate(s.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      onTap: () {
                        onNavigate?.call();
                        context.go('/chat/${s.id}');
                      },
                      trailing: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          size: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'rename',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('تغییر نام'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('حذف',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (v) async {
                          if (v == 'rename') {
                            final c = TextEditingController(text: s.title);
                            final title = await showDialog<String>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('تغییر نام جلسه'),
                                content: TextField(
                                  controller: c,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    hintText: 'نام جدید جلسه',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('لغو'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, c.text.trim()),
                                    child: const Text('ذخیره'),
                                  ),
                                ],
                              ),
                            );
                            if (title != null && title.isNotEmpty) {
                              await context
                                  .read<ChatCubit>()
                                  .renameSession(s, title);
                            }
                          }
                          if (v == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('حذف جلسه'),
                                content: Text(
                                    'آیا از حذف جلسه "${s.title}" مطمئن هستید؟'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('لغو'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('حذف'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await context.read<ChatCubit>().deleteSession(s);
                            }
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // Navigation to other pages
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _buildNavigationButton(
                    context,
                    icon: Icons.home_outlined,
                    label: 'خانه',
                    onTap: () {
                      onNavigate?.call();
                      context.go('/');
                    },
                  ),
                  _buildNavigationButton(
                    context,
                    icon: Icons.person_outline,
                    label: 'پروفایل',
                    onTap: () {
                      onNavigate?.call();
                      context.go('/profile');
                    },
                  ),
                  _buildNavigationButton(
                    context,
                    icon: Icons.calendar_today,
                    label: 'ویزیت آنلاین',
                    onTap: () {
                      onNavigate?.call();
                      context.go('/visits');
                    },
                  ),
                  _buildNavigationButton(
                    context,
                    icon: Icons.support_agent,
                    label: 'تماس با ما',
                    onTap: () {
                      onNavigate?.call();
                      context.go('/contact');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'امروز';
    } else if (difference.inDays == 1) {
      return 'دیروز';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} روز پیش';
    } else {
      return '${date.year}/${date.month}/${date.day}';
    }
  }
}
