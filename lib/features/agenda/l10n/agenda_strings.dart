import 'package:la_pelve/core/l10n/app_language.dart';

class AgendaStrings {
  const AgendaStrings(this.language);

  final AppLanguage language;

  String get createAppointment => switch (language) {
    AppLanguage.portuguese => 'Criar agendamento',
    AppLanguage.english => 'Create appointment',
    AppLanguage.spanish => 'Crear cita',
  };

  String get pageTitle => switch (language) {
    AppLanguage.portuguese => 'Agenda',
    AppLanguage.english => 'Schedule',
    AppLanguage.spanish => 'Agenda',
  };

  String get pageSubtitle => switch (language) {
    AppLanguage.portuguese => 'Seus próximos atendimentos',
    AppLanguage.english => 'Your upcoming appointments',
    AppLanguage.spanish => 'Tus próximas citas',
  };

  String get upcomingTab => switch (language) {
    AppLanguage.portuguese => 'Próximos',
    AppLanguage.english => 'Upcoming',
    AppLanguage.spanish => 'Próximas',
  };

  String get reportTab => switch (language) {
    AppLanguage.portuguese => 'Relatório',
    AppLanguage.english => 'Report',
    AppLanguage.spanish => 'Informe',
  };

  String get emptyTitle => switch (language) {
    AppLanguage.portuguese => 'Nenhum agendamento',
    AppLanguage.english => 'No appointments',
    AppLanguage.spanish => 'Ninguna cita',
  };

  String get emptyMessage => switch (language) {
    AppLanguage.portuguese => 'Nada marcado para os próximos 7 dias.',
    AppLanguage.english => 'Nothing scheduled for the next 7 days.',
    AppLanguage.spanish => 'Nada programado para los próximos 7 días.',
  };

  String get today => switch (language) {
    AppLanguage.portuguese => 'HOJE',
    AppLanguage.english => 'TODAY',
    AppLanguage.spanish => 'HOY',
  };

  String get tomorrow => switch (language) {
    AppLanguage.portuguese => 'AMANHÃ',
    AppLanguage.english => 'TOMORROW',
    AppLanguage.spanish => 'MAÑANA',
  };

  String weekdayLabel(int weekday) => switch (weekday) {
    1 => switch (language) {
      AppLanguage.portuguese => 'Segunda-feira',
      AppLanguage.english => 'Monday',
      AppLanguage.spanish => 'Lunes',
    },
    2 => switch (language) {
      AppLanguage.portuguese => 'Terça-feira',
      AppLanguage.english => 'Tuesday',
      AppLanguage.spanish => 'Martes',
    },
    3 => switch (language) {
      AppLanguage.portuguese => 'Quarta-feira',
      AppLanguage.english => 'Wednesday',
      AppLanguage.spanish => 'Miércoles',
    },
    4 => switch (language) {
      AppLanguage.portuguese => 'Quinta-feira',
      AppLanguage.english => 'Thursday',
      AppLanguage.spanish => 'Jueves',
    },
    5 => switch (language) {
      AppLanguage.portuguese => 'Sexta-feira',
      AppLanguage.english => 'Friday',
      AppLanguage.spanish => 'Viernes',
    },
    6 => switch (language) {
      AppLanguage.portuguese => 'Sábado',
      AppLanguage.english => 'Saturday',
      AppLanguage.spanish => 'Sábado',
    },
    _ => switch (language) {
      AppLanguage.portuguese => 'Domingo',
      AppLanguage.english => 'Sunday',
      AppLanguage.spanish => 'Domingo',
    },
  };

  String get editAppointment => switch (language) {
    AppLanguage.portuguese => 'Editar agendamento',
    AppLanguage.english => 'Edit appointment',
    AppLanguage.spanish => 'Editar cita',
  };

  String get editAppointmentSubtitle => switch (language) {
    AppLanguage.portuguese => 'Atualize os dados do atendimento',
    AppLanguage.english => 'Update the appointment details',
    AppLanguage.spanish => 'Actualiza los datos de la cita',
  };

  String get createAppointmentSubtitle => switch (language) {
    AppLanguage.portuguese => 'Novo atendimento na agenda',
    AppLanguage.english => 'New appointment on the schedule',
    AppLanguage.spanish => 'Nueva cita en la agenda',
  };

  String get dateHint => switch (language) {
    AppLanguage.portuguese => 'Data',
    AppLanguage.english => 'Date',
    AppLanguage.spanish => 'Fecha',
  };

  String get timeHint => switch (language) {
    AppLanguage.portuguese => 'Horário',
    AppLanguage.english => 'Time',
    AppLanguage.spanish => 'Hora',
  };

  String get patientNameHint => switch (language) {
    AppLanguage.portuguese => 'Nome do paciente',
    AppLanguage.english => 'Patient name',
    AppLanguage.spanish => 'Nombre del paciente',
  };

  String get selectRegisteredPatient => switch (language) {
    AppLanguage.portuguese => 'Selecionar paciente cadastrado',
    AppLanguage.english => 'Select a registered patient',
    AppLanguage.spanish => 'Seleccionar paciente registrado',
  };

  String get delete => switch (language) {
    AppLanguage.portuguese => 'Excluir',
    AppLanguage.english => 'Delete',
    AppLanguage.spanish => 'Eliminar',
  };

  String get save => switch (language) {
    AppLanguage.portuguese => 'Salvar',
    AppLanguage.english => 'Save',
    AppLanguage.spanish => 'Guardar',
  };

  String get deleteAppointmentTitle => switch (language) {
    AppLanguage.portuguese => 'Excluir agendamento',
    AppLanguage.english => 'Delete appointment',
    AppLanguage.spanish => 'Eliminar cita',
  };

  String get deleteAppointmentDescription => switch (language) {
    AppLanguage.portuguese =>
      'Tem certeza que deseja excluir este agendamento? Essa ação não pode ser desfeita.',
    AppLanguage.english =>
      'Are you sure you want to delete this appointment? This action cannot be undone.',
    AppLanguage.spanish =>
      '¿Seguro que deseas eliminar esta cita? Esta acción no se puede deshacer.',
  };

  String get appointmentCreatedSuccess => switch (language) {
    AppLanguage.portuguese => 'Agendamento criado com sucesso.',
    AppLanguage.english => 'Appointment created successfully.',
    AppLanguage.spanish => 'Cita creada con éxito.',
  };

  String get appointmentUpdatedSuccess => switch (language) {
    AppLanguage.portuguese => 'Agendamento atualizado com sucesso.',
    AppLanguage.english => 'Appointment updated successfully.',
    AppLanguage.spanish => 'Cita actualizada con éxito.',
  };

  String monthName(int month) => switch (month) {
    1 => switch (language) {
      AppLanguage.portuguese => 'Janeiro',
      AppLanguage.english => 'January',
      AppLanguage.spanish => 'Enero',
    },
    2 => switch (language) {
      AppLanguage.portuguese => 'Fevereiro',
      AppLanguage.english => 'February',
      AppLanguage.spanish => 'Febrero',
    },
    3 => switch (language) {
      AppLanguage.portuguese => 'Março',
      AppLanguage.english => 'March',
      AppLanguage.spanish => 'Marzo',
    },
    4 => switch (language) {
      AppLanguage.portuguese => 'Abril',
      AppLanguage.english => 'April',
      AppLanguage.spanish => 'Abril',
    },
    5 => switch (language) {
      AppLanguage.portuguese => 'Maio',
      AppLanguage.english => 'May',
      AppLanguage.spanish => 'Mayo',
    },
    6 => switch (language) {
      AppLanguage.portuguese => 'Junho',
      AppLanguage.english => 'June',
      AppLanguage.spanish => 'Junio',
    },
    7 => switch (language) {
      AppLanguage.portuguese => 'Julho',
      AppLanguage.english => 'July',
      AppLanguage.spanish => 'Julio',
    },
    8 => switch (language) {
      AppLanguage.portuguese => 'Agosto',
      AppLanguage.english => 'August',
      AppLanguage.spanish => 'Agosto',
    },
    9 => switch (language) {
      AppLanguage.portuguese => 'Setembro',
      AppLanguage.english => 'September',
      AppLanguage.spanish => 'Septiembre',
    },
    10 => switch (language) {
      AppLanguage.portuguese => 'Outubro',
      AppLanguage.english => 'October',
      AppLanguage.spanish => 'Octubre',
    },
    11 => switch (language) {
      AppLanguage.portuguese => 'Novembro',
      AppLanguage.english => 'November',
      AppLanguage.spanish => 'Noviembre',
    },
    _ => switch (language) {
      AppLanguage.portuguese => 'Dezembro',
      AppLanguage.english => 'December',
      AppLanguage.spanish => 'Diciembre',
    },
  };

  String periodRange(String start, String end) => switch (language) {
    AppLanguage.portuguese => 'Período: $start a $end',
    AppLanguage.english => 'Period: $start to $end',
    AppLanguage.spanish => 'Período: $start a $end',
  };

  String get appointmentsInMonth => switch (language) {
    AppLanguage.portuguese => 'Agendamentos no mês',
    AppLanguage.english => 'Appointments this month',
    AppLanguage.spanish => 'Citas en el mes',
  };

  String get statusPickerTitle => switch (language) {
    AppLanguage.portuguese => 'Status do agendamento',
    AppLanguage.english => 'Appointment status',
    AppLanguage.spanish => 'Estado de la cita',
  };
}
