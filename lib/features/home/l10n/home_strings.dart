import 'package:la_pelve/core/l10n/app_language.dart';

class HomeStrings {
  const HomeStrings(this.language);

  final AppLanguage language;

  String get navHome => switch (language) {
    AppLanguage.portuguese => 'Início',
    AppLanguage.english => 'Home',
    AppLanguage.spanish => 'Inicio',
  };

  String get navPatients => switch (language) {
    AppLanguage.portuguese => 'Pacientes',
    AppLanguage.english => 'Patients',
    AppLanguage.spanish => 'Pacientes',
  };

  String get navAgenda => switch (language) {
    AppLanguage.portuguese => 'Agenda',
    AppLanguage.english => 'Agenda',
    AppLanguage.spanish => 'Agenda',
  };

  String get navFinancial => switch (language) {
    AppLanguage.portuguese => 'Financeiro',
    AppLanguage.english => 'Financial',
    AppLanguage.spanish => 'Finanzas',
  };

  String greetingFor(int hour) {
    if (hour < 12) {
      return switch (language) {
        AppLanguage.portuguese => 'Bom dia,',
        AppLanguage.english => 'Good morning,',
        AppLanguage.spanish => 'Buenos días,',
      };
    }
    if (hour < 18) {
      return switch (language) {
        AppLanguage.portuguese => 'Boa tarde,',
        AppLanguage.english => 'Good afternoon,',
        AppLanguage.spanish => 'Buenas tardes,',
      };
    }
    return switch (language) {
      AppLanguage.portuguese => 'Boa noite,',
      AppLanguage.english => 'Good evening,',
      AppLanguage.spanish => 'Buenas noches,',
    };
  }

  String get defaultUserName => switch (language) {
    AppLanguage.portuguese => 'Fisioterapeuta',
    AppLanguage.english => 'Physiotherapist',
    AppLanguage.spanish => 'Fisioterapeuta',
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

  static const _weekdaysEs = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  String weekdayFullName(int weekday) => switch (language) {
    AppLanguage.portuguese => _weekdaysPt[weekday - 1],
    AppLanguage.english => _weekdaysEn[weekday - 1],
    AppLanguage.spanish => _weekdaysEs[weekday - 1],
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

  static const _monthsEs = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  String monthFullName(int month) => switch (language) {
    AppLanguage.portuguese => _monthsPt[month - 1],
    AppLanguage.english => _monthsEn[month - 1],
    AppLanguage.spanish => _monthsEs[month - 1],
  };

  String dateLine(int weekday, int day, int month) => switch (language) {
    AppLanguage.portuguese =>
      '${weekdayFullName(weekday)}, $day de ${monthFullName(month)}',
    AppLanguage.english =>
      '${weekdayFullName(weekday)}, $day ${monthFullName(month)}',
    AppLanguage.spanish =>
      '${weekdayFullName(weekday)}, $day de ${monthFullName(month)}',
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
  static const _weekdaysShortEs = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];

  String weekdayShortName(int weekday) => switch (language) {
    AppLanguage.portuguese => _weekdaysShortPt[weekday - 1],
    AppLanguage.english => _weekdaysShortEn[weekday - 1],
    AppLanguage.spanish => _weekdaysShortEs[weekday - 1],
  };

  String get today => switch (language) {
    AppLanguage.portuguese => 'Hoje',
    AppLanguage.english => 'Today',
    AppLanguage.spanish => 'Hoy',
  };

  String get tomorrow => switch (language) {
    AppLanguage.portuguese => 'Amanhã',
    AppLanguage.english => 'Tomorrow',
    AppLanguage.spanish => 'Mañana',
  };

  String get noNamePatient => switch (language) {
    AppLanguage.portuguese => 'Sem nome',
    AppLanguage.english => 'No name',
    AppLanguage.spanish => 'Sin nombre',
  };

  String get scheduleStatusCompleted => switch (language) {
    AppLanguage.portuguese => 'Finalizado',
    AppLanguage.english => 'Completed',
    AppLanguage.spanish => 'Finalizado',
  };

  String get scheduleStatusNext => switch (language) {
    AppLanguage.portuguese => 'Próximo',
    AppLanguage.english => 'Next',
    AppLanguage.spanish => 'Próximo',
  };

  String get scheduleStatusWaiting => switch (language) {
    AppLanguage.portuguese => 'Aguardando',
    AppLanguage.english => 'Waiting',
    AppLanguage.spanish => 'Esperando',
  };

  String get scheduleStatusCancelled => switch (language) {
    AppLanguage.portuguese => 'Cancelado',
    AppLanguage.english => 'Cancelled',
    AppLanguage.spanish => 'Cancelado',
  };

  String get upcomingAppointmentsTitle => switch (language) {
    AppLanguage.portuguese => 'Próximos atendimentos',
    AppLanguage.english => 'Upcoming appointments',
    AppLanguage.spanish => 'Próximas citas',
  };

  String get viewAgendaAction => switch (language) {
    AppLanguage.portuguese => 'Ver agenda',
    AppLanguage.english => 'View schedule',
    AppLanguage.spanish => 'Ver agenda',
  };

  String get quickActionsTitle => switch (language) {
    AppLanguage.portuguese => 'Ações rápidas',
    AppLanguage.english => 'Quick actions',
    AppLanguage.spanish => 'Acciones rápidas',
  };

  String get noUpcomingAppointmentsMessage => switch (language) {
    AppLanguage.portuguese => 'Nenhum atendimento agendado.',
    AppLanguage.english => 'No upcoming appointments.',
    AppLanguage.spanish => 'Ninguna cita programada.',
  };

  String get newPatientAction => switch (language) {
    AppLanguage.portuguese => 'Novo\npaciente',
    AppLanguage.english => 'New\npatient',
    AppLanguage.spanish => 'Nuevo\npaciente',
  };

  String get scheduleAppointmentAction => switch (language) {
    AppLanguage.portuguese => 'Agendar\nconsulta',
    AppLanguage.english => 'Schedule\nappointment',
    AppLanguage.spanish => 'Agendar\ncita',
  };

  String get addProgressNoteAction => switch (language) {
    AppLanguage.portuguese => 'Registrar\nevolução',
    AppLanguage.english => 'Add\nprogress note',
    AppLanguage.spanish => 'Registrar\nevolución',
  };

  String get addPaymentAction => switch (language) {
    AppLanguage.portuguese => 'Lançar\nreceita',
    AppLanguage.english => 'Add\npayment',
    AppLanguage.spanish => 'Registrar\npago',
  };

  String get clinicOverviewTitle => switch (language) {
    AppLanguage.portuguese => 'Visão geral da clínica',
    AppLanguage.english => 'Clinic overview',
    AppLanguage.spanish => 'Resumen de la clínica',
  };

  String get activePatientsLabel => switch (language) {
    AppLanguage.portuguese => 'Pacientes ativos',
    AppLanguage.english => 'Active patients',
    AppLanguage.spanish => 'Pacientes activos',
  };

  String get appointmentsThisWeekLabel => switch (language) {
    AppLanguage.portuguese => 'Atendimentos\nesta semana',
    AppLanguage.english => 'Appointments\nthis week',
    AppLanguage.spanish => 'Citas\nesta semana',
  };

  String get receivedThisMonthLabel => switch (language) {
    AppLanguage.portuguese => 'Recebido\neste mês',
    AppLanguage.english => 'Received\nthis month',
    AppLanguage.spanish => 'Recibido\neste mes',
  };

  String get showFinancialValueTooltip => switch (language) {
    AppLanguage.portuguese => 'Mostrar valor',
    AppLanguage.english => 'Show value',
    AppLanguage.spanish => 'Mostrar valor',
  };

  String get hideFinancialValueTooltip => switch (language) {
    AppLanguage.portuguese => 'Esconder valor',
    AppLanguage.english => 'Hide value',
    AppLanguage.spanish => 'Ocultar valor',
  };
}
