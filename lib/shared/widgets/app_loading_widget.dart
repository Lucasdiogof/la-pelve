import 'package:flutter/material.dart';
import 'package:la_pelve/shared/widgets/pulsing_logo.dart';

class AppLoadingWidget extends StatelessWidget {
  const AppLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: PulsingLogo());
}
