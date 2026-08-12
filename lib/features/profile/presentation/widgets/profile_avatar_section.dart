import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';

class ProfileAvatarSection extends StatelessWidget {
  const ProfileAvatarSection({
    required this.photoUrl,
    required this.initial,
    required this.isSaving,
    required this.onTap,
    super.key,
  });

  final String? photoUrl;
  final String initial;
  final bool isSaving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: context.colors.primary.withValues(alpha: 0.15),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? Text(
                    initial,
                    style: TextStyle(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 32,
                    ),
                  )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: context.colors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: isSaving ? null : onTap,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt_outlined,
                          size: 16,
                          color: Colors.white,
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
