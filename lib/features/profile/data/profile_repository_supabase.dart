import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fisioterapia_pelvica/core/error/failures.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/features/profile/domain/entities/profile.dart';
import 'package:fisioterapia_pelvica/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositorySupabase implements ProfileRepository {
  ProfileRepositorySupabase(this._client);

  final SupabaseClient _client;

  static const _bucket = 'avatars';

  Profile? _cachedProfile;
  String? _cachedPhotoUrl;
  String? _cachedPhotoUrlPath;

  @override
  Future<Result<Profile>> getCurrent() async {
    final cached = _cachedProfile;
    if (cached != null) return Success(cached);
    try {
      final user = _client.auth.currentUser!;
      final rows = await _client.from('profiles').select().eq('id', user.id);
      if (rows.isEmpty) {
        final inserted = await _client
            .from('profiles')
            .insert({
              'id': user.id,
              'name': '',
              'crefito': '',
              'phone': '',
              'email': user.email ?? '',
            })
            .select()
            .single();
        _cachedProfile = Profile.fromJson(inserted);
        return Success(_cachedProfile!);
      }
      _cachedProfile = Profile.fromJson(rows.first);
      return Success(_cachedProfile!);
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[ProfileRepositorySupabase.getCurrent] code=${e.code} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[ProfileRepositorySupabase.getCurrent] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> updateName(String name) async {
    try {
      final userId = _client.auth.currentUser!.id;
      await _client.from('profiles').update({'name': name}).eq('id', userId);
      _cachedProfile = _cachedProfile?.copyWith(name: name);
      return const Success(null);
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[ProfileRepositorySupabase.updateName] code=${e.code} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[ProfileRepositorySupabase.updateName] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<String>> uploadPhoto({
    required Uint8List bytes,
    required String contentType,
  }) async {
    try {
      final userId = _client.auth.currentUser!.id;
      final ext = contentType == 'image/png' ? 'png' : 'jpg';
      final path = '$userId/avatar.$ext';
      await _client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );
      await _client
          .from('profiles')
          .update({'photo_path': path})
          .eq('id', userId);
      _cachedProfile = _cachedProfile?.copyWith(photoPath: path);
      _cachedPhotoUrl = null;
      _cachedPhotoUrlPath = null;
      return Success(path);
    } on StorageException catch (e, st) {
      debugPrint(
        '[ProfileRepositorySupabase.uploadPhoto] storage statusCode=${e.statusCode} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[ProfileRepositorySupabase.uploadPhoto] code=${e.code} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[ProfileRepositorySupabase.uploadPhoto] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> removePhoto() async {
    try {
      final userId = _client.auth.currentUser!.id;
      final files = await _client.storage.from(_bucket).list(path: userId);
      if (files.isNotEmpty) {
        await _client.storage
            .from(_bucket)
            .remove(files.map((f) => '$userId/${f.name}').toList());
      }
      await _client
          .from('profiles')
          .update({'photo_path': null})
          .eq('id', userId);
      _cachedProfile = _cachedProfile?.copyWith(photoPath: null);
      _cachedPhotoUrl = null;
      _cachedPhotoUrlPath = null;
      return const Success(null);
    } on StorageException catch (e, st) {
      debugPrint(
        '[ProfileRepositorySupabase.removePhoto] storage statusCode=${e.statusCode} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[ProfileRepositorySupabase.removePhoto] code=${e.code} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[ProfileRepositorySupabase.removePhoto] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<String>> getPhotoUrl(String photoPath) async {
    if (_cachedPhotoUrlPath == photoPath && _cachedPhotoUrl != null) {
      return Success(_cachedPhotoUrl!);
    }
    try {
      final url = await _client.storage
          .from(_bucket)
          .createSignedUrl(photoPath, 3600);
      _cachedPhotoUrl = url;
      _cachedPhotoUrlPath = photoPath;
      return Success(url);
    } on StorageException catch (e, st) {
      debugPrint(
        '[ProfileRepositorySupabase.getPhotoUrl] storage statusCode=${e.statusCode} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[ProfileRepositorySupabase.getPhotoUrl] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }
}
