import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_bottom_action_bar.dart';
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
  });

  final String title;
  final int stepIndex;
  final int stepCount;
  final Widget body;
  final VoidCallback? onNext;
  final VoidCallback onBack;
  final String nextLabel;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        foregroundColor: context.colors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: Text(title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Etapa ${stepIndex + 1} de $stepCount',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (stepIndex + 1) / stepCount,
                    backgroundColor: context.colors.border,
                    color: context.colors.primary,
                    minHeight: 6,
                  ),
                ),
              ],
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
            child: PrimaryButton(
              label: nextLabel,
              isLoading: isLoading,
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }
}
