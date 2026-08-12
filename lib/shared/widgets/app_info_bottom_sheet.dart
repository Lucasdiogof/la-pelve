import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/shared/widgets/primary_button.dart';

enum AppInfoBottomSheetVariant { error, success, info }

class AppInfoBottomSheet extends StatelessWidget {
  const AppInfoBottomSheet({
    required this.title,
    required this.description,
    required this.variant,
    super.key,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String description;
  final AppInfoBottomSheetVariant variant;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  static Future<void> showError(
    BuildContext context, {
    required String description,
    String title = 'Não foi possível continuar',
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
    String title = 'Tudo certo!',
  }) => _show(
    context,
    title: title,
    description: description,
    variant: AppInfoBottomSheetVariant.success,
  );

  static Future<void> showInfo(
    BuildContext context, {
    required String description,
    String title = 'Informação',
  }) => _show(
    context,
    title: title,
    description: description,
    variant: AppInfoBottomSheetVariant.info,
  );

  static Future<void> _show(
    BuildContext context, {
    required String title,
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
      barrierColor: Colors.black.withValues(alpha: 0.35),
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
    AppInfoBottomSheetVariant.error => context.colors.error,
    AppInfoBottomSheetVariant.success => context.colors.success,
    AppInfoBottomSheetVariant.info => context.colors.primary,
  };

  IconData get _icon => switch (variant) {
    AppInfoBottomSheetVariant.error => Icons.error_outline_rounded,
    AppInfoBottomSheetVariant.success => Icons.check_circle_outline_rounded,
    AppInfoBottomSheetVariant.info => Icons.info_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accentColor = _accentColor(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.16),
                  ),
                ),
                child: Icon(_icon, color: accentColor, size: 30),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Entendi',
                onPressed: () => Navigator.of(context).pop(),
              ),
              if (secondaryActionLabel != null)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onSecondaryAction?.call();
                  },
                  child: Text(secondaryActionLabel!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
