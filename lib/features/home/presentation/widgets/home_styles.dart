import 'package:flutter/material.dart';

const double kHomeCardRadius = 20;

List<BoxShadow> get kHomeCardShadow => [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.05),
    blurRadius: 20,
    offset: const Offset(0, 8),
  ),
];
