import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/state/data_state.dart';

/// Cubit de um dado remoto com o ciclo de vida completo de [DataState].
///
/// - Não carrega nada no construtor: quem decide é a sessão
///   ([ensureLoaded] no bootstrap) ou a própria tela (dados sob demanda).
///   Assim um cubit criado sem usuário logado nunca guarda um "vazio" falso.
/// - [refresh] mantém os dados atuais na tela enquanto busca; em falha, os
///   dados anteriores continuam e só [DataState.failure] muda.
/// - Concorrência: cada busca recebe um número de geração e só a mais nova
///   pode emitir. Uma resposta antiga que chega depois é descartada.
/// - [reset] (logout/troca de usuário) apaga os dados e invalida as buscas
///   em andamento, que também são descartadas ao chegar.
abstract class ResourceCubit<T> extends Cubit<DataState<T>> {
  ResourceCubit({required this.debugName}) : super(DataState<T>.loading());

  /// Nome técnico para log (sem dado pessoal), ex.: "patients".
  final String debugName;

  int _generation = 0;
  Future<void>? _inFlight;

  @protected
  Future<Result<T>> fetch();

  /// Primeira carga. Não faz nada se já há dados válidos; se já existe uma
  /// busca em andamento, aguarda a mesma em vez de abrir outra.
  Future<void> ensureLoaded() {
    if (state.hasData) return Future.value();
    return _inFlight ?? refresh();
  }

  /// Busca de novo, mantendo os dados atuais visíveis.
  Future<void> refresh() {
    late final Future<void> run;
    run = _run(++_generation).whenComplete(() {
      if (identical(_inFlight, run)) _inFlight = null;
    });
    _inFlight = run;
    return run;
  }

  /// Esquece os dados (logout/troca de usuário). Buscas em andamento são
  /// descartadas quando terminarem.
  void reset() {
    _generation++;
    _inFlight = null;
    if (!isClosed) emit(DataState<T>.loading());
  }

  Future<void> _run(int generation) async {
    if (isClosed) return;
    if (!state.isLoading || state.failure != null) {
      emit(state.loadingStarted());
    }
    final stopwatch = Stopwatch()..start();
    Result<T> result;
    try {
      result = await fetch();
    } on Object catch (e, st) {
      debugPrint('[DataLoad] $debugName exceção: ${e.runtimeType}\n$st');
      result = Error(UnexpectedFailure());
    }
    if (isClosed || generation != _generation) return;
    switch (result) {
      case Success(:final data):
        if (kDebugMode) {
          debugPrint(
            '[DataLoad] $debugName ok em ${stopwatch.elapsedMilliseconds}ms',
          );
        }
        emit(DataState<T>.success(data));
      case Error(:final failure):
        debugPrint(
          '[DataLoad] $debugName falhou em ${stopwatch.elapsedMilliseconds}ms '
          '(${failure.runtimeType}, dados anteriores '
          '${state.hasData ? 'mantidos' : 'inexistentes'})',
        );
        emit(state.failed(failure));
    }
  }
}
