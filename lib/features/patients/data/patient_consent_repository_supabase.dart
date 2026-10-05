import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/features/patients/domain/entities/patient_consent.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_consent_repository.dart';

/// Nenhuma chamada deste repositório pode ficar pendente para sempre: a UI
/// (ex.: carregar o consentimento ativo ao abrir o formulário de edição)
/// depende de que toda chamada eventualmente resolva em Success ou Error.
const Duration _kPatientConsentQueryTimeout = Duration(seconds: 10);

class PatientConsentRepositorySupabase implements PatientConsentRepository {
  PatientConsentRepositorySupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<PatientConsent?>> getActive({
    required String patientId,
    required String channel,
    required String purpose,
  }) async {
    try {
      final row = await _client
          .from('patient_consents')
          .select()
          .eq('patient_id', patientId)
          .eq('channel', channel)
          .eq('purpose', purpose)
          .filter('revoked_at', 'is', null)
          .maybeSingle()
          .timeout(_kPatientConsentQueryTimeout);
      return Success(row == null ? null : PatientConsent.fromJson(row));
    } on TimeoutException catch (e, st) {
      debugPrint('[PatientConsentRepositorySupabase.getActive] timeout\n$e\n$st');
      return Error(NetworkFailure());
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[PatientConsentRepositorySupabase.getActive] code=${e.code} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[PatientConsentRepositorySupabase.getActive] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<PatientConsent>> grant({
    required String patientId,
    required String channel,
    required String purpose,
    required String contactValue,
    required String source,
  }) async {
    try {
      final row = await _client
          .from('patient_consents')
          .insert({
            'patient_id': patientId,
            'channel': channel,
            'purpose': purpose,
            'contact_value': contactValue,
            'source': source,
          })
          .select()
          .single()
          .timeout(_kPatientConsentQueryTimeout);
      return Success(PatientConsent.fromJson(row));
    } on TimeoutException catch (e, st) {
      debugPrint('[PatientConsentRepositorySupabase.grant] timeout\n$e\n$st');
      return Error(NetworkFailure());
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[PatientConsentRepositorySupabase.grant] code=${e.code} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[PatientConsentRepositorySupabase.grant] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> revoke(String consentId) async {
    try {
      await _client
          .from('patient_consents')
          .update({'revoked_at': DateTime.now().toIso8601String()})
          .eq('id', consentId)
          .timeout(_kPatientConsentQueryTimeout);
      return const Success(null);
    } on TimeoutException catch (e, st) {
      debugPrint('[PatientConsentRepositorySupabase.revoke] timeout\n$e\n$st');
      return Error(NetworkFailure());
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[PatientConsentRepositorySupabase.revoke] code=${e.code} msg=${e.message}\n$st',
      );
      return Error(ServerFailure());
    } catch (e, st) {
      debugPrint('[PatientConsentRepositorySupabase.revoke] $e\n$st');
      return Error(UnexpectedFailure());
    }
  }
}
