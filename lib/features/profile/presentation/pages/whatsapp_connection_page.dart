import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pelve/core/di/injection_container.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/features/profile/domain/repositories/whatsapp_connection_repository.dart';
import 'package:la_pelve/features/profile/l10n/profile_strings.dart';
import 'package:la_pelve/features/profile/presentation/cubit/whatsapp_connection_cubit.dart';
import 'package:la_pelve/features/profile/presentation/cubit/whatsapp_connection_state.dart';
import 'package:la_pelve/shared/widgets/app_bottom_action_bar.dart';
import 'package:la_pelve/shared/widgets/app_empty_state.dart';
import 'package:la_pelve/shared/widgets/app_date_field.dart';
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

class _WhatsappConnectionView extends StatelessWidget {
  const _WhatsappConnectionView();

  @override
  Widget build(BuildContext context) {
    final t = ProfileStrings(context.watch<LocaleCubit>().state);
    return BlocBuilder<WhatsappConnectionCubit, WhatsappConnectionState>(
      builder: (context, state) {
        final bottomAction = _bottomActionFor(context, t, state);
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
                child: _WhatsappConnectionBody(state: state, strings: t),
              ),
            ],
          ),
          bottomNavigationBar: bottomAction == null
              ? null
              : AppBottomActionBar(child: bottomAction),
        );
      },
    );
  }

  Widget? _bottomActionFor(
    BuildContext context,
    ProfileStrings t,
    WhatsappConnectionState state,
  ) {
    switch (state) {
      case WhatsappConnectionLoading():
        return null;
      case WhatsappConnectionNotConnected():
      case WhatsappConnectionDisconnected():
        // Nesta etapa o botão não dispara nenhum fluxo da Meta: fica
        // desabilitado, só para o lugar já existir quando a integração
        // (Embedded Signup) for liberada pela Meta.
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              label: t.connectWhatsappButtonLabel,
              onPressed: null,
            ),
            const SizedBox(height: 8),
            Text(
              t.whatsappIntegrationInProgressNote,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        );
      case WhatsappConnectionPending():
      case WhatsappConnectionError():
        return PrimaryButton(
          label: t.refreshStatusButtonLabel,
          onPressed: () => context.read<WhatsappConnectionCubit>().load(),
        );
      case WhatsappConnectionConnected():
        return null;
      case WhatsappConnectionLoadFailure():
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              label: t.retryButtonLabel,
              onPressed: () => context.read<WhatsappConnectionCubit>().load(),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(t.backButtonLabel),
            ),
          ],
        );
    }
  }
}

class _WhatsappConnectionBody extends StatelessWidget {
  const _WhatsappConnectionBody({required this.state, required this.strings});

  final WhatsappConnectionState state;
  final ProfileStrings strings;

  @override
  Widget build(BuildContext context) {
    final t = strings;
    return switch (state) {
      WhatsappConnectionLoading() => Center(
        child: CircularProgressIndicator(color: context.colors.primary),
      ),
      WhatsappConnectionNotConnected() => Padding(
        padding: const EdgeInsets.all(24),
        child: AppEmptyState(
          icon: Icons.chat_outlined,
          title: t.whatsappNotConnectedTitle,
          message: t.whatsappNotConnectedMessage,
        ),
      ),
      WhatsappConnectionPending() => _InfoCard(
        icon: Icons.hourglass_top_outlined,
        iconColor: context.colors.primary,
        title: t.whatsappPendingTitle,
        message: t.whatsappPendingMessage,
        children: const [],
      ),
      WhatsappConnectionConnected(:final connection) => _InfoCard(
        icon: Icons.check_circle_outline,
        iconColor: context.colors.success,
        title: t.whatsappConnectedStatusLabel,
        message: null,
        children: [
          _ConnectionField(
            label: t.connectedPhoneNumberLabel,
            value: connection.displayPhoneNumber ?? t.notInformedLabel,
          ),
          if (connection.connectedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                t.whatsappConnectedSinceLabel(
                  AppDateField.format(connection.connectedAt!),
                ),
                style: TextStyle(color: context.colors.textSecondary),
              ),
            ),
        ],
      ),
      WhatsappConnectionDisconnected(:final connection) => Padding(
        padding: const EdgeInsets.all(24),
        child: AppEmptyState(
          icon: Icons.chat_outlined,
          title: t.whatsappDisconnectedTitle,
          message: connection.disconnectedAt == null
              ? t.whatsappNotConnectedMessage
              : t.whatsappDisconnectedSinceLabel(
                  AppDateField.format(connection.disconnectedAt!),
                ),
        ),
      ),
      WhatsappConnectionError() => _InfoCard(
        icon: Icons.error_outline_rounded,
        iconColor: context.colors.error,
        title: t.whatsappConnectionErrorMessage,
        message: null,
        children: const [],
      ),
      WhatsappConnectionLoadFailure() => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: context.colors.error,
              ),
              const SizedBox(height: 16),
              Text(
                t.whatsappLoadErrorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    };
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.children,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? message;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              ],
              if (children.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...children,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionField extends StatelessWidget {
  const _ConnectionField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: context.colors.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
