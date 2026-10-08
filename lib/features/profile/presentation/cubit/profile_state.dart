import 'package:equatable/equatable.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/features/profile/domain/entities/profile.dart';
import 'package:la_pelve/shared/utils/unset.dart';

class ProfileState extends Equatable {
  const ProfileState({
    this.profile,
    this.photoUrl,
    this.biometriaEnabled = false,
    this.loading = true,
    this.savingPhoto = false,
    this.failure,
  });

  final Profile? profile;
  final String? photoUrl;
  final bool biometriaEnabled;
  final bool loading;
  final bool savingPhoto;

  /// Falha ao carregar o perfil. Com [profile] presente, os dados anteriores
  /// continuam valendo; sem ele, a tela mostra erro + tentar novamente.
  final Failure? failure;

  ProfileState copyWith({
    Profile? profile,
    Object? photoUrl = kUnset,
    bool? biometriaEnabled,
    bool? loading,
    bool? savingPhoto,
    Object? failure = kUnset,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      photoUrl: unsetOr(photoUrl, this.photoUrl),
      biometriaEnabled: biometriaEnabled ?? this.biometriaEnabled,
      loading: loading ?? this.loading,
      savingPhoto: savingPhoto ?? this.savingPhoto,
      failure: unsetOr(failure, this.failure),
    );
  }

  @override
  List<Object?> get props => [
    profile,
    photoUrl,
    biometriaEnabled,
    loading,
    savingPhoto,
    failure,
  ];
}
