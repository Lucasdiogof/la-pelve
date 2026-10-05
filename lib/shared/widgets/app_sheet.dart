import 'package:flutter/material.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';

/// Casca comum dos bottom sheets: superfície, topo com raio [AppRadius.lg],
/// puxador, SafeArea e padding. O conteúdo ([children]) continua específico
/// de cada sheet.
///
/// Abra com `showModalBottomSheet(backgroundColor: Colors.transparent, ...)`
/// (ou deixe o tema cuidar do fundo); o scrim vem do `bottomSheetTheme`.
class AppSheet extends StatelessWidget {
  const AppSheet({required this.children, super.key, this.constraints});

  final List<Widget> children;

  /// Limite opcional (ex.: altura máxima de uma lista longa).
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    // Material (e não Container) para o ripple de ListTile/InkWell aparecer
    // sobre a superfície do sheet.
    final sheet = Material(
      color: context.colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgTop),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.s8,
            AppSpacing.gutter,
            AppSpacing.s20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _DragHandle(),
              const SizedBox(height: AppSpacing.s16),
              ...children,
            ],
          ),
        ),
      ),
    );
    final constrained = constraints == null
        ? sheet
        : ConstrainedBox(constraints: constraints!, child: sheet);
    return SizedBox(width: double.infinity, child: constrained);
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: context.colors.border,
          // Puxador é um elemento realmente arredondado: raio = altura/2.
          borderRadius: const BorderRadius.all(Radius.circular(2)),
        ),
      ),
    );
  }
}
