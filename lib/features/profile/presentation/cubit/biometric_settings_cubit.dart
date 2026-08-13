import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/utils/biometric_preference.dart';
import 'package:fisioterapia_pelvica/features/profile/presentation/cubit/biometric_settings_state.dart';

class BiometricSettingsCubit extends Cubit<BiometricSettingsState> {
  BiometricSettingsCubit() : super(const BiometricSettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final enabled = await BiometricPreference.isEnabled();
    emit(state.copyWith(enabled: enabled, loading: false));
  }

  Future<void> setEnabled(bool value) async {
    await BiometricPreference.setEnabled(value);
    emit(state.copyWith(enabled: value));
  }
}
