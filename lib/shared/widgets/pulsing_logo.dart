import 'package:flutter/material.dart';

class PulsingLogo extends StatefulWidget {
  const PulsingLogo({super.key, this.size = 72, this.animate = true});

  final double size;
  final bool animate;

  @override
  State<PulsingLogo> createState() => _PulsingLogoState();
}

class _PulsingLogoState extends State<PulsingLogo>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _scale;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      )..repeat(reverse: true);
      _controller = controller;
      _scale = Tween<double>(
        begin: 0.85,
        end: 1.15,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'lib/assets/app_icon.png',
      width: widget.size,
      height: widget.size,
      filterQuality: FilterQuality.high,
    );
    final scale = _scale;
    if (scale == null) return image;
    return ScaleTransition(scale: scale, child: image);
  }
}
