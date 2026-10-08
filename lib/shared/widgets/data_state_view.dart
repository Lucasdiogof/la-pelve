import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/state/data_state.dart';
import 'package:la_pelve/core/state/resource_cubit.dart';
import 'package:la_pelve/shared/l10n/app_strings.dart';
import 'package:la_pelve/shared/l10n/shared_strings.dart';
import 'package:la_pelve/shared/widgets/app_error_state.dart';
import 'package:la_pelve/shared/widgets/app_loading_widget.dart';

/// Decide entre loading / erro / conteúdo a partir de um [DataState]:
///
/// - primeira carga: loading (nunca o estado vazio);
/// - falha sem dados: erro + tentar novamente (nunca o estado vazio);
/// - com dados (mesmo atualizando ou com falha de atualização): [builder].
///   Só o [builder] decide se mostra o estado vazio, e só com dados válidos.
class DataStateView<T> extends StatelessWidget {
  const DataStateView({
    required this.state,
    required this.onRetry,
    required this.builder,
    super.key,
  });

  final DataState<T> state;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, T data) builder;

  @override
  Widget build(BuildContext context) {
    final data = state.data;
    if (data != null) return builder(context, data);
    if (state.isFailureWithoutData) {
      final t = context.strings.shared;
      return AppErrorState(
        title: t.loadErrorTitle,
        message: state.failure!.message,
        retryLabel: t.retry,
        onRetry: onRetry,
      );
    }
    return const AppLoadingWidget();
  }
}

/// Pull-to-refresh de um recurso que já tem dados: atualiza mantendo a lista
/// e, se a atualização falhar, avisa sem apagar nada.
Future<void> refreshKeepingData(
  BuildContext context,
  ResourceCubit<Object> cubit,
) async {
  await cubit.refresh();
  if (!context.mounted) return;
  if (cubit.state.failure != null && cubit.state.hasData) {
    showRefreshFailed(context);
  }
}

/// Chamado fora do build (depois de um await): lê o idioma com `read`.
void showRefreshFailed(BuildContext context) {
  final t = SharedStrings(context.read<LocaleCubit>().state);
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(t.refreshFailed)));
}
