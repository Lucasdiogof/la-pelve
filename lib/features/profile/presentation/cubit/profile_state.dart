import 'package:equatable/equatable.dart';
import 'package:fisioterapia_pelvica/features/profile/domain/entities/profile.dart';
import 'package:fisioterapia_pelvica/shared/utils/unset.dart';

class ProfileState extends Equatable {
  const ProfileState({
    this.profile,
    this.photoUrl,
    this.biometriaEnabled = false,
    this.loading = true,
    this.savingPhoto = false,
  });

  final Profile? profile;
  final String? photoUrl;
  final bool biometriaEnabled;
  final bool loading;
  final bool savingPhoto;

  ProfileState copyWith({
    Profile? profile,
    Object? photoUrl = kUnset,
    bool? biometriaEnabled,
    bool? loading,
    bool? savingPhoto,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      photoUrl: unsetOr(photoUrl, this.photoUrl),
      biometriaEnabled: biometriaEnabled ?? this.biometriaEnabled,
      loading: loading ?? this.loading,
      savingPhoto: savingPhoto ?? this.savingPhoto,
    );
  }

  @override
  List<Object?> get props => [
    profile,
    photoUrl,
    biometriaEnabled,
    loading,
    savingPhoto,
  ];
}
