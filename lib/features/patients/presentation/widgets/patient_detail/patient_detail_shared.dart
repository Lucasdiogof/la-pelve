import 'package:flutter/material.dart';
import 'package:la_pelve/core/di/injection_container.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/app_language.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/features/patients/domain/entities/patient_consent.dart';
import 'package:la_pelve/features/patients/domain/entities/pregnancy.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/domain/entities/patient_enums.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_consent_repository.dart';
import 'package:la_pelve/features/patients/l10n/patients_strings.dart';
import 'package:la_pelve/shared/widgets/app_date_field.dart';
import 'package:la_pelve/shared/utils/money_format.dart';

class PatientDetailFormat {
  const PatientDetailFormat._();

  static String naoInformado({AppLanguage language = AppLanguage.portuguese}) =>
      PatientsStrings(language).notInformed;

  static String text(
    String? value, {
    AppLanguage language = AppLanguage.portuguese,
  }) => (value == null || value.trim().isEmpty)
      ? naoInformado(language: language)
      : value.trim();

  static String yesNo(
    bool? value, {
    AppLanguage language = AppLanguage.portuguese,
  }) {
    final t = PatientsStrings(language);
    return switch (value) {
      true => t.yes,
      false => t.no,
      null => naoInformado(language: language),
    };
  }

  static String intValue(
    int? value, {
    AppLanguage language = AppLanguage.portuguese,
  }) => value?.toString() ?? naoInformado(language: language);

  static String dateValue(
    DateTime? value, {
    AppLanguage language = AppLanguage.portuguese,
  }) => value == null
      ? naoInformado(language: language)
      : AppDateField.format(value);

  static String money(
    double? value, {
    AppLanguage language = AppLanguage.portuguese,
  }) => value == null
      ? naoInformado(language: language)
      : formatBrl(value, language: language);

  static String enumValue<T>(
    T? value,
    String Function(T) label, {
    AppLanguage language = AppLanguage.portuguese,
  }) => value == null ? naoInformado(language: language) : label(value);
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.s32,
        bottom: AppSpacing.s8,
      ),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(
          context,
        ).textTheme.overline.copyWith(color: context.colors.textSecondary),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow(
    this.label,
    this.value, {
    this.language = AppLanguage.portuguese,
    this.showDivider = false,
    super.key,
  });

  final String label;
  final String value;
  final AppLanguage language;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isMissing =
        value == PatientDetailFormat.naoInformado(language: language);
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyLarge?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: textTheme.bodyLarge?.copyWith(
                color: isMissing
                    ? context.colors.textHint
                    : context.colors.textPrimary,
                fontStyle: isMissing ? FontStyle.italic : FontStyle.normal,
                fontWeight: isMissing ? FontWeight.w400 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
    if (!showDivider) return row;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [row, const Divider(height: 1)],
    );
  }
}

/// Mostra, discretamente, se o paciente tem consentimento ativo para
/// lembretes de agendamento pelo WhatsApp. Só leitura: não altera o banco.
class WhatsappReminderStatusRow extends StatelessWidget {
  const WhatsappReminderStatusRow({
    required this.patientId,
    this.language = AppLanguage.portuguese,
    super.key,
  });

  final String patientId;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final t = PatientsStrings(language);
    return FutureBuilder<Result<PatientConsent?>>(
      future: sl<PatientConsentRepository>().getActive(
        patientId: patientId,
        channel: kWhatsappChannel,
        purpose: kAppointmentReminderPurpose,
      ),
      builder: (context, snapshot) {
        final result = snapshot.data;
        final consent = switch (result) {
          Success(:final data) => data,
          _ => null,
        };
        final value = consent == null
            ? t.whatsappReminderInactive
            : t.whatsappReminderActiveSince(
                AppDateField.format(consent.grantedAt),
              );
        return InfoRow(t.whatsappReminderFieldLabel, value, language: language);
      },
    );
  }
}

class DischargeBanner extends StatelessWidget {
  const DischargeBanner({
    required this.discharge,
    required this.onReopen,
    required this.language,
    super.key,
  });

  final Discharge discharge;
  final VoidCallback onReopen;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final t = PatientsStrings(language);
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.textHint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.event_busy_outlined, color: context.colors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.treatmentClosedOn(AppDateField.format(discharge.date)),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  t.reasonLabel(discharge.reason.label(language)),
                  style: TextStyle(color: context.colors.textSecondary),
                ),
                if ((discharge.finalNote ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    discharge.finalNote!,
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          TextButton(onPressed: onReopen, child: Text(t.reopenLabel)),
        ],
      ),
    );
  }
}

class PregnancyCard extends StatelessWidget {
  const PregnancyCard({
    required this.index,
    required this.pregnancy,
    required this.language,
    super.key,
  });

  final int index;
  final Pregnancy pregnancy;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final t = PatientsStrings(language);
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.pregnancyNumber(index + 1),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: 8),
          InfoRow(
            t.fieldPregnancyLoss,
            PatientDetailFormat.yesNo(
              pregnancy.pregnancyLoss,
              language: language,
            ),
            language: language,
          ),
          if (pregnancy.pregnancyLoss == true)
            InfoRow(
              t.fieldLossDetail,
              PatientDetailFormat.text(
                pregnancy.lossDescription,
                language: language,
              ),
              language: language,
            )
          else if (pregnancy.pregnancyLoss == false) ...[
            InfoRow(
              t.fieldDeliveryMethod,
              PatientDetailFormat.enumValue(
                pregnancy.deliveryMethod,
                (v) => v.label(language),
                language: language,
              ),
              language: language,
            ),
            if (pregnancy.deliveryMethod == DeliveryMethod.vaginal)
              InfoRow(
                t.fieldDeliveryComplication,
                PatientDetailFormat.enumValue(
                  pregnancy.deliveryComplication,
                  (v) => v.label(language),
                  language: language,
                ),
                language: language,
              ),
            if (pregnancy.deliveryMethod == DeliveryMethod.vaginal)
              InfoRow(
                t.fieldForcepsOrVacuum,
                PatientDetailFormat.yesNo(
                  pregnancy.forcepsOrVacuumUse,
                  language: language,
                ),
                language: language,
              ),
            InfoRow(
              t.fieldApproxBabyWeight,
              PatientDetailFormat.text(
                pregnancy.approximateBabyWeight,
                language: language,
              ),
              language: language,
            ),
            InfoRow(
              t.fieldHadComplications,
              PatientDetailFormat.yesNo(
                pregnancy.hadComplications,
                language: language,
              ),
              language: language,
            ),
            if (pregnancy.hadComplications == true)
              InfoRow(
                t.fieldComplicationDetail,
                PatientDetailFormat.text(
                  pregnancy.complicationDescription,
                  language: language,
                ),
                language: language,
              ),
          ],
        ],
      ),
    );
  }
}
