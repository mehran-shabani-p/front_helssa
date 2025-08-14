import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/profile_service.dart';


class ProfileState extends Equatable {
  final bool isLoading;
  final String name;
  final String email;
  final String nationalId;
  final String? errorMessage;
  final bool saved;

  const ProfileState({
    this.isLoading = false,
    this.name = '',
    this.email = '',
    this.nationalId = '',
    this.errorMessage,
    this.saved = false,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? name,
    String? email,
    String? nationalId,
    String? errorMessage,
    bool? saved,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      name: name ?? this.name,
      email: email ?? this.email,
      nationalId: nationalId ?? this.nationalId,
      errorMessage: errorMessage,
      saved: saved ?? this.saved,
    );
  }

  @override
  List<Object?> get props => [isLoading, name, email, nationalId, errorMessage, saved];
}

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileService _service;
  ProfileCubit(this._service) : super(const ProfileState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, errorMessage: null, saved: false));
    try {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('access_token') ?? '';
      final p = await _service.fetchProfile(token);
      emit(state.copyWith(
        isLoading: false,
        name: (p['name'] ?? '').toString(),
        email: (p['email'] ?? '').toString(),
        nationalId: (p['nationalId'] ?? '').toString(),
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> save({required String name, required String email, required String nationalId}) async {
    emit(state.copyWith(isLoading: true, errorMessage: null, saved: false));
    try {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('access_token') ?? '';
      await _service.updateProfile(token, {
        'name': name.trim(),
        'email': email.trim(),
        'nationalId': nationalId.trim(),
      });
      emit(state.copyWith(isLoading: false, name: name, email: email, nationalId: nationalId, saved: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void clearSaved() => emit(state.copyWith(saved: false));
  void clearError() => emit(state.copyWith(errorMessage: null));
}
