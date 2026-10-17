/// Como uma tabela do Supabase é espelhada e sincronizada.
class EntityConfig {
  const EntityConfig({
    required this.kind,
    required this.table,
    this.orderBy = 'created_at',
    this.strict = false,
    this.softDeleteColumn,
    this.parentKind,
    this.parentColumn,
    this.ignoredKeys = const {},
  });

  /// Nome do tipo no espelho local (igual ao da tabela).
  final String kind;
  final String table;
  final String orderBy;

  /// Dado clínico de texto livre: QUALQUER alteração remota concorrente
  /// (não só nas colunas editadas) vira conflito explícito. Nunca mescla.
  final bool strict;

  /// Coluna de exclusão lógica (a linha continua no servidor).
  final String? softDeleteColumn;

  /// Entidade pai (FK) e a coluna que a referencia, para ordenar a fila.
  final String? parentKind;
  final String? parentColumn;

  /// Colunas controladas pelo servidor/triggers, ignoradas na detecção de
  /// conflito (mudam sem que a profissional tenha editado nada).
  final Set<String> ignoredKeys;

  /// Linha em que [key] participa da comparação de conflito.
  bool compares(String key) => !ignoredKeys.contains(key);
}

const patientsConfig = EntityConfig(
  kind: 'patients',
  table: 'patients',
  softDeleteColumn: 'deleted_at',
  ignoredKeys: {'created_at', 'fisioterapeuta_id'},
);

const appointmentsConfig = EntityConfig(
  kind: 'appointments',
  table: 'appointments',
  parentKind: 'patients',
  parentColumn: 'patient_id',
  // Preenchidas por triggers do banco (WhatsApp scheduler).
  ignoredKeys: {
    'created_at',
    'fisioterapeuta_id',
    'schedule_revision',
    'schedule_revision_at',
  },
);

const evolutionsConfig = EntityConfig(
  kind: 'evolution_entries',
  table: 'evolution_entries',
  orderBy: 'date',
  strict: true,
  parentKind: 'patients',
  parentColumn: 'patient_id',
  // updated_at é carimbado pelo cliente (0011): não prova alteração remota.
  ignoredKeys: {'created_at', 'physiotherapist_id', 'updated_at'},
);

const financialConfig = EntityConfig(
  kind: 'financial_entries',
  table: 'financial_entries',
  orderBy: 'date',
  parentKind: 'patients',
  parentColumn: 'patient_id',
  ignoredKeys: {'created_at', 'fisioterapeuta_id'},
);

/// Ordem importa: pais antes dos filhos.
const offlineEntities = [
  patientsConfig,
  appointmentsConfig,
  evolutionsConfig,
  financialConfig,
];
