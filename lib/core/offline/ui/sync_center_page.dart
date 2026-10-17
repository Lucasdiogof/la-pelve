import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pelve/core/di/injection_container.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/offline/local/local_store.dart';
import 'package:la_pelve/core/offline/offline_session.dart';
import 'package:la_pelve/core/offline/sync/conflict_resolver.dart';
import 'package:la_pelve/core/offline/sync/sync_engine.dart';
import 'package:la_pelve/core/offline/ui/sync_strings.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/shared/widgets/app_sheet.dart';
import 'package:la_pelve/shared/widgets/modern_app_bar.dart';
import 'package:la_pelve/shared/widgets/primary_button.dart';

/// Central de sincronização: situação, conflitos que pedem decisão e
/// alterações com erro (tentar de novo ou descartar). Nunca mostra o corpo
/// clínico de uma alteração fora dos conflitos, onde é indispensável para
/// decidir.
class SyncCenterPage extends StatefulWidget {
  const SyncCenterPage({super.key});

  @override
  State<SyncCenterPage> createState() => _SyncCenterPageState();
}

class _SyncCenterPageState extends State<SyncCenterPage> {
  StreamSubscription<SyncStatus>? _sub;
  bool _busy = false;

  SyncEngine? get _engine => sl<OfflineSession>().active?.engine;

  @override
  void initState() {
    super.initState();
    _sub = _engine?.statusStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _syncNow() async {
    setState(() => _busy = true);
    await _engine?.sync(force: true);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = SyncStrings(context.watch<LocaleCubit>().state);
    final engine = _engine;
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final conflicts = engine?.conflicts() ?? const <ConflictItem>[];
    final failed = engine?.failedOps() ?? const <SyncOp>[];
    final last = engine?.status.lastSyncAt;
    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ModernAppBar(
            title: t.centerTitle,
            showBackButton: true,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.s8,
                AppSpacing.gutter,
                AppSpacing.s32,
              ),
              children: [
                Text(
                  t.centerExplain,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                Text(
                  '${t.lastSync}: '
                  '${last == null ? t.never : _format(last.toLocal())}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                PrimaryButton(
                  label: t.syncNow,
                  isLoading: _busy,
                  onPressed: engine == null ? null : _syncNow,
                ),
                const SizedBox(height: AppSpacing.s24),
                if (conflicts.isEmpty && failed.isEmpty)
                  Text(
                    t.nothingToReview,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                if (conflicts.isNotEmpty) ...[
                  Text(t.conflictsTitle, style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.s8),
                  for (final item in conflicts)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.call_split, color: colors.danger),
                      title: Text(t.kindLabel(item.kind)),
                      subtitle: Text(
                        item.remote == null
                            ? t.deletedOnServer
                            : item.keys.map(t.fieldLabel).join(', '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openConflict(context, item),
                    ),
                  const SizedBox(height: AppSpacing.s16),
                ],
                if (failed.isNotEmpty) ...[
                  Text(t.failuresTitle, style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.s8),
                  for (final op in failed)
                    _FailedTile(op: op, engine: engine!, t: t),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _format(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<void> _openConflict(BuildContext context, ConflictItem item) async {
    final engine = _engine;
    if (engine == null) return;
    final t = SyncStrings(context.read<LocaleCubit>().state);
    final choice = await showModalBottomSheet<ConflictResolution>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConflictSheet(item: item, t: t),
    );
    if (choice == null) return;
    await engine.resolveConflict(item.kind, item.id, choice);
    if (mounted) setState(() {});
  }
}

class _FailedTile extends StatelessWidget {
  const _FailedTile({required this.op, required this.engine, required this.t});

  final SyncOp op;
  final SyncEngine engine;
  final SyncStrings t;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.error_outline, color: colors.warning),
      title: Text(t.kindLabel(op.kind)),
      subtitle: Text(t.errorServer),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'retry') {
            engine.retryOp(op.opId);
          } else {
            engine.discardOp(op.opId);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'retry', child: Text(t.retry)),
          PopupMenuItem(value: 'discard', child: Text(t.discard)),
        ],
      ),
    );
  }
}

class _ConflictSheet extends StatelessWidget {
  const _ConflictSheet({required this.item, required this.t});

  final ConflictItem item;
  final SyncStrings t;

  String _show(Object? value) {
    final text = value == null ? '' : '$value';
    if (text.isEmpty) return t.empty;
    return text.length > 600 ? '${text.substring(0, 600)}…' : text;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final remote = item.remote;
    final keys = item.keys;
    return AppSheet(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      children: [
        Text(t.kindLabel(item.kind), style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.s8),
        Text(
          t.conflictIntro,
          style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.s16),
        Flexible(
          child: SingleChildScrollView(
            child: remote == null
                ? Text(t.deletedOnServer, style: textTheme.bodyMedium)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final key in keys) ...[
                        Text(
                          t.fieldLabel(key),
                          style: textTheme.labelLarge,
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        _Version(
                          label: t.thisDevice,
                          value: _show(item.local[key]),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        _Version(label: t.onServer, value: _show(remote[key])),
                        const SizedBox(height: AppSpacing.s16),
                      ],
                    ],
                  ),
          ),
        ),
        PrimaryButton(
          label: t.keepMine,
          onPressed: () => Navigator.of(context).pop(ConflictResolution.keepLocal),
        ),
        const SizedBox(height: AppSpacing.s8),
        if (remote != null) ...[
          OutlinedButton(
            onPressed: () =>
                Navigator.of(context).pop(ConflictResolution.keepRemote),
            child: Text(t.keepServer),
          ),
          if (item.kind == 'evolution_entries') ...[
            const SizedBox(height: AppSpacing.s8),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).pop(ConflictResolution.keepBoth),
              child: Text(t.keepBoth, textAlign: TextAlign.center),
            ),
          ],
        ] else
          OutlinedButton(
            onPressed: () =>
                Navigator.of(context).pop(ConflictResolution.keepRemote),
            child: Text(t.keepServer),
          ),
      ],
    );
  }
}

class _Version extends StatelessWidget {
  const _Version({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: AppRadius.smAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
