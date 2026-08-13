import 'package:equatable/equatable.dart';

class BiometricSettingsState extends Equatable {
  const BiometricSettingsState({this.enabled = false, this.loading = true});

  final bool enabled;
  final bool loading;

  BiometricSettingsState copyWith({bool? enabled, bool? loading}) {
    return BiometricSettingsState(
      enabled: enabled ?? this.enabled,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [enabled, loading];
}
