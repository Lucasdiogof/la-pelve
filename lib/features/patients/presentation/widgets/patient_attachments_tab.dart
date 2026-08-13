import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fisioterapia_pelvica/core/di/injection_container.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/l10n/locale_cubit.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/core/utils/app_loading.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/attachment.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/repositories/attachment_repository.dart';
import 'package:fisioterapia_pelvica/features/patients/l10n/patients_strings.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patient_attachments_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patient_attachments_state.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/pages/image_viewer_page.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/attachment_picker_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_confirm_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_empty_state.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_info_bottom_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/primary_button.dart';

class PatientAttachmentsTab extends StatelessWidget {
  const PatientAttachmentsTab({required this.patientId, super.key});

  final String patientId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PatientAttachmentsCubit(sl<AttachmentRepository>(), patientId),
      child: const _PatientAttachmentsView(),
    );
  }
}

class _PatientAttachmentsView extends StatelessWidget {
  const _PatientAttachmentsView();

  Future<void> _addAttachment(BuildContext context) async {
    final t = PatientsStrings(context.read<LocaleCubit>().state);
    final cubit = context.read<PatientAttachmentsCubit>();
    final picked = await pickAttachment(context);
    if (picked == null || !context.mounted) return;
    showAppLoading();
    final result = await cubit.upload(
      category: picked.contentType == 'application/pdf'
          ? AttachmentCategory.document
          : AttachmentCategory.image,
      bytes: picked.bytes,
      fileName: picked.fileName,
      contentType: picked.contentType,
    );
    hideAppLoading();
    if (!context.mounted) return;
    switch (result) {
      case Success():
        await AppInfoBottomSheet.showSuccess(
          context,
          description: t.attachmentAddedSuccess,
        );
      case Error(:final failure):
        await AppInfoBottomSheet.showError(
          context,
          description: failure.message,
        );
    }
  }

  Future<void> _open(BuildContext context, Attachment attachment) async {
    final t = PatientsStrings(context.read<LocaleCubit>().state);
    showAppLoading();
    final result = await sl<AttachmentRepository>().getViewUrl(attachment);
    if (result case Success(
      :final data,
    ) when attachment.isImage && context.mounted) {
      try {
        await precacheImage(NetworkImage(data), context);
      } catch (_) {}
    }
    hideAppLoading();
    if (!context.mounted) return;
    switch (result) {
      case Success(:final data):
        if (attachment.isImage) {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ImageViewerPage(
                url: data,
                title: attachment.category.label(t.language),
              ),
            ),
          );
        } else {
          final opened = await launchUrl(
            Uri.parse(data),
            mode: LaunchMode.externalApplication,
          );
          if (!opened && context.mounted) {
            await AppInfoBottomSheet.showError(
              context,
              description: t.cannotOpenFileError,
            );
          }
        }
      case Error(:final failure):
        await AppInfoBottomSheet.showError(
          context,
          description: failure.message,
        );
    }
  }

  Future<void> _delete(BuildContext context, Attachment attachment) async {
    final t = PatientsStrings(context.read<LocaleCubit>().state);
    final cubit = context.read<PatientAttachmentsCubit>();
    final confirmed = await AppConfirmSheet.show(
      context,
      title: t.deleteAttachmentTitle,
      description: t.deleteAttachmentDescription(
        attachment.category.label(t.language).toLowerCase(),
      ),
      confirmLabel: t.deleteLabel,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    showAppLoading();
    final result = await cubit.delete(attachment);
    hideAppLoading();
    if (!context.mounted) return;
    if (result case Error(:final failure)) {
      await AppInfoBottomSheet.showError(context, description: failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = PatientsStrings(context.watch<LocaleCubit>().state);
    return BlocBuilder<PatientAttachmentsCubit, PatientAttachmentsState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            PrimaryButton(
              label: t.addAttachmentButton,
              icon: const Icon(Icons.add, color: Colors.white),
              isLoading: state.uploading,
              onPressed: () => _addAttachment(context),
            ),
            const SizedBox(height: 20),
            Builder(
              builder: (context) {
                final result = state.result;
                final attachments = switch (result) {
                  Success(:final data) => data,
                  _ => const <Attachment>[],
                };
                if (result is Error<List<Attachment>>) {
                  return Center(
                    child: Text(
                      result.failure.message,
                      style: TextStyle(color: context.colors.textSecondary),
                    ),
                  );
                }
                if (attachments.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.attach_file,
                    title: t.attachmentsEmptyTitle,
                    message: t.attachmentsEmptyMessage,
                  );
                }
                return Column(
                  children: [
                    for (final attachment in attachments)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _AttachmentRow(
                          attachment: attachment,
                          onTap: () => _open(context, attachment),
                          onDelete: () => _delete(context, attachment),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({
    required this.attachment,
    required this.onTap,
    required this.onDelete,
  });

  final Attachment attachment;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LocaleCubit>().state;
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  attachment.isPdf
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined,
                  color: context.colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.category.label(language),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      AppDateField.format(attachment.createdAt),
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: context.colors.error),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
