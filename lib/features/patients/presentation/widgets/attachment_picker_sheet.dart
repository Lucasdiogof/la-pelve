import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';

class PickedAttachmentFile {
  const PickedAttachmentFile({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileName;
  final String contentType;
}

enum _PickSource { camera, gallery, file }

String _mimeFromName(String name) {
  final ext = name.split('.').last.toLowerCase();
  return switch (ext) {
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'heic' => 'image/heic',
    'webp' => 'image/webp',
    'pdf' => 'application/pdf',
    _ => 'application/octet-stream',
  };
}

Future<PickedAttachmentFile?> pickAttachment(BuildContext context) async {
  final source = await showModalBottomSheet<_PickSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AttachmentSourceSheet(),
  );
  if (source == null || !context.mounted) return null;

  switch (source) {
    case _PickSource.camera:
    case _PickSource.gallery:
      final photo = await ImagePicker().pickImage(
        source: source == _PickSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 85,
      );
      if (photo == null) return null;
      return PickedAttachmentFile(
        bytes: await photo.readAsBytes(),
        fileName: photo.name,
        contentType: _mimeFromName(photo.name),
      );
    case _PickSource.file:
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      final picked = result?.files.firstOrNull;
      if (picked?.bytes == null) return null;
      return PickedAttachmentFile(
        bytes: picked!.bytes!,
        fileName: picked.name,
        contentType: 'application/pdf',
      );
  }
}

class _AttachmentSourceSheet extends StatelessWidget {
  const _AttachmentSourceSheet();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.border,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Adicionar anexo',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                onTap: () => Navigator.of(context).pop(_PickSource.camera),
                leading: Icon(
                  Icons.photo_camera_outlined,
                  color: context.colors.primary,
                ),
                title: const Text('Tirar foto'),
              ),
              ListTile(
                onTap: () => Navigator.of(context).pop(_PickSource.gallery),
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: context.colors.primary,
                ),
                title: const Text('Escolher da galeria'),
              ),
              ListTile(
                onTap: () => Navigator.of(context).pop(_PickSource.file),
                leading: Icon(
                  Icons.picture_as_pdf_outlined,
                  color: context.colors.primary,
                ),
                title: const Text('Escolher arquivo (PDF)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
