import 'package:flutter/material.dart';

/// Botão primário. Herda forma, cor e tipografia do `elevatedButtonTheme`.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      // Carregando, o botão fica desabilitado mas mantém a cor primária,
      // para o spinner (onPrimary) ter contraste.
      style: isLoading
          ? ElevatedButton.styleFrom(
              disabledBackgroundColor: scheme.primary,
              disabledForegroundColor: scheme.onPrimary,
            )
          : null,
      child: isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: scheme.onPrimary,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(child: Text(label, textAlign: TextAlign.center)),
                if (icon != null) ...[const SizedBox(width: 8), icon!],
              ],
            ),
    );
  }
}
