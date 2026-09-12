import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pelve/core/di/injection_container.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/core/l10n/locale_cubit.dart';
import 'package:la_pelve/core/theme/app_colors.dart';
import 'package:la_pelve/core/utils/app_loading.dart';
import 'package:la_pelve/features/profile/domain/repositories/profile_repository.dart';
import 'package:la_pelve/features/profile/l10n/profile_strings.dart';
import 'package:la_pelve/shared/cubit/ticker_cubit.dart';
import 'package:la_pelve/shared/widgets/app_info_bottom_sheet.dart';
import 'package:la_pelve/shared/widgets/app_text_field.dart';
import 'package:la_pelve/shared/widgets/modern_app_bar.dart';
import 'package:la_pelve/shared/widgets/primary_button.dart';

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
    final t = ProfileStrings(context.watch<LocaleCubit>().state);
    return BlocProvider.value(
      value: _tickerCubit,
      child: BlocBuilder<TickerCubit, int>(
        builder: (context, _) => Scaffold(
          backgroundColor: context.colors.background,
          body: Column(
            children: [
              ModernAppBar(
                title: t.editNamePageTitle,
                subtitle: t.editNamePageSubtitle,
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
                        hintText: t.editNameHint,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: t.saveButtonLabel,
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
