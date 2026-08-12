import 'package:flutter/material.dart';
import 'package:fisioterapia_pelvica/core/di/injection_container.dart';
import 'package:fisioterapia_pelvica/core/services/biometric_service.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/core/utils/biometric_preference.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_info_bottom_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/modern_app_bar.dart';

class BiometricSettingsPage extends StatefulWidget {
  const BiometricSettingsPage({super.key});

  @override
  State<BiometricSettingsPage> createState() => _BiometricSettingsPageState();
}

class _BiometricSettingsPageState extends State<BiometricSettingsPage> {
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await BiometricPreference.isEnabled();
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _loading = false;
      });
    }
  }

  Future<void> _toggle(bool value) async {
    final biometricService = sl<BiometricService>();
    if (value) {
      final supported = await biometricService.isDeviceSupported();
      if (!supported) {
        if (mounted) {
          await AppInfoBottomSheet.showError(
            context,
            description:
                'Este dispositivo não oferece suporte à biometria ou não possui um bloqueio de tela configurado.',
          );
        }
        return;
      }
      final authenticated = await biometricService.authenticate(
        'Confirme sua identidade para ativar a biometria',
      );
      if (!authenticated) return;
    }
    await BiometricPreference.setEnabled(value);
    if (mounted) setState(() => _enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        children: [
          const ModernAppBar(
            title: 'Biometria',
            subtitle: 'Proteja o acesso ao app',
            showBackButton: true,
          ),
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: context.colors.primary,
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Material(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        child: SwitchListTile(
                          value: _enabled,
                          onChanged: _toggle,
                          activeThumbColor: context.colors.primary,
                          title: const Text('Entrar com biometria'),
                          subtitle: const Text(
                            'Exige biometria para reabrir o app depois de minimizado.',
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
