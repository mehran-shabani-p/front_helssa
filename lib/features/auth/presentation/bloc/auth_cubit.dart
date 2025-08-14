import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/auth_service.dart';

class AuthState extends Equatable {
  final bool isLoading;
  final bool otpSent;
  final String token;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.otpSent = false,
    this.token = '',
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? otpSent,
    String? token,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      otpSent: otpSent ?? this.otpSent,
      token: token ?? this.token,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, otpSent, token, errorMessage];
}

class AuthCubit extends Cubit<AuthState> {
  final AuthService _service;
  AuthCubit(this._service) : super(const AuthState());

  Future<void> requestOtp(String phoneNumber) async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await _service.requestOtp(phoneNumber);
      emit(state.copyWith(isLoading: false, otpSent: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> login(
      {required String phoneNumber, required String code}) async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final token = await _service.login(phoneNumber: phoneNumber, code: code);
      final sp = await SharedPreferences.getInstance();
      await sp.setString('access_token', token);
      emit(state.copyWith(isLoading: false, token: token));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void clearError() => emit(state.copyWith(errorMessage: null));
}
