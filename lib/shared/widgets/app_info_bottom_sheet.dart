import 'package:flutter/material.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/shared/l10n/app_strings.dart';
import 'package:la_pelve/shared/widgets/app_sheet.dart';
import 'package:la_pelve/shared/widgets/primary_button.dart';

enum AppInfoBottomSheetVariant { error, success, info }

class AppInfoBottomSheet extends StatelessWidget {
  const AppInfoBottomSheet({
    required this.description,
    required this.variant,
    super.key,
    this.title,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String? title;
  final String description;
  final AppInfoBottomSheetVariant variant;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  static Future<void> showError(
    BuildContext context, {
    required String description,
    String? title,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
  }) => _show(
    context,
    title: title,
    description: description,
    variant: AppInfoBottomSheetVariant.error,
    secondaryActionLabel: secondaryActionLabel,
    onSecondaryAction: onSecondaryAction,
  );

  static Future<void> showSuccess(
    BuildContext context, {
    required String description,
    String? title,
  }) => _show(
    context,
    title: title,
    description: description,
    variant: AppInfoBottomSheetVariant.success,
  );

  static Future<void> showInfo(
    BuildContext context, {
    required String description,
    String? title,
  }) => _show(
    context,
    title: title,
    description: description,
    variant: AppInfoBottomSheetVariant.info,
  );

  static Future<void> _show(
    BuildContext context, {
    required String? title,
    required String description,
    required AppInfoBottomSheetVariant variant,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppInfoBottomSheet(
        title: title,
        description: description,
        variant: variant,
        secondaryActionLabel: secondaryActionLabel,
        onSecondaryAction: onSecondaryAction,
      ),
    );
  }

  Color _accentColor(BuildContext context) => switch (variant) {
    AppInfoBottomSheetVariant.error => context.colors.danger,
    AppInfoBottomSheetVariant.success => context.colors.success,
    AppInfoBottomSheetVariant.info => context.colors.primary,
  };

  IconData get _icon => switch (variant) {
    AppInfoBottomSheetVariant.error => Icons.error_outline_rounded,
    AppInfoBottomSheetVariant.success => Icons.check_circle_outline_rounded,
    AppInfoBottomSheetVariant.info => Icons.info_outline_rounded,
  };

  String _defaultTitle(BuildContext context) => switch (variant) {
    AppInfoBottomSheetVariant.error => context.strings.shared.errorTitle,
    AppInfoBottomSheetVariant.success => context.strings.shared.successTitle,
    AppInfoBottomSheetVariant.info => context.strings.shared.infoTitle,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppSheet(
      children: [
        Row(
          children: [
            Icon(_icon, color: _accentColor(context), size: 24),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Text(
                title ?? _defaultTitle(context),
                style: textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          description,
          style: textTheme.bodyLarge?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
        PrimaryButton(
          label: context.strings.shared.understood,
          onPressed: () => Navigator.of(context).pop(),
        ),
        if (secondaryActionLabel != null) ...[
          const SizedBox(height: AppSpacing.s8),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onSecondaryAction?.call();
            },
            child: Text(secondaryActionLabel!),
          ),
        ],
      ],
    );
  }
}
