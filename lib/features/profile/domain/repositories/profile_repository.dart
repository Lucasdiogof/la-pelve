import 'dart:typed_data';

import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/features/profile/domain/entities/profile.dart';

abstract class ProfileRepository {
  Future<Result<Profile>> getCurrent();

  Future<Result<void>> updateName(String name);

  Future<Result<String>> uploadPhoto({
    required Uint8List bytes,
    required String contentType,
  });

  Future<Result<String>> getPhotoUrl(String photoPath);
}
