import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';

class ImageViewerPage extends StatelessWidget {
  const ImageViewerPage({required this.url, required this.title, super.key});

  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(title: Text(title, overflow: TextOverflow.ellipsis)),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(
            url,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : CircularProgressIndicator(color: context.colors.primary),
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.broken_image_outlined,
              color: context.colors.textSecondary,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}
