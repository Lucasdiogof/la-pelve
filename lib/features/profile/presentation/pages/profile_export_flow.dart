import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:la_pelve/core/di/injection_container.dart';
import 'package:la_pelve/core/utils/app_loading.dart';
import 'package:la_pelve/features/profile/data/export/data_export_repository.dart';
import 'package:la_pelve/features/profile/data/export/data_export_service.dart';
import 'package:la_pelve/features/profile/l10n/profile_strings.dart';
import 'package:la_pelve/shared/widgets/app_confirm_sheet.dart';
import 'package:la_pelve/shared/widgets/app_info_bottom_sheet.dart';

/// Fluxo de "Exportar meus dados": confirma, gera e verifica o pacote, e só
/// então pede ao sistema para salvar. Nenhum dado clínico vai para log.
Future<void> runDataExportFlow(BuildContext context, ProfileStrings t) async {
  final confirmed = await AppConfirmSheet.show(
    context,
    title: t.exportRowLabel,
    description: t.exportConfirmDescription,
    confirmLabel: t.exportConfirmLabel,
  );
  if (!confirmed || !context.mounted) return;

  showAppLoading();
  PreparedExport? prepared;
  ExportException? failure;
  try {
    prepared = await sl<DataExportRepository>().prepare();
  } on ExportException catch (e) {
    failure = e;
  } catch (e) {
    debugPrint('[runDataExportFlow] ${e.runtimeType}');
    failure = const ExportException(ExportFailureCode.sourceFailure);
  }
  hideAppLoading();
  if (!context.mounted) return;

  if (prepared == null) {
    debugPrint('[runDataExportFlow] failed: ${failure?.code}');
    await AppInfoBottomSheet.showError(
      context,
      description: failure?.code == ExportFailureCode.pendingLocalChanges
          ? t.exportPendingSyncMessage
          : t.exportIncompleteMessage,
    );
    return;
  }

  try {
    await FilePicker.platform.saveFile(
      dialogTitle: t.exportRowLabel,
      fileName: prepared.package.fileName,
      bytes: prepared.package.bytes,
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
  } catch (e) {
    debugPrint('[runDataExportFlow] save failed: ${e.runtimeType}');
    if (!context.mounted) return;
    await AppInfoBottomSheet.showError(
      context,
      description: t.exportIncompleteMessage,
    );
    return;
  }
  if (!context.mounted) return;
  await AppInfoBottomSheet.showSuccess(
    context,
    title: t.exportRowLabel,
    description: t.exportDoneDescription,
  );
}
