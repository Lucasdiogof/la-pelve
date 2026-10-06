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
import 'package:la_pelve/shared/widgets/app_list_row.dart';
import 'package:la_pelve/shared/widgets/app_section.dart';
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

/// Divisor fino entre widgets consecutivos (nenhum antes do primeiro nem
/// depois do último).
List<Widget> _withDividers(List<Widget> children) => [
  for (var i = 0; i < children.length; i++) ...[
    if (i > 0)
      const Divider(
        height: 1,
        indent: AppSpacing.s16,
        endIndent: AppSpacing.s16,
      ),
    children[i],
  ],
];

/// Seção da ficha: overline + UM painel (surface + borda, sem sombra) com as
/// linhas separadas por divisor. Só apresentação: nenhuma regra clínica.
class InfoSection extends StatelessWidget {
  const InfoSection({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppSection(title: title, children: _withDividers(children));
  }
}

/// Linha rótulo/valor da ficha, para uso dentro de [InfoSection].
///
/// Horizontal (padrão): rótulo à esquerda e valor à direita, para valores
/// curtos (Sim/Não, números, datas, enums). O valor ocupa no máximo 60% da
/// largura; o rótulo fica com o resto e quebra em palavras inteiras.
///
/// Vertical: rótulo em cima e valor embaixo, em largura total, para textos
/// livres e listas. A escolha é SEMÂNTICA, feita por campo, nunca pelo
/// tamanho do texto.
class InfoRow extends StatelessWidget {
  const InfoRow(
    this.label,
    this.value, {
    this.language = AppLanguage.portuguese,
    this.vertical = false,
    super.key,
  });

  final String label;
  final String value;
  final AppLanguage language;
  final bool vertical;

  static const double _valueMaxShare = 0.6;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isMissing =
        value == PatientDetailFormat.naoInformado(language: language);
    final labelStyle = textTheme.bodyMedium?.copyWith(
      color: context.colors.textSecondary,
    );
    final valueStyle = textTheme.bodyLarge?.copyWith(
      color: isMissing ? context.colors.textHint : context.colors.textPrimary,
      fontStyle: isMissing ? FontStyle.italic : FontStyle.normal,
      fontWeight: isMissing ? FontWeight.w400 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      child: vertical
          ? SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: labelStyle),
                  const SizedBox(height: AppSpacing.s4),
                  Text(value, style: valueStyle),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) => Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(child: Text(label, style: labelStyle)),
                  const SizedBox(width: AppSpacing.s16),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * _valueMaxShare,
                    ),
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      style: valueStyle,
                    ),
                  ),
                ],
              ),
            ),
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
        return InfoRow(
          t.whatsappReminderFieldLabel,
          value,
          language: language,
          vertical: true,
        );
      },
    );
  }
}

/// Cabeçalho compacto e fixo do paciente (sem card): avatar, nome, "idade ·
/// sexo", telefone e, se houver alta, uma linha discreta. Campos ausentes
/// são omitidos (nunca "Não informado" aqui).
class PatientHeader extends StatelessWidget {
  const PatientHeader({
    required this.patient,
    required this.language,
    super.key,
  });

  final Patient patient;
  final AppLanguage language;

  /// Variante compacta só no cenário apertado: tela baixa e estreita com texto
  /// ampliado (ex.: 360x640 a 1,3x). Em qualquer outro caso vale o header normal.
  static bool isCompact(BuildContext context) {
    final media = MediaQuery.of(context);
    return media.size.height <= 700 &&
        media.size.width <= 380 &&
        media.textScaler.scale(10) / 10 >= 1.25;
  }

  @override
  Widget build(BuildContext context) {
    final t = PatientsStrings(language);
    final textTheme = Theme.of(context).textTheme;
    final compact = isCompact(context);
    final info = patient.personalInfo;
    final discharge = patient.discharge;
    final demographics = [
      if (info.age != null) t.ageYears(info.age!),
      if (info.gender != null) info.gender!.label(language),
    ].join(' · ');
    final phone = info.phone.trim();
    final secondary = textTheme.bodyMedium?.copyWith(
      color: context.colors.textSecondary,
    );
    final name = Text(
      info.name.isEmpty ? t.patientFallbackTitle : info.name,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: compact ? textTheme.titleMedium : textTheme.titleLarge,
    );
    final meta = [
      if (demographics.isNotEmpty) demographics,
      if (phone.isNotEmpty) phone,
      if (discharge != null)
        '${t.dischargedSectionTitle} · ${AppDateField.format(discharge.date)}',
    ];
    final padding = EdgeInsets.fromLTRB(
      AppSpacing.gutter,
      compact ? 0 : AppSpacing.s4,
      AppSpacing.gutter,
      compact ? AppSpacing.s4 : AppSpacing.s12,
    );
    if (compact) {
      // Compacto: o nome fica ao lado do avatar e os metadados ocupam a
      // largura toda embaixo, em itens que só quebram entre si (sem "·"
      // pendurado). Nenhuma informação é omitida.
      return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppInitialAvatar(name: info.name, size: 40),
                const SizedBox(width: AppSpacing.s8),
                Expanded(child: name),
              ],
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s4),
              Wrap(
                spacing: AppSpacing.s16,
                children: [
                  for (final item in meta)
                    Text(
                      item,
                      style: textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    }
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppInitialAvatar(name: info.name, size: 48),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                name,
                for (final item in meta) Text(item, style: secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Uma gestação dentro da seção Obstétrico: título discreto + linhas com
/// divisor, sem card próprio.
class PregnancyBlock extends StatelessWidget {
  const PregnancyBlock({
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
    final rows = <Widget>[
      InfoRow(
        t.fieldPregnancyLoss,
        PatientDetailFormat.yesNo(pregnancy.pregnancyLoss, language: language),
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
          vertical: true,
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
            vertical: true,
          ),
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s16,
            AppSpacing.s16,
            AppSpacing.s4,
          ),
          child: Text(
            t.pregnancyNumber(index + 1),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        ..._withDividers(rows),
      ],
    );
  }
}
