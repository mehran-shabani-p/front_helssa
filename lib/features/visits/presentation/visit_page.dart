import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/visit_service.dart';

class VisitPage extends StatefulWidget {
  const VisitPage({super.key});
  @override
  State<VisitPage> createState() => _VisitPageState();
}

class _VisitPageState extends State<VisitPage> {
  final _svc = VisitService();
  final _desc = TextEditingController();
  bool _busy = false;
  List<Map<String, dynamic>> _items = const [];

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final sp = await SharedPreferences.getInstance();
      final t = sp.getString('access_token') ?? '';
      _items = await _svc.listVisits(t);
    } catch (e) { _snack('خطا در دریافت لیست: $e'); }
    finally { setState(() => _busy = false); }
  }

  Future<void> _request() async {
    if (_desc.text.trim().isEmpty) { _snack('شرح مشکل را وارد کنید.'); return; }
    setState(() => _busy = true);
    try {
      final sp = await SharedPreferences.getInstance();
      final t = sp.getString('access_token') ?? '';
      await _svc.requestVisit(t, {'description': _desc.text.trim()});
      _desc.clear(); _snack('درخواست ثبت شد.'); await _load();
    } catch (e) { _snack('خطا در ثبت: $e', error: true); }
    finally { setState(() => _busy = false); }
  }

  void _snack(String m, {bool error=false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: error ? Colors.red.shade700 : null));
  }

  @override
  void initState() { super.initState(); _load(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ویزیت آنلاین')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(child: TextField(controller: _desc, minLines: 1, maxLines: 3, decoration: const InputDecoration(hintText: 'شرح مشکل...'))),
                const SizedBox(width: 8),
                FilledButton.icon(onPressed: _busy?null:_request, icon: const Icon(Icons.send), label: const Text('درخواست')),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: _busy
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final it = _items[i];
                      return ListTile(
                        title: Text(it['title']?.toString() ?? 'ویزیت'),
                        subtitle: Text(it['status']?.toString() ?? 'نامشخص'),
                        trailing: Text(it['date']?.toString() ?? ''),
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
