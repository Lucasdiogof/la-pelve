import 'package:equatable/equatable.dart';

/// Exclusão definitiva de todos os dados já pedida: até [purgeAfter] a
/// profissional ainda pode restaurar a conta.
class DataDeletionSchedule extends Equatable {
  const DataDeletionSchedule({
    required this.requestedAt,
    required this.purgeAfter,
  });

  factory DataDeletionSchedule.fromJson(Map<String, dynamic> json) =>
      DataDeletionSchedule(
        requestedAt: DateTime.parse(json['requested_at'] as String),
        purgeAfter: DateTime.parse(json['purge_after'] as String),
      );

  final DateTime requestedAt;
  final DateTime purgeAfter;

  @override
  List<Object?> get props => [requestedAt, purgeAfter];
}
