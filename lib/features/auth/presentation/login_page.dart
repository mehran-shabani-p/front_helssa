import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/snackbar.dart';
import '../data/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  bool _sent = false, _busy = false;
  final _auth = AuthService();

  Future<void> _requestOtp() async {
    if (_phone.text.trim().length < 10) { _snack('شماره موبایل معتبر نیست.'); return; }
    setState(() => _busy = true);
    try { await _auth.requestOtp(_phone.text.trim()); setState(() => _sent = true); _snack('کد ارسال شد.'); }
    catch (e) { _snack('خطا در ارسال کد: $e', error: true); }
    finally { setState(() => _busy = false); }
  }

  Future<void> _login() async {
    if (_otp.text.trim().isEmpty) { _snack('کد را وارد کنید.'); return; }
    setState(() => _busy = true);
    try {
      final t = await _auth.login(phoneNumber: _phone.text.trim(), code: _otp.text.trim());
      final sp = await SharedPreferences.getInstance(); await sp.setString('access_token', t);
      if (!mounted) return; context.go('/chat/new');
    } catch (e) { _snack('ورود ناموفق: $e', error: true); }
    finally { setState(() => _busy = false); }
  }

  void _snack(String m, {bool error=false}) => AppSnack.show(context, m, error: error);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ورود')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'شماره موبایل')),
                  const SizedBox(height: 12),
                  if (_sent) TextField(controller: _otp, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'کد تایید')),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(onPressed: _busy?null:_requestOtp, icon: const Icon(Icons.message_outlined), label: const Text('ارسال کد'))),
                    const SizedBox(width: 12),
                    Expanded(child: FilledButton.icon(onPressed: _busy?null:_login, icon: const Icon(Icons.login), label: const Text('ورود'))),
                  ]),
                  if (_busy) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator(minHeight: 2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
