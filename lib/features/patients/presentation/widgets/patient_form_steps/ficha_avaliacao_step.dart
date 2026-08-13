import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/attachment_picker_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/primary_button.dart';

class FichaAvaliacaoStep extends StatelessWidget {
  const FichaAvaliacaoStep({
    required this.files,
    required this.onAdd,
    required this.onRemove,
    super.key,
  });

  final List<PickedAttachmentFile> files;
  final ValueChanged<PickedAttachmentFile> onAdd;
  final ValueChanged<int> onRemove;

  Future<void> _pick(BuildContext context) async {
    final picked = await pickAttachment(context);
    if (picked != null) onAdd(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anexe a ficha de avaliação física do paciente, como fotos ou PDFs. '
          'Você pode adicionar mais de um arquivo. Esse passo é opcional e pode '
          'ser feito depois, pela aba Anexos.',
          style: TextStyle(color: context.colors.textSecondary),
        ),
        const SizedBox(height: 20),
        if (files.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Nenhum arquivo selecionado.',
                style: TextStyle(color: context.colors.textSecondary),
              ),
            ),
          )
        else
          for (var i = 0; i < files.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _FileRow(file: files[i], onRemove: () => onRemove(i)),
          ],
        const SizedBox(height: 16),
        PrimaryButton(
          label: files.isEmpty
              ? 'Selecionar arquivo'
              : 'Adicionar outro arquivo',
          onPressed: () => _pick(context),
        ),
      ],
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, required this.onRemove});

  final PickedAttachmentFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
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
              file.contentType == 'application/pdf'
                  ? Icons.picture_as_pdf_outlined
                  : Icons.image_outlined,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Avaliação Física',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: context.colors.error),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
