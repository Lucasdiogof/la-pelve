import 'package:flutter/material.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/shared/l10n/app_strings.dart';
import 'package:la_pelve/shared/widgets/app_bottom_action_bar.dart';
import 'package:la_pelve/shared/widgets/modern_app_bar.dart';
import 'package:la_pelve/shared/widgets/primary_button.dart';

class AppWizardScaffold extends StatelessWidget {
  const AppWizardScaffold({
    required this.title,
    required this.stepIndex,
    required this.stepCount,
    required this.body,
    required this.onNext,
    required this.onBack,
    super.key,
    this.nextLabel,
    this.isLoading = false,
    this.showSaveButton = false,
    this.onSave,
  });

  final String title;
  final int stepIndex;
  final int stepCount;
  final Widget body;
  final VoidCallback? onNext;
  final VoidCallback onBack;
  final String? nextLabel;
  final bool isLoading;
  final bool showSaveButton;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final t = context.strings.shared;
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        children: [
          ModernAppBar(
            title: title,
            subtitle: t.stepOf(stepIndex + 1, stepCount),
            showBackButton: true,
            onBack: onBack,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              0,
              AppSpacing.gutter,
              AppSpacing.s16,
            ),
            child: LinearProgressIndicator(
              value: (stepIndex + 1) / stepCount,
              minHeight: 2,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              key: ValueKey(stepIndex),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                0,
                AppSpacing.gutter,
                AppSpacing.s24,
              ),
              child: body,
            ),
          ),
          AppBottomActionBar(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showSaveButton) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: isLoading ? null : onSave,
                      child: Text(t.saveEditButton),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                PrimaryButton(
                  label: nextLabel ?? t.nextButton,
                  isLoading: isLoading,
                  onPressed: onNext,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
