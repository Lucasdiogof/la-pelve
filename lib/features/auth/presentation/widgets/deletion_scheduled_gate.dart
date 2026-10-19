import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pelve/core/di/injection_container.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/features/auth/domain/entities/data_deletion_schedule.dart';
import 'package:la_pelve/features/auth/domain/repositories/auth_repository.dart';
import 'package:la_pelve/features/profile/l10n/profile_strings.dart';
import 'package:la_pelve/shared/widgets/app_info_bottom_sheet.dart';

/// Envolve a área logada. Se a conta tem exclusão definitiva agendada, mostra
/// só a tela de restaurar (ou sair) em vez do app. Se a checagem falhar (por
/// exemplo sem internet) NÃO bloqueia: o app abre normalmente, porque o
/// servidor é quem apaga e a pessoa pode estar offline.
class DeletionScheduledGate extends StatefulWidget {
  const DeletionScheduledGate({required this.child, super.key});

  final Widget child;

  @override
  State<DeletionScheduledGate> createState() => _DeletionScheduledGateState();
}

class _DeletionScheduledGateState extends State<DeletionScheduledGate> {
  DataDeletionSchedule? _schedule;
  bool _checked = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final result = await sl<AuthRepository>().getDataDeletionSchedule();
    if (!mounted) return;
    setState(() {
      _checked = true;
      _schedule = switch (result) {
        Success(:final data) => data,
        Error() => null,
      };
    });
  }

  Future<void> _restore() async {
    final t = ProfileStrings(context.read<LocaleCubit>().state);
    setState(() => _busy = true);
    final result = await sl<AuthRepository>().cancelDataDeletion();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success():
        setState(() => _schedule = null);
      case Error():
        await AppInfoBottomSheet.showError(
          context,
          description: t.restoreFailedMessage,
        );
    }
  }

  Future<void> _signOut() async {
    await sl<AuthRepository>().signOut();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final schedule = _schedule;
    if (!_checked || schedule == null) return widget.child;
    final t = ProfileStrings(context.read<LocaleCubit>().state);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.scheduledPageTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.s16),
              Text(
                t.scheduledPageBody(schedule.purgeAfter),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.s32),
              ElevatedButton(
                onPressed: _busy ? null : _restore,
                child: Text(t.restoreAccountLabel),
              ),
              const SizedBox(height: AppSpacing.s8),
              TextButton(
                onPressed: _busy ? null : _signOut,
                child: Text(t.signOutButtonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
