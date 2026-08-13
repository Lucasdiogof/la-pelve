import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/attachment.dart';

class PatientAttachmentsState {
  const PatientAttachmentsState({this.result, this.uploading = false});

  final Result<List<Attachment>>? result;
  final bool uploading;

  PatientAttachmentsState copyWith({
    Result<List<Attachment>>? result,
    bool clearResult = false,
    bool? uploading,
  }) {
    return PatientAttachmentsState(
      result: clearResult ? null : (result ?? this.result),
      uploading: uploading ?? this.uploading,
    );
  }
}
