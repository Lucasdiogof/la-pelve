import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/utils/biometric_preference.dart';
import 'package:fisioterapia_pelvica/features/profile/domain/repositories/profile_repository.dart';
import 'package:fisioterapia_pelvica/features/profile/presentation/cubit/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileState()) {
    load();
  }

  final ProfileRepository _repository;

  Future<void> load() async {
    final biometria = BiometricPreference.isEnabled();
    final profileResult = await _repository.getCurrent();
    final biometriaEnabled = await biometria;
    switch (profileResult) {
      case Success(:final data):
        emit(
          state.copyWith(
            profile: data,
            biometriaEnabled: biometriaEnabled,
            loading: false,
          ),
        );
        if (data.fotoPath != null) {
          final urlResult = await _repository.getPhotoUrl(data.fotoPath!);
          if (urlResult is Success<String>) {
            emit(state.copyWith(photoUrl: urlResult.data));
          }
        }
      case Error():
        emit(state.copyWith(loading: false));
    }
  }

  Future<Result<String>> uploadPhoto({
    required Uint8List bytes,
    required String contentType,
  }) async {
    emit(state.copyWith(savingPhoto: true));
    final result = await _repository.uploadPhoto(
      bytes: bytes,
      contentType: contentType,
    );
    emit(state.copyWith(savingPhoto: false));
    if (result case Success(:final data)) {
      final urlResult = await _repository.getPhotoUrl(data);
      if (urlResult is Success<String>) {
        emit(state.copyWith(photoUrl: urlResult.data));
      }
    }
    return result;
  }

  void applyNome(String nome) {
    final profile = state.profile;
    if (profile == null) return;
    emit(state.copyWith(profile: profile.copyWith(nome: nome)));
  }

  Future<void> refreshBiometria() async {
    final enabled = await BiometricPreference.isEnabled();
    emit(state.copyWith(biometriaEnabled: enabled));
  }
}
