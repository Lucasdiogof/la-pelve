import 'package:flutter/material.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';

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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.s12,
                AppSpacing.gutter,
                AppSpacing.s12,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
