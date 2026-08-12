import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.icon,
    required this.hintText,
    super.key,
    this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.errorText,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.onChanged,
    this.inputFormatters,
    this.iconColor,
  });

  final IconData icon;
  final String hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? errorText;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: obscureText ? 1 : maxLines,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          style: TextStyle(color: context.colors.textPrimary),
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.fromLTRB(58, 18, 20, 18),
          ),
        ),
        Positioned(
          left: 10,
          top: 11,
          child: IgnorePointer(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: iconColor ?? context.colors.primary),
              ),
              child: Icon(
                icon,
                size: 16,
                color: iconColor ?? context.colors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
