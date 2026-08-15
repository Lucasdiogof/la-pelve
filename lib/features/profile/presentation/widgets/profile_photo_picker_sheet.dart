import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/attachment_picker_sheet.dart';
import 'package:fisioterapia_pelvica/features/profile/l10n/profile_strings.dart';

enum ProfilePhotoAction { camera, gallery, remove }

String _mimeFromName(String name) {
  final ext = name.split('.').last.toLowerCase();
  return switch (ext) {
    'png' => 'image/png',
    'heic' => 'image/heic',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}

Future<ProfilePhotoAction?> showProfilePhotoActionSheet(
  BuildContext context, {
  required bool canRemove,
}) => showModalBottomSheet<ProfilePhotoAction>(
  context: context,
  backgroundColor: Colors.transparent,
  builder: (_) => _ProfilePhotoSourceSheet(canRemove: canRemove),
);

Future<PickedAttachmentFile?> pickProfilePhotoFrom(
  ProfilePhotoAction action,
) async {
  final photo = await ImagePicker().pickImage(
    source: action == ProfilePhotoAction.camera
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
}

class _ProfilePhotoSourceSheet extends StatelessWidget {
  const _ProfilePhotoSourceSheet({required this.canRemove});

  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    final t = ProfileStrings(context.watch<LocaleCubit>().state);
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
                t.photoPickerTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                onTap: () =>
                    Navigator.of(context).pop(ProfilePhotoAction.camera),
                leading: Icon(
                  Icons.photo_camera_outlined,
                  color: context.colors.primary,
                ),
                title: Text(t.takePhotoLabel),
              ),
              ListTile(
                onTap: () =>
                    Navigator.of(context).pop(ProfilePhotoAction.gallery),
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: context.colors.primary,
                ),
                title: Text(t.chooseFromGalleryLabel),
              ),
              if (canRemove)
                ListTile(
                  onTap: () =>
                      Navigator.of(context).pop(ProfilePhotoAction.remove),
                  leading: Icon(
                    Icons.delete_outline,
                    color: context.colors.error,
                  ),
                  title: Text(
                    t.removePhotoTitle,
                    style: TextStyle(color: context.colors.error),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
