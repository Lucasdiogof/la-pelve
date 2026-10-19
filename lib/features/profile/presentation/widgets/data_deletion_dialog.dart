import 'package:flutter/material.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/features/profile/l10n/profile_strings.dart';
import 'package:la_pelve/shared/l10n/app_strings.dart';
import 'package:la_pelve/shared/widgets/app_sheet.dart';

/// Resultado do diálogo de exclusão definitiva.
enum DataDeletionChoice { cancel, exportFirst, confirm }

/// Explica a exclusão de todos os dados, oferece exportar antes e só habilita
/// o botão destrutivo quando a pessoa digita a palavra de confirmação.
class DataDeletionDialog extends StatefulWidget {
  const DataDeletionDialog({required this.strings, super.key});

  final ProfileStrings strings;

  static Future<DataDeletionChoice> show(
    BuildContext context,
    ProfileStrings strings,
  ) async {
    final result = await showModalBottomSheet<DataDeletionChoice>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DataDeletionDialog(strings: strings),
    );
    return result ?? DataDeletionChoice.cancel;
  }

  @override
  State<DataDeletionDialog> createState() => _DataDeletionDialogState();
}

class _DataDeletionDialogState extends State<DataDeletionDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _matches =>
      _controller.text.trim().toUpperCase() ==
      widget.strings.dataDeletionKeyword;

  @override
  Widget build(BuildContext context) {
    final t = widget.strings;
    final textTheme = Theme.of(context).textTheme;
    return AppSheet(
      children: [
        Text(t.dataDeletionTitle, style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.s8),
        Flexible(
          child: SingleChildScrollView(
            child: Text(
              t.dataDeletionDescription,
              style: textTheme.bodyLarge?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        OutlinedButton(
          onPressed: () =>
              Navigator.of(context).pop(DataDeletionChoice.exportFirst),
          child: Text(t.dataDeletionExportFirst),
        ),
        const SizedBox(height: AppSpacing.s16),
        TextField(
          controller: _controller,
          autocorrect: false,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(labelText: t.dataDeletionTypeToConfirm),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.s16),
        ElevatedButton(
          onPressed: _matches
              ? () => Navigator.of(context).pop(DataDeletionChoice.confirm)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colors.danger,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: Text(t.dataDeletionConfirmLabel),
        ),
        const SizedBox(height: AppSpacing.s8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(DataDeletionChoice.cancel),
          child: Text(context.strings.shared.cancel),
        ),
      ],
    );
  }
}
