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
              'nome': '',
              'crefito': '',
              'telefone': '',
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
      return const Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[ProfileRepositorySupabase.getCurrent] $e\n$st');
      return const Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> updateNome(String nome) async {
    try {
      final userId = _client.auth.currentUser!.id;
      await _client.from('profiles').update({'nome': nome}).eq('id', userId);
      _cachedProfile = _cachedProfile?.copyWith(nome: nome);
      return const Success(null);
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[ProfileRepositorySupabase.updateNome] code=${e.code} msg=${e.message}\n$st',
      );
      return const Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[ProfileRepositorySupabase.updateNome] $e\n$st');
      return const Error(UnexpectedFailure());
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
          .update({'foto_path': path})
          .eq('id', userId);
      _cachedProfile = _cachedProfile?.copyWith(fotoPath: path);
      _cachedPhotoUrl = null;
      _cachedPhotoUrlPath = null;
      return Success(path);
    } on StorageException catch (e, st) {
      debugPrint(
        '[ProfileRepositorySupabase.uploadPhoto] storage statusCode=${e.statusCode} msg=${e.message}\n$st',
      );
      return const Error(ServerFailure());
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[ProfileRepositorySupabase.uploadPhoto] code=${e.code} msg=${e.message}\n$st',
      );
      return const Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[ProfileRepositorySupabase.uploadPhoto] $e\n$st');
      return const Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<String>> getPhotoUrl(String fotoPath) async {
    if (_cachedPhotoUrlPath == fotoPath && _cachedPhotoUrl != null) {
      return Success(_cachedPhotoUrl!);
    }
    try {
      final url = await _client.storage
          .from(_bucket)
          .createSignedUrl(fotoPath, 3600);
      _cachedPhotoUrl = url;
      _cachedPhotoUrlPath = fotoPath;
      return Success(url);
    } on StorageException catch (e, st) {
      debugPrint(
        '[ProfileRepositorySupabase.getPhotoUrl] storage statusCode=${e.statusCode} msg=${e.message}\n$st',
      );
      return const Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[ProfileRepositorySupabase.getPhotoUrl] $e\n$st');
      return const Error(UnexpectedFailure());
    }
  }
}
