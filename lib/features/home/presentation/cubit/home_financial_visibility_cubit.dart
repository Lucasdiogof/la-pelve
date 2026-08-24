import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/utils/financial_visibility_preference.dart';

class HomeFinancialVisibilityCubit extends Cubit<bool> {
  HomeFinancialVisibilityCubit() : super(false) {
    _load();
  }

  Future<void> _load() async {
    emit(await FinancialVisibilityPreference.isHidden());
  }

  Future<void> toggle() async {
    final hidden = !state;
    emit(hidden);
    await FinancialVisibilityPreference.setHidden(hidden);
  }
}
