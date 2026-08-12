import 'package:flutter/material.dart';

class AppBottomActionBar extends StatelessWidget {
  const AppBottomActionBar({required this.child, super.key});

  final Widget child;

  static const double maxContentWidth = 480;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
