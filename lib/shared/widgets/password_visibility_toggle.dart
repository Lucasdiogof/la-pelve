import 'package:flutter/material.dart';

class PasswordVisibilityToggle extends StatelessWidget {
  const PasswordVisibilityToggle({
    required this.obscured,
    required this.onPressed,
    this.color,
    super.key,
  });

  final bool obscured;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: color,
      ),
      onPressed: onPressed,
    );
  }
}
