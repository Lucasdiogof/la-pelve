import 'package:flutter/material.dart';
import 'package:la_pelve/core/theme/app_colors.dart';

class ProfileAvatarSection extends StatelessWidget {
  const ProfileAvatarSection({
    required this.photoUrl,
    required this.initial,
    required this.isSaving,
    required this.onTap,
    this.onViewPhoto,
    super.key,
  });

  final String? photoUrl;
  final String initial;
  final bool isSaving;
  final VoidCallback onTap;
  final VoidCallback? onViewPhoto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: onViewPhoto,
            child: CircleAvatar(
              radius: 32,
              backgroundColor: context.colors.primary.withValues(alpha: 0.15),
              backgroundImage: photoUrl != null
                  ? NetworkImage(photoUrl!)
                  : null,
              child: photoUrl == null
                  ? Text(
                      initial,
                      style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    )
                  : null,
            ),
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
                  padding: const EdgeInsets.all(6),
                  child: isSaving
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.colors.onPrimary,
                          ),
                        )
                      : Icon(
                          Icons.camera_alt_outlined,
                          size: 14,
                          color: context.colors.onPrimary,
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
