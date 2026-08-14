import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';

class AppSelectField extends StatefulWidget {
  const AppSelectField({
    required this.icon,
    required this.hintText,
    required this.displayText,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String hintText;
  final String displayText;
  final VoidCallback onTap;

  @override
  State<AppSelectField> createState() => _AppSelectFieldState();
}

class _AppSelectFieldState extends State<AppSelectField> {
  late final _controller = TextEditingController(text: widget.displayText);

  @override
  void didUpdateWidget(covariant AppSelectField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.displayText != oldWidget.displayText) {
      _controller.text = widget.displayText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeFocus(
      child: AppTextField(
        icon: widget.icon,
        hintText: widget.hintText,
        readOnly: true,
        enableInteractiveSelection: false,
        controller: _controller,
        onTap: widget.onTap,
      ),
    );
  }
}
