import 'package:equatable/equatable.dart';
import 'package:la_pelve/core/error/failures.dart';

/// Estado de um dado remoto. Separa o que uma `List` pura não consegue:
///
/// - ainda carregando pela primeira vez ([isInitialLoading]);
/// - carregado (com dados ou realmente vazio) ([hasData]);
/// - atualizando sem perder o que já está na tela ([isRefreshing]);
/// - falha, com ou sem dados anteriores válidos ([failure]).
///
/// Regra de UI: estado vazio só quando [hasData] e a coleção está vazia;
/// nunca durante a primeira carga nem numa falha sem dados.
class DataState<T> extends Equatable {
  const DataState._({this.data, this.isLoading = false, this.failure});

  /// Ainda sem nenhum dado válido (inclusive logo depois de sair da conta).
  const DataState.loading() : this._(isLoading: true);

  const DataState.success(T value) : this._(data: value);

  /// Último dado carregado com sucesso; `null` enquanto nunca carregou.
  final T? data;

  /// Há uma busca em andamento.
  final bool isLoading;

  /// Falha da última busca. Com [data] presente, é falha de atualização: os
  /// dados anteriores continuam valendo.
  final Failure? failure;

  bool get hasData => data != null;
  bool get isInitialLoading => isLoading && !hasData;
  bool get isRefreshing => isLoading && hasData;

  /// Falhou sem nunca ter carregado: a tela mostra erro + tentar de novo.
  bool get isFailureWithoutData => !isLoading && !hasData && failure != null;

  DataState<T> loadingStarted() => DataState._(data: data, isLoading: true);

  DataState<T> failed(Failure failure) =>
      DataState._(data: data, failure: failure);

  @override
  List<Object?> get props => [data, isLoading, failure];
}
