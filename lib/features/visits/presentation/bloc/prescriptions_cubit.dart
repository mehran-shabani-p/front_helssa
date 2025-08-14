import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/visit_service.dart';

class PrescriptionsState extends Equatable {
  final bool isLoading;
  final List<Map<String, dynamic>> items;
  final String? errorMessage;

  const PrescriptionsState({this.isLoading = false, this.items = const [], this.errorMessage});

  PrescriptionsState copyWith({bool? isLoading, List<Map<String, dynamic>>? items, String? errorMessage}) {
    return PrescriptionsState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, items, errorMessage];
}

class PrescriptionsCubit extends Cubit<PrescriptionsState> {
  final VisitService _service;
  PrescriptionsCubit(this._service) : super(const PrescriptionsState());

  Future<void> load(String nationalCode) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('access_token') ?? '';
      final list = await _service.previousPrescriptions(token, nationalCode.trim());
      emit(state.copyWith(isLoading: false, items: list));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void clearError() => emit(state.copyWith(errorMessage: null));
}