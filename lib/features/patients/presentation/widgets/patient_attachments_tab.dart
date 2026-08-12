import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fisioterapia_pelvica/core/di/injection_container.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/core/utils/app_loading.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/attachment.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/repositories/attachment_repository.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/pages/image_viewer_page.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/attachment_picker_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_confirm_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_empty_state.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_info_bottom_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/primary_button.dart';

class PatientAttachmentsTab extends StatefulWidget {
  const PatientAttachmentsTab({required this.patientId, super.key});

  final String patientId;

  @override
  State<PatientAttachmentsTab> createState() => _PatientAttachmentsTabState();
}

class _PatientAttachmentsTabState extends State<PatientAttachmentsTab> {
  final _repository = sl<AttachmentRepository>();
  late Future<Result<List<Attachment>>> _future = _repository.getForPatient(
    widget.patientId,
  );
  bool _uploading = false;

  Future<void> _reload() async {
    setState(() {
      _future = _repository.getForPatient(widget.patientId);
    });
  }

  Future<void> _addAttachment() async {
    final picked = await pickAttachment(context);
    if (picked == null || !mounted) return;
    setState(() => _uploading = true);
    showAppLoading();
    final result = await _repository.upload(
      patientId: widget.patientId,
      category: picked.contentType == 'application/pdf'
          ? AttachmentCategory.documento
          : AttachmentCategory.imagem,
      bytes: picked.bytes,
      fileName: picked.fileName,
      contentType: picked.contentType,
    );
    hideAppLoading();
    if (!mounted) return;
    setState(() => _uploading = false);
    switch (result) {
      case Success():
        await _reload();
      case Error(:final failure):
        await AppInfoBottomSheet.showError(
          context,
          description: failure.message,
        );
    }
  }

  Future<void> _open(Attachment attachment) async {
    showAppLoading();
    final result = await _repository.getViewUrl(attachment);
    if (result case Success(:final data) when attachment.isImage && mounted) {
      try {
        await precacheImage(NetworkImage(data), context);
      } catch (_) {}
    }
    hideAppLoading();
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        if (attachment.isImage) {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  ImageViewerPage(url: data, title: attachment.category.label),
            ),
          );
        } else {
          final opened = await launchUrl(
            Uri.parse(data),
            mode: LaunchMode.externalApplication,
          );
          if (!opened && mounted) {
            await AppInfoBottomSheet.showError(
              context,
              description: 'Não foi possível abrir o arquivo.',
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

  Future<void> _delete(Attachment attachment) async {
    final confirmed = await AppConfirmSheet.show(
      context,
      title: 'Excluir anexo',
      description:
          'Excluir este ${attachment.category.label.toLowerCase()}? Essa ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    showAppLoading();
    final result = await _repository.delete(attachment);
    hideAppLoading();
    if (!mounted) return;
    switch (result) {
      case Success():
        await _reload();
      case Error(:final failure):
        await AppInfoBottomSheet.showError(
          context,
          description: failure.message,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PrimaryButton(
          label: 'Adicionar anexo',
          icon: const Icon(Icons.add, color: Colors.white),
          isLoading: _uploading,
          onPressed: _addAttachment,
        ),
        const SizedBox(height: 20),
        FutureBuilder<Result<List<Attachment>>>(
          future: _future,
          builder: (context, snapshot) {
            final result = snapshot.data;
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
              return const AppEmptyState(
                icon: Icons.attach_file,
                title: 'Nenhum anexo ainda',
                message: 'Anexe fotos ou arquivos do paciente.',
              );
            }
            return Column(
              children: [
                for (final attachment in attachments)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AttachmentRow(
                      attachment: attachment,
                      onTap: () => _open(attachment),
                      onDelete: () => _delete(attachment),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
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
                      attachment.category.label,
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
