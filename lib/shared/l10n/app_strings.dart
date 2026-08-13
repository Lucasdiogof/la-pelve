import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/features/agenda/l10n/agenda_strings.dart';
import 'package:fisioterapia_pelvica/features/auth/l10n/auth_strings.dart';
import 'package:fisioterapia_pelvica/features/financial/l10n/financial_strings.dart';
import 'package:fisioterapia_pelvica/features/home/l10n/home_strings.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_strings.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_wizard_strings_a.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_wizard_strings_b.dart';
import 'package:fisioterapia_pelvica/features/profile/l10n/profile_strings.dart';
import 'package:fisioterapia_pelvica/shared/l10n/shared_strings.dart';

class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  AgendaStrings get agenda => AgendaStrings(language);
  AuthStrings get auth => AuthStrings(language);
  FinancialStrings get financial => FinancialStrings(language);
  HomeStrings get home => HomeStrings(language);
  PatientsStrings get patients => PatientsStrings(language);
  PatientsWizardStringsA get patientsWizardA =>
      PatientsWizardStringsA(language);
  PatientsWizardStringsB get patientsWizardB =>
      PatientsWizardStringsB(language);
  ProfileStrings get profile => ProfileStrings(language);
  SharedStrings get shared => SharedStrings(language);
}

extension AppStringsContext on BuildContext {
  AppStrings get strings => AppStrings(watch<LocaleCubit>().state);
}
