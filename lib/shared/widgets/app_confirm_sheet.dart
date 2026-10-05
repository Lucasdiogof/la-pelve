import 'package:flutter/material.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/shared/l10n/app_strings.dart';
import 'package:la_pelve/shared/widgets/app_sheet.dart';

class AppConfirmSheet extends StatelessWidget {
  const AppConfirmSheet({
    required this.title,
    required this.description,
    required this.confirmLabel,
    super.key,
    this.cancelLabel,
    this.isDestructive = false,
  });

  final String title;
  final String description;
  final String confirmLabel;
  final String? cancelLabel;
  final bool isDestructive;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String description,
    required String confirmLabel,
    String? cancelLabel,
    bool isDestructive = false,
  }) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppConfirmSheet(
        title: title,
        description: description,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppSheet(
      children: [
        Text(title, style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.s8),
        Text(
          description,
          style: textTheme.bodyLarge?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          // Confirmação destrutiva é o único lugar com botão cheio em danger.
          style: isDestructive
              ? ElevatedButton.styleFrom(
                  backgroundColor: context.colors.danger,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                )
              : null,
          child: Text(confirmLabel),
        ),
        const SizedBox(height: AppSpacing.s8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel ?? context.strings.shared.cancel),
        ),
      ],
    );
  }
}
