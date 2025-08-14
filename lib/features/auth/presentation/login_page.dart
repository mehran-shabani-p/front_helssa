import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/snackbar.dart';
import 'bloc/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();

  void _snack(BuildContext context, String m, {bool error=false}) => AppSnack.show(context, m, error: error);

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
              child: BlocConsumer<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
                    _snack(context, state.errorMessage!, error: true);
                    context.read<AuthCubit>().clearError();
                  }
                  if (state.token.isNotEmpty) {
                    context.go('/chat/new');
                  }
                },
                builder: (context, state) {
                  return Column(
                    children: [
                      TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'شماره موبایل')),
                      const SizedBox(height: 12),
                      if (state.otpSent) TextField(controller: _otp, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'کد تایید')),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: OutlinedButton.icon(onPressed: state.isLoading?null:() => context.read<AuthCubit>().requestOtp(_phone.text.trim()), icon: const Icon(Icons.message_outlined), label: const Text('ارسال کد'))),
                        const SizedBox(width: 12),
                        Expanded(child: FilledButton.icon(onPressed: state.isLoading?null:() => context.read<AuthCubit>().login(phoneNumber: _phone.text.trim(), code: _otp.text.trim()), icon: const Icon(Icons.login), label: const Text('ورود'))),
                      ]),
                      if (state.isLoading) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator(minHeight: 2)),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
