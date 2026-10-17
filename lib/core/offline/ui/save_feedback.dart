import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/di/injection_container.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/offline/offline_session.dart';
import 'package:la_pelve/core/offline/ui/sync_strings.dart';
import 'package:la_pelve/shared/widgets/app_info_bottom_sheet.dart';

/// O registro já está no servidor? Sem armazenamento offline (Web, testes) a
/// gravação foi direta no servidor, então sim. Com ele, tenta enviar agora e
/// só responde true se não restou nenhuma pendência.
Future<bool> savedOnServer(String kind, String id) async {
  final engine = maybeSl<OfflineSession>()?.active?.engine;
  if (engine == null) return true;
  return engine.flush(kind, id);
}

/// Confirmação de gravação que nunca afirma mais do que aconteceu: se o
/// registro só está neste aparelho, diz isso; senão, mostra [successMessage].
Future<void> showSavedFeedback(
  BuildContext context, {
  required String kind,
  required String id,
  required String successMessage,
}) async {
  final onServer = await savedOnServer(kind, id);
  if (!context.mounted) return;
  if (onServer) {
    await AppInfoBottomSheet.showSuccess(context, description: successMessage);
  } else {
    await AppInfoBottomSheet.showInfo(
      context,
      description: SyncStrings(context.read<LocaleCubit>().state).savedOnDevice,
    );
  }
}
