import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/utils/biometric_preference.dart';
import 'package:la_pelve/features/profile/domain/repositories/profile_repository.dart';
import 'package:la_pelve/features/profile/presentation/cubit/profile_state.dart';

/// Perfil do profissional logado. Singleton: [reset] no logout/troca de
/// usuário apaga o perfil (e a foto) da conta anterior e invalida respostas
/// em andamento. A carga é explícita ([ensureLoaded]), nunca no construtor.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileState());

  final ProfileRepository _repository;
  int _generation = 0;
  Future<void>? _inFlight;

  /// Carrega se ainda não há perfil; reaproveita uma carga em andamento.
  Future<void> ensureLoaded() {
    if (state.profile != null) return Future.value();
    return _inFlight ?? load();
  }

  Future<void> load() {
    late final Future<void> run;
    run = _load(++_generation).whenComplete(() {
      if (identical(_inFlight, run)) _inFlight = null;
    });
    _inFlight = run;
    return run;
  }

  void reset() {
    _generation++;
    _inFlight = null;
    if (!isClosed) emit(const ProfileState());
  }

  Future<void> _load(int generation) async {
    if (state.profile == null && !state.loading) {
      emit(state.copyWith(loading: true, failure: null));
    }
    final biometria = BiometricPreference.isEnabled();
    final profileResult = await _repository.getCurrent();
    final biometriaEnabled = await biometria;
    if (isClosed || generation != _generation) return;
    switch (profileResult) {
      case Success(:final data):
        emit(
          state.copyWith(
            profile: data,
            biometriaEnabled: biometriaEnabled,
            loading: false,
            failure: null,
          ),
        );
        if (data.photoPath != null) {
          final urlResult = await _repository.getPhotoUrl(data.photoPath!);
          if (isClosed || generation != _generation) return;
          if (urlResult is Success<String>) {
            emit(state.copyWith(photoUrl: urlResult.data));
          }
        }
      case Error(:final failure):
        emit(state.copyWith(loading: false, failure: failure));
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

  Future<Result<void>> removePhoto() async {
    emit(state.copyWith(savingPhoto: true));
    final result = await _repository.removePhoto();
    if (result case Success()) {
      emit(
        state.copyWith(
          profile: state.profile?.copyWith(photoPath: null),
          photoUrl: null,
          savingPhoto: false,
        ),
      );
    } else {
      emit(state.copyWith(savingPhoto: false));
    }
    return result;
  }

  void applyNome(String name) {
    final profile = state.profile;
    if (profile == null) return;
    emit(state.copyWith(profile: profile.copyWith(name: name)));
  }

  Future<void> refreshBiometria() async {
    final enabled = await BiometricPreference.isEnabled();
    emit(state.copyWith(biometriaEnabled: enabled));
  }
}
