import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/profile_cubit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _nationalId = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load profile on first frame to ensure context availability
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileCubit>().load();
    });
  }

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
              child: BlocConsumer<ProfileCubit, ProfileState>(
                listener: (context, state) {
                  if (state.errorMessage != null &&
                      state.errorMessage!.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطا: ${state.errorMessage}')));
                    context.read<ProfileCubit>().clearError();
                  }
                  if (state.saved) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ذخیره شد')));
                    context.read<ProfileCubit>().clearSaved();
                  }
                },
                builder: (context, state) {
                  _name.value = _name.value.copyWith(
                      text: state.name,
                      selection:
                          TextSelection.collapsed(offset: state.name.length));
                  _email.value = _email.value.copyWith(
                      text: state.email,
                      selection:
                          TextSelection.collapsed(offset: state.email.length));
                  _nationalId.value = _nationalId.value.copyWith(
                      text: state.nationalId,
                      selection: TextSelection.collapsed(
                          offset: state.nationalId.length));

                  return Column(children: [
                    TextField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'نام')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'ایمیل')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: _nationalId,
                        decoration: const InputDecoration(labelText: 'کد ملی')),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                          child: OutlinedButton(
                              onPressed: state.isLoading
                                  ? null
                                  : () => context.read<ProfileCubit>().load(),
                              child: const Text('بارگیری دوباره'))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: FilledButton(
                              onPressed: state.isLoading
                                  ? null
                                  : () => context.read<ProfileCubit>().save(
                                      name: _name.text,
                                      email: _email.text,
                                      nationalId: _nationalId.text),
                              child: const Text('ذخیره'))),
                    ]),
                    if (state.isLoading)
                      const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: LinearProgressIndicator(minHeight: 2)),
                  ]);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
