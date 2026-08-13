import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';

class HomeStrings {
  const HomeStrings(this.language);

  final AppLanguage language;

  String get navHome => switch (language) {
    AppLanguage.portuguese => 'Início',
    AppLanguage.english => 'Home',
  };

  String get navPatients => switch (language) {
    AppLanguage.portuguese => 'Pacientes',
    AppLanguage.english => 'Patients',
  };

  String get navAgenda => switch (language) {
    AppLanguage.portuguese => 'Agenda',
    AppLanguage.english => 'Agenda',
  };

  String get navFinancial => switch (language) {
    AppLanguage.portuguese => 'Financeiro',
    AppLanguage.english => 'Financial',
  };

  String greetingFor(int hour) {
    if (hour < 12) {
      return switch (language) {
        AppLanguage.portuguese => 'Bom dia,',
        AppLanguage.english => 'Good morning,',
      };
    }
    if (hour < 18) {
      return switch (language) {
        AppLanguage.portuguese => 'Boa tarde,',
        AppLanguage.english => 'Good afternoon,',
      };
    }
    return switch (language) {
      AppLanguage.portuguese => 'Boa noite,',
      AppLanguage.english => 'Good evening,',
    };
  }

  String get defaultUserName => switch (language) {
    AppLanguage.portuguese => 'Fisioterapeuta',
    AppLanguage.english => 'Physiotherapist',
  };

  static const _weekdaysPt = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  static const _weekdaysEn = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String weekdayFullName(int weekday) => switch (language) {
    AppLanguage.portuguese => _weekdaysPt[weekday - 1],
    AppLanguage.english => _weekdaysEn[weekday - 1],
  };

  static const _monthsPt = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  static const _monthsEn = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String monthFullName(int month) => switch (language) {
    AppLanguage.portuguese => _monthsPt[month - 1],
    AppLanguage.english => _monthsEn[month - 1],
  };

  String dateLine(int weekday, int day, int month) => switch (language) {
    AppLanguage.portuguese =>
      '${weekdayFullName(weekday)}, $day de ${monthFullName(month)}',
    AppLanguage.english =>
      '${weekdayFullName(weekday)}, $day ${monthFullName(month)}',
  };

  static const _weekdaysShortPt = [
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
    'Dom',
  ];
  static const _weekdaysShortEn = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  String weekdayShortName(int weekday) => switch (language) {
    AppLanguage.portuguese => _weekdaysShortPt[weekday - 1],
    AppLanguage.english => _weekdaysShortEn[weekday - 1],
  };

  String get today => switch (language) {
    AppLanguage.portuguese => 'Hoje',
    AppLanguage.english => 'Today',
  };

  String get tomorrow => switch (language) {
    AppLanguage.portuguese => 'Amanhã',
    AppLanguage.english => 'Tomorrow',
  };

  String get noNamePatient => switch (language) {
    AppLanguage.portuguese => 'Sem nome',
    AppLanguage.english => 'No name',
  };

  String get scheduleStatusCompleted => switch (language) {
    AppLanguage.portuguese => 'Finalizado',
    AppLanguage.english => 'Completed',
  };

  String get scheduleStatusNext => switch (language) {
    AppLanguage.portuguese => 'Próximo',
    AppLanguage.english => 'Next',
  };

  String get scheduleStatusWaiting => switch (language) {
    AppLanguage.portuguese => 'Aguardando',
    AppLanguage.english => 'Waiting',
  };

  String get scheduleStatusCancelled => switch (language) {
    AppLanguage.portuguese => 'Cancelado',
    AppLanguage.english => 'Cancelled',
  };

  String get upcomingAppointmentsTitle => switch (language) {
    AppLanguage.portuguese => 'Próximos atendimentos',
    AppLanguage.english => 'Upcoming appointments',
  };

  String get noUpcomingAppointmentsMessage => switch (language) {
    AppLanguage.portuguese => 'Nenhum atendimento nos próximos 7 dias.',
    AppLanguage.english => 'No appointments in the next 7 days.',
  };

  String get newPatientAction => switch (language) {
    AppLanguage.portuguese => 'Novo\npaciente',
    AppLanguage.english => 'New\npatient',
  };

  String get scheduleAppointmentAction => switch (language) {
    AppLanguage.portuguese => 'Agendar\nconsulta',
    AppLanguage.english => 'Schedule\nappointment',
  };

  String get addProgressNoteAction => switch (language) {
    AppLanguage.portuguese => 'Registrar\nevolução',
    AppLanguage.english => 'Add\nprogress note',
  };

  String get addPaymentAction => switch (language) {
    AppLanguage.portuguese => 'Lançar\nreceita',
    AppLanguage.english => 'Add\npayment',
  };

  String get clinicOverviewTitle => switch (language) {
    AppLanguage.portuguese => 'Visão geral da clínica',
    AppLanguage.english => 'Clinic overview',
  };

  String get activePatientsLabel => switch (language) {
    AppLanguage.portuguese => 'Pacientes ativos',
    AppLanguage.english => 'Active patients',
  };

  String get appointmentsThisWeekLabel => switch (language) {
    AppLanguage.portuguese => 'Atendimentos\nesta semana',
    AppLanguage.english => 'Appointments\nthis week',
  };

  String get receivedThisMonthLabel => switch (language) {
    AppLanguage.portuguese => 'Recebido\neste mês',
    AppLanguage.english => 'Received\nthis month',
  };
}
