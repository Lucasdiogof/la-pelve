import 'package:equatable/equatable.dart';

const String kWhatsappChannel = 'whatsapp';
const String kAppointmentReminderPurpose = 'appointment_reminder';
const String kPatientFormConsentSource = 'patient_form';

class PatientConsent extends Equatable {
  const PatientConsent({
    required this.id,
    required this.patientId,
    required this.channel,
    required this.purpose,
    required this.contactValue,
    required this.grantedAt,
    this.revokedAt,
  });

  final String id;
  final String patientId;
  final String channel;
  final String purpose;
  final String contactValue;
  final DateTime grantedAt;
  final DateTime? revokedAt;

  bool get isActive => revokedAt == null;

  factory PatientConsent.fromJson(Map<String, dynamic> json) =>
      PatientConsent(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        channel: json['channel'] as String,
        purpose: json['purpose'] as String,
        contactValue: json['contact_value'] as String,
        grantedAt: DateTime.parse(json['granted_at'] as String),
        revokedAt: json['revoked_at'] == null
            ? null
            : DateTime.parse(json['revoked_at'] as String),
      );

  @override
  List<Object?> get props => [
    id,
    patientId,
    channel,
    purpose,
    contactValue,
    grantedAt,
    revokedAt,
  ];
}
