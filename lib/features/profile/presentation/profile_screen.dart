import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _svc = ProfileService();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _nationalId = TextEditingController();
  bool _busy = false;

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final sp = await SharedPreferences.getInstance();
      final t = sp.getString('access_token') ?? '';
      final p = await _svc.fetchProfile(t);
      _name.text = (p['name'] ?? '').toString();
      _email.text = (p['email'] ?? '').toString();
      _nationalId.text = (p['nationalId'] ?? '').toString();
    } catch (_) {} finally { setState(() => _busy = false); }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final sp = await SharedPreferences.getInstance();
      final t = sp.getString('access_token') ?? '';
      await _svc.updateProfile(t, {'name': _name.text.trim(), 'email': _email.text.trim(), 'nationalId': _nationalId.text.trim()});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ذخیره شد')));
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e'))); }
    finally { setState(() => _busy = false); }
  }

  @override
  void initState() { super.initState(); _load(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پروفایل')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                TextField(controller: _name, decoration: const InputDecoration(labelText: 'نام')),
                const SizedBox(height: 12),
                TextField(controller: _email, decoration: const InputDecoration(labelText: 'ایمیل')),
                const SizedBox(height: 12),
                TextField(controller: _nationalId, decoration: const InputDecoration(labelText: 'کد ملی')),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: _busy?null:_load, child: const Text('بارگیری دوباره'))),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton(onPressed: _busy?null:_save, child: const Text('ذخیره'))),
                ]),
                if (_busy) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator(minHeight: 2)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
