import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';

class ProfileRow extends StatelessWidget {
  const ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: context.colors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    Text(
                      value.isEmpty ? 'Não informado' : value,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
