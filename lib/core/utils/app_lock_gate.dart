import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fisioterapia_pelvica/core/di/injection_container.dart';
import 'package:fisioterapia_pelvica/core/services/biometric_service.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/core/utils/app_lock_cubit.dart';
import 'package:fisioterapia_pelvica/core/utils/biometric_preference.dart';
import 'package:fisioterapia_pelvica/shared/widgets/primary_button.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({required this.child, super.key});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final _lockCubit = AppLockCubit();
  bool _wasBackgrounded = false;
  bool _unlocking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_maybeLock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lockCubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _wasBackgrounded = true;
    } else if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      _maybeLock();
    }
  }

  Future<void> _maybeLock() async {
    final hasSession = Supabase.instance.client.auth.currentSession != null;
    if (!hasSession) return;
    final enabled = await BiometricPreference.isEnabled();
    if (enabled && mounted) {
      _lockCubit.lock();
      unawaited(_unlock());
    }
  }

  Future<void> _unlock() async {
    if (_unlocking) return;
    _unlocking = true;
    final ok = await sl<BiometricService>().authenticate(
      'Desbloqueie para continuar',
    );
    _unlocking = false;
    if (ok && mounted) _lockCubit.unlock();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _lockCubit,
      child: BlocBuilder<AppLockCubit, bool>(
        builder: (context, locked) => Stack(
          children: [
            widget.child,
            if (locked)
              ColoredBox(
                color: context.colors.background,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 48,
                        color: context.colors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'App bloqueado',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(label: 'Desbloquear', onPressed: _unlock),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
