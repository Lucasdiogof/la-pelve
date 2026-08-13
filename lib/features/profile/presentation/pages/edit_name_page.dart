import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fisioterapia_pelvica/core/di/injection_container.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/core/utils/app_loading.dart';
import 'package:fisioterapia_pelvica/features/profile/domain/repositories/profile_repository.dart';
import 'package:fisioterapia_pelvica/shared/cubit/ticker_cubit.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_info_bottom_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_text_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/modern_app_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/primary_button.dart';

class EditNamePage extends StatefulWidget {
  const EditNamePage({required this.initialNome, super.key});

  final String initialNome;

  @override
  State<EditNamePage> createState() => _EditNamePageState();
}

class _EditNamePageState extends State<EditNamePage> {
  final _repository = sl<ProfileRepository>();
  final _tickerCubit = TickerCubit();
  late final _controller = TextEditingController(text: widget.initialNome)
    ..addListener(_tickerCubit.tick);

  bool get _canSave {
    final nome = _controller.text.trim();
    return nome.isNotEmpty && nome != widget.initialNome.trim();
  }

  @override
  void dispose() {
    _controller.removeListener(_tickerCubit.tick);
    _controller.dispose();
    _tickerCubit.close();
    super.dispose();
  }

  Future<void> _save() async {
    final nome = _controller.text.trim();
    if (nome.isEmpty) return;
    showAppLoading();
    final result = await _repository.updateName(nome);
    hideAppLoading();
    if (!mounted) return;
    switch (result) {
      case Success():
        Navigator.of(context).pop(nome);
      case Error(:final failure):
        await AppInfoBottomSheet.showError(
          context,
          description: failure.message,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _tickerCubit,
      child: BlocBuilder<TickerCubit, int>(
        builder: (context, _) => Scaffold(
          backgroundColor: context.colors.background,
          body: Column(
            children: [
              const ModernAppBar(
                title: 'Editar nome',
                subtitle: 'Atualize seu nome de exibição',
                showBackButton: true,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _controller,
                        icon: Icons.person_outline,
                        hintText: 'Nome completo',
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: 'Salvar',
                        onPressed: _canSave ? _save : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
