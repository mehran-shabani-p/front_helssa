import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/visit_service.dart';

class VisitsState extends Equatable {
  final bool isLoading;
  final List<Map<String, dynamic>> items;
  final String? errorMessage;

  const VisitsState({this.isLoading = false, this.items = const [], this.errorMessage});

  VisitsState copyWith({bool? isLoading, List<Map<String, dynamic>>? items, String? errorMessage}) {
    return VisitsState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, items, errorMessage];
}

class VisitsCubit extends Cubit<VisitsState> {
  final VisitService _service;
  VisitsCubit(this._service) : super(const VisitsState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('access_token') ?? '';
      final list = await _service.listVisits(token);
      emit(state.copyWith(isLoading: false, items: list));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> requestVisit(String description) async {
    if (description.trim().isEmpty) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('access_token') ?? '';
      await _service.requestVisit(token, {'description': description.trim()});
      await load();
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void clearError() => emit(state.copyWith(errorMessage: null));
}