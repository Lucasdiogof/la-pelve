import 'package:fisioterapia_pelvica/core/l10n/app_language.dart';

class AgendaStrings {
  const AgendaStrings(this.language);

  final AppLanguage language;

  String get createAppointment => switch (language) {
    AppLanguage.portuguese => 'Criar agendamento',
    AppLanguage.english => 'Create appointment',
  };

  String get pageTitle => switch (language) {
    AppLanguage.portuguese => 'Agenda',
    AppLanguage.english => 'Schedule',
  };

  String get pageSubtitle => switch (language) {
    AppLanguage.portuguese => 'Seus próximos atendimentos',
    AppLanguage.english => 'Your upcoming appointments',
  };

  String get upcomingTab => switch (language) {
    AppLanguage.portuguese => 'Próximos',
    AppLanguage.english => 'Upcoming',
  };

  String get reportTab => switch (language) {
    AppLanguage.portuguese => 'Relatório',
    AppLanguage.english => 'Report',
  };

  String get emptyTitle => switch (language) {
    AppLanguage.portuguese => 'Nenhum agendamento',
    AppLanguage.english => 'No appointments',
  };

  String get emptyMessage => switch (language) {
    AppLanguage.portuguese => 'Nada marcado para os próximos 7 dias.',
    AppLanguage.english => 'Nothing scheduled for the next 7 days.',
  };

  String get today => switch (language) {
    AppLanguage.portuguese => 'HOJE',
    AppLanguage.english => 'TODAY',
  };

  String get tomorrow => switch (language) {
    AppLanguage.portuguese => 'AMANHÃ',
    AppLanguage.english => 'TOMORROW',
  };

  String weekdayLabel(int weekday) => switch (weekday) {
    1 => switch (language) {
      AppLanguage.portuguese => 'Segunda-feira',
      AppLanguage.english => 'Monday',
    },
    2 => switch (language) {
      AppLanguage.portuguese => 'Terça-feira',
      AppLanguage.english => 'Tuesday',
    },
    3 => switch (language) {
      AppLanguage.portuguese => 'Quarta-feira',
      AppLanguage.english => 'Wednesday',
    },
    4 => switch (language) {
      AppLanguage.portuguese => 'Quinta-feira',
      AppLanguage.english => 'Thursday',
    },
    5 => switch (language) {
      AppLanguage.portuguese => 'Sexta-feira',
      AppLanguage.english => 'Friday',
    },
    6 => switch (language) {
      AppLanguage.portuguese => 'Sábado',
      AppLanguage.english => 'Saturday',
    },
    _ => switch (language) {
      AppLanguage.portuguese => 'Domingo',
      AppLanguage.english => 'Sunday',
    },
  };

  String get editAppointment => switch (language) {
    AppLanguage.portuguese => 'Editar agendamento',
    AppLanguage.english => 'Edit appointment',
  };

  String get editAppointmentSubtitle => switch (language) {
    AppLanguage.portuguese => 'Atualize os dados do atendimento',
    AppLanguage.english => 'Update the appointment details',
  };

  String get createAppointmentSubtitle => switch (language) {
    AppLanguage.portuguese => 'Novo atendimento na agenda',
    AppLanguage.english => 'New appointment on the schedule',
  };

  String get dateHint => switch (language) {
    AppLanguage.portuguese => 'Data',
    AppLanguage.english => 'Date',
  };

  String get timeHint => switch (language) {
    AppLanguage.portuguese => 'Horário',
    AppLanguage.english => 'Time',
  };

  String get patientNameHint => switch (language) {
    AppLanguage.portuguese => 'Nome do paciente',
    AppLanguage.english => 'Patient name',
  };

  String get selectRegisteredPatient => switch (language) {
    AppLanguage.portuguese => 'Selecionar paciente cadastrado',
    AppLanguage.english => 'Select a registered patient',
  };

  String get delete => switch (language) {
    AppLanguage.portuguese => 'Excluir',
    AppLanguage.english => 'Delete',
  };

  String get save => switch (language) {
    AppLanguage.portuguese => 'Salvar',
    AppLanguage.english => 'Save',
  };

  String get deleteAppointmentTitle => switch (language) {
    AppLanguage.portuguese => 'Excluir agendamento',
    AppLanguage.english => 'Delete appointment',
  };

  String get deleteAppointmentDescription => switch (language) {
    AppLanguage.portuguese =>
      'Tem certeza que deseja excluir este agendamento? Essa ação não pode ser desfeita.',
    AppLanguage.english =>
      'Are you sure you want to delete this appointment? This action cannot be undone.',
  };

  String get appointmentCreatedSuccess => switch (language) {
    AppLanguage.portuguese => 'Agendamento criado com sucesso.',
    AppLanguage.english => 'Appointment created successfully.',
  };

  String get appointmentUpdatedSuccess => switch (language) {
    AppLanguage.portuguese => 'Agendamento atualizado com sucesso.',
    AppLanguage.english => 'Appointment updated successfully.',
  };

  String monthName(int month) => switch (month) {
    1 => switch (language) {
      AppLanguage.portuguese => 'Janeiro',
      AppLanguage.english => 'January',
    },
    2 => switch (language) {
      AppLanguage.portuguese => 'Fevereiro',
      AppLanguage.english => 'February',
    },
    3 => switch (language) {
      AppLanguage.portuguese => 'Março',
      AppLanguage.english => 'March',
    },
    4 => switch (language) {
      AppLanguage.portuguese => 'Abril',
      AppLanguage.english => 'April',
    },
    5 => switch (language) {
      AppLanguage.portuguese => 'Maio',
      AppLanguage.english => 'May',
    },
    6 => switch (language) {
      AppLanguage.portuguese => 'Junho',
      AppLanguage.english => 'June',
    },
    7 => switch (language) {
      AppLanguage.portuguese => 'Julho',
      AppLanguage.english => 'July',
    },
    8 => switch (language) {
      AppLanguage.portuguese => 'Agosto',
      AppLanguage.english => 'August',
    },
    9 => switch (language) {
      AppLanguage.portuguese => 'Setembro',
      AppLanguage.english => 'September',
    },
    10 => switch (language) {
      AppLanguage.portuguese => 'Outubro',
      AppLanguage.english => 'October',
    },
    11 => switch (language) {
      AppLanguage.portuguese => 'Novembro',
      AppLanguage.english => 'November',
    },
    _ => switch (language) {
      AppLanguage.portuguese => 'Dezembro',
      AppLanguage.english => 'December',
    },
  };

  String periodRange(String start, String end) => switch (language) {
    AppLanguage.portuguese => 'Período: $start a $end',
    AppLanguage.english => 'Period: $start to $end',
  };

  String get appointmentsInMonth => switch (language) {
    AppLanguage.portuguese => 'Agendamentos no mês',
    AppLanguage.english => 'Appointments this month',
  };

  String get statusPickerTitle => switch (language) {
    AppLanguage.portuguese => 'Status do agendamento',
    AppLanguage.english => 'Appointment status',
  };
}
