import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/di/injection_container.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/theme/app_tokens.dart';
import 'package:la_pelve/features/profile/domain/entities/whatsapp_connection.dart';
import 'package:la_pelve/features/profile/domain/repositories/whatsapp_connection_repository.dart';
import 'package:la_pelve/features/profile/l10n/profile_strings.dart';
import 'package:la_pelve/features/profile/presentation/cubit/whatsapp_connection_cubit.dart';
import 'package:la_pelve/features/profile/presentation/cubit/whatsapp_connection_state.dart';
import 'package:la_pelve/shared/widgets/app_date_field.dart';
import 'package:la_pelve/shared/widgets/app_error_state.dart';
import 'package:la_pelve/shared/widgets/app_list_row.dart';
import 'package:la_pelve/shared/widgets/app_section.dart';
import 'package:la_pelve/shared/widgets/app_status_badge.dart';
import 'package:la_pelve/shared/widgets/modern_app_bar.dart';
import 'package:la_pelve/shared/widgets/primary_button.dart';

class WhatsappConnectionPage extends StatelessWidget {
  const WhatsappConnectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          WhatsappConnectionCubit(sl<WhatsappConnectionRepository>()),
      child: const _WhatsappConnectionView(),
    );
  }
}

class _WhatsappConnectionView extends StatefulWidget {
  const _WhatsappConnectionView();

  @override
  State<_WhatsappConnectionView> createState() =>
      _WhatsappConnectionViewState();
}

class _WhatsappConnectionViewState extends State<_WhatsappConnectionView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Volta do navegador/aba da Meta: relê o estado real no servidor.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle != AppLifecycleState.resumed || !mounted) return;
    final cubit = context.read<WhatsappConnectionCubit>();
    if (cubit.state is WhatsappConnectionConnecting ||
        cubit.state is WhatsappConnectionPending) {
      cubit.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ProfileStrings(context.watch<LocaleCubit>().state);
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        children: [
          ModernAppBar(
            title: t.whatsappPageTitle,
            subtitle: t.whatsappPageSubtitle,
            showBackButton: true,
          ),
          Expanded(
            child: BlocBuilder<WhatsappConnectionCubit, WhatsappConnectionState>(
              builder: (context, state) {
                // Falha ao CONSULTAR a conexão: erro + tentar de novo, nunca
                // um "não conectado" que pode não ser verdade.
                if (state is WhatsappConnectionLoadFailure) {
                  return AppErrorState(
                    title: t.whatsappLoadErrorMessage,
                    message: state.failure.message,
                    retryLabel: t.retryButtonLabel,
                    onRetry: () =>
                        context.read<WhatsappConnectionCubit>().load(),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.s16,
                    AppSpacing.gutter,
                    AppSpacing.s32,
                  ),
                  children: [_WhatsappPanel(state: state, t: t)],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// O painel único da tela: cabeçalho com status, descrição, benefícios e,
/// no fim, a área que muda conforme o estado da conexão.
class _WhatsappPanel extends StatelessWidget {
  const _WhatsappPanel({required this.state, required this.t});

  final WhatsappConnectionState state;
  final ProfileStrings t;

  @override
  Widget build(BuildContext context) {
    final divider = Divider(height: 1, color: context.colors.border);
    const rowPadding = EdgeInsets.symmetric(horizontal: AppSpacing.s16);
    return AppSection(
      children: [
        _PanelHeader(badge: _badgeFor(state, t), t: t),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            0,
            AppSpacing.s16,
            AppSpacing.s16,
          ),
          child: Text(
            t.whatsappIntroMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
        divider,
        for (final (icon, label) in [
          (Icons.notifications_none_outlined, t.whatsappBenefitReminders),
          (Icons.task_alt_outlined, t.whatsappBenefitConfirmation),
          (Icons.event_available_outlined, t.whatsappBenefitAgendaSync),
        ])
          AppListRow(
            leading: Icon(icon, size: 20, color: context.colors.textSecondary),
            title: label,
            titleMaxLines: 3,
            padding: rowPadding,
          ),
        divider,
        _StatusArea(state: state, t: t),
      ],
    );
  }

  static AppStatusBadge? _badgeFor(
    WhatsappConnectionState state,
    ProfileStrings t,
  ) {
    return switch (state) {
      WhatsappConnectionLoading() || WhatsappConnectionLoadFailure() => null,
      WhatsappConnectionConnecting() => AppStatusBadge(
        label: t.whatsappStatusConnecting,
        tone: AppStatusTone.primary,
      ),
      WhatsappConnectionNotConnected(:final selfConnectAvailable) =>
        selfConnectAvailable
            ? null
            : AppStatusBadge(
                label: t.whatsappStatusInSetup,
                tone: AppStatusTone.neutral,
              ),
      WhatsappConnectionPending() => AppStatusBadge(
        label: t.whatsappStatusPending,
        tone: AppStatusTone.primary,
      ),
      WhatsappConnectionConnected() => AppStatusBadge(
        label: t.whatsappConnectedStatusLabel,
        tone: AppStatusTone.success,
      ),
      WhatsappConnectionDisconnected() => AppStatusBadge(
        label: t.whatsappStatusDisconnected,
        tone: AppStatusTone.muted,
      ),
      WhatsappConnectionError() => AppStatusBadge(
        label: t.whatsappStatusError,
        tone: AppStatusTone.danger,
      ),
    };
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.badge, required this.t});

  final AppStatusBadge? badge;
  final ProfileStrings t;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Row(
        children: [
          // Container discreto; o verde de sucesso só no ícone e bem suave.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.surfaceMuted,
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(
              Icons.chat_outlined,
              size: 20,
              color: colors.success.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  t.clinicWhatsappTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ?badge,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fim do painel: o que fazer agora, conforme o estado da conexão.
class _StatusArea extends StatelessWidget {
  const _StatusArea({required this.state, required this.t});

  final WhatsappConnectionState state;
  final ProfileStrings t;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final secondary = textTheme.bodyMedium?.copyWith(
      color: context.colors.textSecondary,
    );
    void refresh() => context.read<WhatsappConnectionCubit>().load();

    final Widget content = switch (state) {
      // Só enquanto a consulta realmente está em andamento.
      WhatsappConnectionLoading() => Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(child: Text(t.whatsappCheckingStatus, style: secondary)),
        ],
      ),
      WhatsappConnectionConnecting() => _MessageWithAction(
        title: t.whatsappConnectingTitle,
        message: t.whatsappConnectingMessage,
        actionLabel: t.refreshStatusButtonLabel,
        onAction: refresh,
      ),
      WhatsappConnectionNotConnected(
        :final selfConnectAvailable,
        :final startFailed,
      ) =>
        _ConnectArea(
          t: t,
          available: selfConnectAvailable,
          startFailed: startFailed,
        ),
      WhatsappConnectionDisconnected(
        :final connection,
        :final selfConnectAvailable,
        :final startFailed,
      ) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (t.whatsappReasonMessage(_reasonCode(connection))
                case final reason?) ...[
              Text(reason, style: secondary),
              const SizedBox(height: AppSpacing.s12),
            ],
            if (connection.disconnectedAt != null) ...[
              Text(
                t.whatsappDisconnectedSinceLabel(
                  AppDateField.format(connection.disconnectedAt!),
                ),
                style: secondary,
              ),
              const SizedBox(height: AppSpacing.s16),
            ],
            _ConnectArea(
              t: t,
              available: selfConnectAvailable,
              startFailed: startFailed,
            ),
          ],
        ),
      WhatsappConnectionPending(:final connection) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MessageWithAction(
            title: t.whatsappPendingTitle,
            message:
                t.whatsappReasonMessage(_reasonCode(connection)) ??
                t.whatsappPendingMessage,
            actionLabel: t.refreshStatusButtonLabel,
            onAction: refresh,
          ),
          const SizedBox(height: AppSpacing.s8),
          const _DisconnectButton(),
        ],
      ),
      WhatsappConnectionError(:final connection) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MessageWithAction(
            title: t.whatsappConnectionErrorMessage,
            message: t.whatsappReasonMessage(_reasonCode(connection)),
            actionLabel: t.refreshStatusButtonLabel,
            onAction: refresh,
          ),
          const SizedBox(height: AppSpacing.s8),
          const _DisconnectButton(),
        ],
      ),
      WhatsappConnectionConnected(:final connection, :final disconnectFailed) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.connectedPhoneNumberLabel, style: secondary),
            const SizedBox(height: 2),
            Text(
              connection.displayPhoneNumber ?? t.notInformedLabel,
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (connection.connectedAt != null) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                t.whatsappConnectedSinceLabel(
                  AppDateField.format(connection.connectedAt!),
                ),
                style: secondary,
              ),
            ],
            const SizedBox(height: AppSpacing.s12),
            Text(t.whatsappBillingNote, style: secondary),
            if (disconnectFailed) ...[
              const SizedBox(height: AppSpacing.s12),
              Text(
                t.whatsappDisconnectFailedMessage,
                style: textTheme.bodyMedium?.copyWith(
                  color: context.colors.danger,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s16),
            const _DisconnectButton(),
          ],
        ),
      // Tratado pela página (erro de tela cheia); nunca chega aqui.
      WhatsappConnectionLoadFailure() => const SizedBox.shrink(),
    };

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: content,
    );
  }
}

String? _reasonCode(WhatsappConnection connection) =>
    connection.lastError?['code'] as String?;

/// Sem conexão. Com o onboarding liberado pelo backend, mostra o botão
/// primário "Conectar WhatsApp" (fluxo oficial da Meta). Sem ele, mostra
/// "Integração em preparação" -- nunca um botão que não funciona.
class _ConnectArea extends StatelessWidget {
  const _ConnectArea({
    required this.t,
    required this.available,
    required this.startFailed,
  });

  final ProfileStrings t;
  final bool available;
  final bool startFailed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (available) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (startFailed) ...[
            Text(
              t.whatsappStartFailedMessage,
              style: textTheme.bodyMedium?.copyWith(
                color: context.colors.danger,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
          ],
          PrimaryButton(
            label: t.connectWhatsappButtonLabel,
            onPressed: () => context.read<WhatsappConnectionCubit>().connect(),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              t.whatsappPreparingTitle,
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            AppStatusBadge(label: t.comingSoonBadge, tone: AppStatusTone.muted),
          ],
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          t.whatsappPreparingMessage,
          style: textTheme.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Desconectar sempre pede confirmação.
class _DisconnectButton extends StatelessWidget {
  const _DisconnectButton();

  @override
  Widget build(BuildContext context) {
    final t = ProfileStrings(context.watch<LocaleCubit>().state);
    return OutlinedButton(
      onPressed: () async {
        final cubit = context.read<WhatsappConnectionCubit>();
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(t.disconnectWhatsappDialogTitle),
            content: Text(t.disconnectWhatsappDialogMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(t.cancelButtonLabel),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(t.disconnectWhatsappButtonLabel),
              ),
            ],
          ),
        );
        if (confirmed == true) await cubit.disconnect();
      },
      child: Text(t.disconnectWhatsappButtonLabel),
    );
  }
}

class _MessageWithAction extends StatelessWidget {
  const _MessageWithAction({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String? message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            message!,
            style: textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s12),
        OutlinedButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}
