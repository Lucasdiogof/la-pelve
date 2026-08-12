import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_bottom_action_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/modern_app_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/primary_button.dart';

class AppWizardScaffold extends StatelessWidget {
  const AppWizardScaffold({
    required this.title,
    required this.stepIndex,
    required this.stepCount,
    required this.body,
    required this.onNext,
    required this.onBack,
    super.key,
    this.nextLabel = 'Próximo',
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
  final String nextLabel;
  final bool isLoading;
  final bool showSaveButton;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        children: [
          ModernAppBar(
            title: title,
            subtitle: 'Etapa ${stepIndex + 1} de $stepCount',
            showBackButton: true,
            onBack: onBack,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (stepIndex + 1) / stepCount,
                backgroundColor: context.colors.border,
                color: context.colors.primary,
                minHeight: 6,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              key: ValueKey(stepIndex),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        shape: const StadiumBorder(),
                        side: BorderSide(color: context.colors.border),
                      ),
                      child: const Text('Salvar edição'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                PrimaryButton(
                  label: nextLabel,
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
