import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../domain/chat_session.dart';
import 'bloc/chat_cubit.dart';

class SessionDrawer extends StatelessWidget {
  final List<ChatSession> sessions;
  final String? activeId;

  const SessionDrawer({super.key, required this.sessions, required this.activeId});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('جلسه جدید'),
              onTap: () async {
                Navigator.pop(context);
                await context.read<ChatCubit>().createNewSession();
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: sessions.length,
                itemBuilder: (_, i) {
                  final s = sessions[i];
                  final selected = s.id == activeId;
                  return ListTile(
                    selected: selected,
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${s.createdAt}'),
                    onTap: () { Navigator.pop(context); context.go('/chat/${s.id}'); },
                    trailing: PopupMenuButton(
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'rename', child: Text('تغییر نام')),
                        PopupMenuItem(value: 'delete', child: Text('حذف'))
                      ],
                      onSelected: (v) async {
                        if (v == 'rename') {
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
                          if (title != null && title.isNotEmpty) {
                            await context.read<ChatCubit>().renameSession(s, title);
                          }
                        }
                        if (v == 'delete') {
                          await context.read<ChatCubit>().deleteSession(s);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
