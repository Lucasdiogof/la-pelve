import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/shared/widgets/modern_app_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/pulsing_logo.dart';

class ImageViewerPage extends StatelessWidget {
  const ImageViewerPage({
    this.url,
    this.assetPath,
    required this.title,
    super.key,
  }) : assert(
         (url == null) != (assetPath == null),
         'Provide exactly one of url or assetPath',
       );

  final String? url;
  final String? assetPath;
  final String title;

  @override
  Widget build(BuildContext context) {
    final assetPath = this.assetPath;
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        children: [
          ModernAppBar(title: title, showBackButton: true),
          Expanded(
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: assetPath != null
                    ? Image.asset(
                        assetPath,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.broken_image_outlined,
                          color: context.colors.textSecondary,
                          size: 64,
                        ),
                      )
                    : Image.network(
                        url!,
                        loadingBuilder: (context, child, progress) =>
                            progress == null
                            ? child
                            : const PulsingLogo(size: 64),
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.broken_image_outlined,
                          color: context.colors.textSecondary,
                          size: 64,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
