import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DoctorDrawer extends StatelessWidget {
  const DoctorDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const _Header(),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: [
                  _item(context, Icons.home_outlined, 'خانه', () => context.go('/')),
                  _item(context, Icons.person_outline, 'پروفایل', () => context.go('/profile')),
                  _item(context, Icons.calendar_today, 'ویزیت آنلاین', () => context.go('/visits')),
                  _item(context, Icons.star_border, 'ویزیت ویژه', () => context.go('/visits/special')),
                  _item(context, Icons.receipt_long, 'نسخه‌های قبلی', () => context.go('/prescriptions')),
                  _item(context, Icons.support_agent, 'تماس با ما', () => context.go('/contact')),
                  const Divider(height: 24),
                  _item(context, Icons.chat_bubble_outline, 'چت هوشمند (فول‌اسکرین)', () => context.go('/chat/new')),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: const [
                Icon(Icons.info_outline, size: 18, color: Colors.white54),
                SizedBox(width: 8),
                Expanded(child: Text('هلسا — نسخه تولید', style: TextStyle(color: Colors.white60, fontSize: 12))),
              ]),
            )
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext c, IconData i, String t, VoidCallback to) =>
      ListTile(leading: Icon(i, color: Colors.white70), title: Text(t), onTap: () { Navigator.of(c).maybePop(); to(); });

}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
            child: const Icon(Icons.local_hospital, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Helssa', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 2),
              Text('کلینیک هوشمند', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }
}
