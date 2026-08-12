import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fisioterapia_pelvica/core/error/result.dart';
import 'package:fisioterapia_pelvica/core/theme/app_colors.dart';
import 'package:fisioterapia_pelvica/core/utils/app_loading.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/gestacao.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/encerramento_sheet.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/patient_attachments_tab.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_bottom_action_bar.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_confirm_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_date_field.dart';
import 'package:fisioterapia_pelvica/shared/widgets/app_info_bottom_sheet.dart';
import 'package:fisioterapia_pelvica/shared/widgets/primary_button.dart';

const _naoInformado = 'Não informado';

String _text(String? value) =>
    (value == null || value.trim().isEmpty) ? _naoInformado : value.trim();

String _yesNo(bool? value) => switch (value) {
  true => 'Sim',
  false => 'Não',
  null => _naoInformado,
};

String _intValue(int? value) => value?.toString() ?? _naoInformado;

String _dateValue(DateTime? value) =>
    value == null ? _naoInformado : AppDateField.format(value);

String _money(double? value) =>
    value == null ? _naoInformado : 'R\$ ${value.toStringAsFixed(2)}';

String _enumValue<T>(T? value, String Function(T) label) =>
    value == null ? _naoInformado : label(value);

class PatientDetailPage extends StatelessWidget {
  const PatientDetailPage({required this.patient, super.key});

  final Patient patient;

  Future<void> _confirmDelete(BuildContext context, Patient current) async {
    final confirmed = await AppConfirmSheet.show(
      context,
      title: 'Excluir paciente',
      description:
          'Tem certeza que deseja excluir ${current.dadosPessoais.nome.isEmpty ? 'este paciente' : current.dadosPessoais.nome}? '
          'Essa ação não pode ser desfeita e também apaga as evoluções registradas.',
      confirmLabel: 'Excluir',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    showAppLoading();
    final result = await context.read<PatientsCubit>().deletePatient(
      current.id,
    );
    hideAppLoading();
    if (!context.mounted) return;
    switch (result) {
      case Success():
        context.pop();
      case Error(:final failure):
        await AppInfoBottomSheet.showError(
          context,
          description: failure.message,
        );
    }
  }

  Future<void> _encerrarTratamento(
    BuildContext context,
    Patient current,
  ) async {
    final encerramento = await showEncerramentoSheet(context);
    if (encerramento == null || !context.mounted) return;
    await _saveEncerramento(context, current, encerramento);
  }

  Future<void> _reabrirTratamento(BuildContext context, Patient current) async {
    final confirmed = await AppConfirmSheet.show(
      context,
      title: 'Reabrir tratamento',
      description:
          'Isso remove o encerramento atual e volta o tratamento para em andamento.',
      confirmLabel: 'Reabrir',
    );
    if (!confirmed || !context.mounted) return;
    await _saveEncerramento(context, current, null);
  }

  Future<void> _saveEncerramento(
    BuildContext context,
    Patient current,
    Encerramento? encerramento,
  ) async {
    showAppLoading();
    final result = await context.read<PatientsCubit>().updatePatient(
      current.copyWith(encerramento: encerramento),
    );
    hideAppLoading();
    if (!context.mounted) return;
    if (result case Error(:final failure)) {
      await AppInfoBottomSheet.showError(context, description: failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patients = context.watch<PatientsCubit>().state;
    final current = patients.firstWhere(
      (p) => p.id == patient.id,
      orElse: () => patient,
    );
    final dados = current.dadosPessoais;
    final isFeminino = dados.sexo == Sexo.feminino;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(
          title: Text(dados.nome.isEmpty ? 'Paciente' : dados.nome),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar paciente',
              onPressed: () => context.push(
                '/pacientes/${current.id}/editar',
                extra: current,
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: context.colors.error),
              tooltip: 'Excluir paciente',
              onPressed: () => _confirmDelete(context, current),
            ),
          ],
          bottom: TabBar(
            labelColor: context.colors.textPrimary,
            unselectedLabelColor: context.colors.textSecondary,
            indicatorColor: context.colors.primaryButton,
            tabs: const [
              Tab(text: 'Informações'),
              Tab(text: 'Anexos'),
            ],
          ),
        ),
        body: Column(
          children: [
            current.encerramento == null
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: OutlinedButton.icon(
                      onPressed: () => _encerrarTratamento(context, current),
                      icon: const Icon(Icons.event_busy_outlined),
                      label: const Text('Encerrar tratamento'),
                    ),
                  )
                : _EncerramentoBanner(
                    encerramento: current.encerramento!,
                    onReabrir: () => _reabrirTratamento(context, current),
                  ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const _SectionTitle('Dados pessoais'),
                      _InfoRow('Sexo', _enumValue(dados.sexo, (v) => v.label)),
                      _InfoRow('Idade', _intValue(dados.idade)),
                      _InfoRow('Telefone', _text(dados.telefone)),
                      _InfoRow('Profissão', _text(dados.profissao)),
                      _anamneseSection(current.anamnese),
                      if (isFeminino)
                        _historicoGinecologicoSection(
                          current.historicoGinecologico,
                        ),
                      if (isFeminino)
                        _historicoObstetricoSection(
                          current.historicoObstetrico,
                        ),
                      _historicoCirurgicoSection(current.historicoCirurgico),
                      _funcaoUrinariaSection(current.funcaoUrinaria),
                      _funcaoSexualSection(current.funcaoSexual),
                      _funcaoIntestinalSection(current.funcaoIntestinal),
                      _planoTratamentoSection(current.planoTratamento),
                      const _SectionTitle('Valor da consulta'),
                      _InfoRow(
                        'Valor da 1ª consulta',
                        _money(current.valorConsulta),
                      ),
                    ],
                  ),
                  PatientAttachmentsTab(patientId: current.id),
                ],
              ),
            ),
            AppBottomActionBar(
              child: PrimaryButton(
                label: 'Ver evolução',
                onPressed: () => context.push(
                  '/pacientes/${current.id}/evolucao',
                  extra: current,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _anamneseSection(Anamnese a) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Anamnese'),
        _InfoRow('Queixa principal', _text(a.queixaPrincipal)),
        _InfoRow('Início dos sintomas', _text(a.inicioSintomas)),
        _InfoRow('Tem diagnóstico médico', _yesNo(a.temDiagnosticoMedico)),
        if (a.temDiagnosticoMedico == true)
          _InfoRow('Qual diagnóstico', _text(a.diagnosticoMedico)),
        _InfoRow('Já realizou tratamento', _yesNo(a.realizouTratamento)),
        if (a.realizouTratamento == true)
          _InfoRow('Qual tratamento', _text(a.descricaoTratamento)),
        _InfoRow('Doenças crônicas', _yesNo(a.doencasCronicas)),
        if (a.doencasCronicas == true)
          _InfoRow('Quais doenças', _text(a.descricaoDoencasCronicas)),
        _InfoRow(
          'Uso contínuo de medicamentos',
          _yesNo(a.usoContinuoMedicamentos),
        ),
        if (a.usoContinuoMedicamentos == true)
          _InfoRow('Quais medicamentos', _text(a.descricaoMedicamentos)),
        _InfoRow('Tabagismo', _yesNo(a.tabagismo)),
        _InfoRow('Consome álcool', _yesNo(a.consomeAlcool)),
        _InfoRow('Pratica atividade física', _yesNo(a.praticaAtividadeFisica)),
        _InfoRow('Exames de imagem', _text(a.examesImagem)),
      ],
    );
  }

  Widget _historicoGinecologicoSection(HistoricoGinecologico h) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Histórico ginecológico'),
        _InfoRow(
          'Idade da primeira menstruação',
          _intValue(h.idadePrimeiraMenstruacao),
        ),
        _InfoRow(
          'Fluxo menstrual',
          _enumValue(h.fluxoMenstrual, (v) => v.label),
        ),
        _InfoRow('Presença de cólica (0-10)', _intValue(h.colica0a10)),
        _InfoRow('Menstrua atualmente', _yesNo(h.menstruaAtualmente)),
        if (h.menstruaAtualmente == false) ...[
          _InfoRow('Está na menopausa', _yesNo(h.estaNaMenopausa)),
          _InfoRow(
            'Data aproximada da última menstruação',
            _dateValue(h.dataUltimaMenstruacaoAproximada),
          ),
        ],
        _InfoRow('Ciclo regular', _yesNo(h.cicloRegular)),
        _InfoRow('Menopausa', _yesNo(h.menopausa)),
        _InfoRow('Faz reposição hormonal', _yesNo(h.reposicaoHormonal)),
        if (h.reposicaoHormonal == true)
          _InfoRow(
            'Detalhe da reposição hormonal',
            _text(h.descricaoReposicaoHormonal),
          ),
        _InfoRow(
          'Método contraceptivo',
          _enumValue(h.metodoContraceptivo, (v) => v.label),
        ),
        _InfoRow(
          'Dor pélvica fora do período menstrual',
          _yesNo(h.dorPelvicaForaPeriodo),
        ),
        _InfoRow(
          'Sangramento fora do período menstrual',
          _yesNo(h.sangramentoForaPeriodo),
        ),
        _InfoRow('Endometriose', _yesNo(h.endometriose)),
        _InfoRow(
          'Síndrome dos ovários policísticos',
          _yesNo(h.sindromeOvariosPolicisticos),
        ),
        _InfoRow(
          'Infecções urinárias recorrentes',
          _yesNo(h.infeccoesUrinariasRecorrentes),
        ),
        _InfoRow(
          'Infecções vaginais recorrentes',
          _yesNo(h.infeccoesVaginaisRecorrentes),
        ),
      ],
    );
  }

  Widget _historicoObstetricoSection(HistoricoObstetrico h) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Histórico obstétrico'),
        _InfoRow('Está gestante atualmente', _yesNo(h.estaGestanteAtualmente)),
        if (h.estaGestanteAtualmente == true) ...[
          _InfoRow(
            'Via de parto desejado',
            _enumValue(h.viaDePartoDesejado, (v) => v.label),
          ),
          _InfoRow('Quantas semanas', _intValue(h.semanasGestacao)),
          _InfoRow('Data provável do parto', _dateValue(h.dataProvavelParto)),
          _InfoRow('Gestação de risco', _yesNo(h.gestacaoDeRisco)),
          if (h.gestacaoDeRisco == true)
            _InfoRow(
              'Detalhe da gestação de risco',
              _text(h.descricaoGestacaoRisco),
            ),
        ],
        _InfoRow('Já engravidou', _yesNo(h.jaEngravidou)),
        if (h.jaEngravidou == true) ...[
          _InfoRow('Quantas gestações', _intValue(h.numeroGestacoes)),
          for (var i = 0; i < h.gestacoes.length; i++)
            _GestacaoCard(index: i, gestacao: h.gestacoes[i]),
        ],
      ],
    );
  }

  Widget _historicoCirurgicoSection(HistoricoCirurgico h) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Histórico cirúrgico'),
        _InfoRow(
          'Cirurgias',
          h.cirurgias.isEmpty
              ? _naoInformado
              : h.cirurgias.map((c) => c.label).join(', '),
        ),
        if (h.cirurgias.contains(CirurgiaGinecologica.outro))
          _InfoRow('Qual cirurgia', _text(h.descricaoOutraCirurgia)),
      ],
    );
  }

  Widget _funcaoUrinariaSection(FuncaoUrinaria f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Função urinária'),
        _InfoRow('Urgência', _yesNo(f.urgencia)),
        if (f.urgencia == true)
          _InfoRow('Detalhe da urgência', _text(f.descricaoUrgencia)),
        _InfoRow(
          'Perda associada à urgência',
          _yesNo(f.perdaAssociadaUrgencia),
        ),
        _InfoRow('Incontinência de esforço', _yesNo(f.incontinenciaEsforco)),
        if (f.incontinenciaEsforco == true) ...[
          _InfoRow(
            'Gatilhos',
            f.gatilhosIncontinencia.isEmpty
                ? _naoInformado
                : f.gatilhosIncontinencia.map((g) => g.label).join(', '),
          ),
          if (f.gatilhosIncontinencia.contains(GatilhoIncontinencia.outros))
            _InfoRow('Qual outro gatilho', _text(f.descricaoOutroGatilho)),
        ],
        if (f.perdaAssociadaUrgencia == true || f.incontinenciaEsforco == true)
          _InfoRow(
            'Quantidade aproximada da perda',
            _enumValue(f.quantidadePerda, (v) => v.label),
          ),
        _InfoRow('Utiliza absorvente ou protetor', _yesNo(f.utilizaAbsorvente)),
        if (f.utilizaAbsorvente == true)
          _InfoRow('Quantos por dia', _intValue(f.quantosAbsorventes)),
        _InfoRow('Dor ou ardência ao urinar', _yesNo(f.dorArdenciaAoUrinar)),
        _InfoRow('Jato urinário fraco', _yesNo(f.jatoUrinarioFraco)),
        _InfoRow('Enurese noturna', _yesNo(f.enureseNoturna)),
        if (f.enureseNoturna == true)
          _InfoRow('Detalhe da enurese', _text(f.descricaoEnurese)),
        _InfoRow('Hesitação', _yesNo(f.hesitacao)),
        if (f.hesitacao == true)
          _InfoRow('Detalhe da hesitação', _text(f.descricaoHesitacao)),
        _InfoRow('Esforço miccional', _yesNo(f.esforcoMiccional)),
        if (f.esforcoMiccional == true)
          _InfoRow(
            'Detalhe do esforço miccional',
            _text(f.descricaoEsforcoMiccional),
          ),
        _InfoRow(
          'Gotejamento pós miccional',
          _yesNo(f.gotejamentoPosMiccional),
        ),
        if (f.gotejamentoPosMiccional == true)
          _InfoRow('Detalhe do gotejamento', _text(f.descricaoGotejamento)),
        _InfoRow(
          'Sensação de esvaziamento incompleto',
          _yesNo(f.esvaziamentoIncompleto),
        ),
        if (f.esvaziamentoIncompleto == true)
          _InfoRow(
            'Detalhe do esvaziamento',
            _text(f.descricaoEsvaziamentoIncompleto),
          ),
      ],
    );
  }

  Widget _funcaoSexualSection(FuncaoSexual f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Função sexual'),
        _InfoRow('Vida sexual ativa', _yesNo(f.vidaSexualAtiva)),
        if (f.vidaSexualAtiva == true) ...[
          _InfoRow(
            'Frequência de atividade sexual',
            _text(f.frequenciaAtividadeSexual),
          ),
          _InfoRow('Precisa usar lubrificante', _yesNo(f.precisaLubrificante)),
          _InfoRow('Sensação de ressecamento', _yesNo(f.ressecamento)),
          _InfoRow(
            'Dificuldade para atingir o orgasmo',
            _yesNo(f.dificuldadeOrgasmo),
          ),
          if (f.dificuldadeOrgasmo == true)
            _InfoRow('Detalhe', _text(f.descricaoDificuldadeOrgasmo)),
          _InfoRow('Dor na penetração', _yesNo(f.dorNaPenetracao)),
          if (f.dorNaPenetracao == true)
            _InfoRow(
              'Tipo de dor',
              _enumValue(f.tipoDorPenetracao, (v) => v.label),
            ),
          _InfoRow(
            'Dor durante ou depois da relação',
            _yesNo(f.dorDuranteOuDepoisRelacao),
          ),
          if (f.dorNaPenetracao == true || f.dorDuranteOuDepoisRelacao == true)
            _InfoRow(
              'Intensidade da dor (0-10)',
              _intValue(f.intensidadeDor0a10),
            ),
          _InfoRow('Desejo sexual', _enumValue(f.desejoSexual, (v) => v.label)),
        ],
      ],
    );
  }

  Widget _planoTratamentoSection(PlanoTratamento p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Plano de tratamento'),
        _InfoRow(
          'Diagnóstico fisioterapêutico',
          _text(p.diagnosticoFisioterapeutico),
        ),
        _InfoRow('Objetivo do tratamento', _text(p.objetivoTratamento)),
        _InfoRow('Conduta / plano de tratamento', _text(p.condutaTratamento)),
        _InfoRow('Frequência sugerida', _text(p.frequenciaSugerida)),
      ],
    );
  }

  Widget _funcaoIntestinalSection(FuncaoIntestinal f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Função intestinal'),
        _InfoRow(
          'Frequência evacuatória',
          _enumValue(f.frequenciaEvacuatoria, (v) => v.label),
        ),
        if (f.frequenciaEvacuatoria == FrequenciaEvacuatoria.personalizado)
          _InfoRow(
            'Quantas vezes por semana',
            _intValue(f.frequenciaPersonalizadaValor),
          ),
        _InfoRow('Usa laxante', _yesNo(f.usaLaxante)),
        if (f.usaLaxante == true)
          _InfoRow('Qual laxante e frequência', _text(f.descricaoLaxante)),
        _InfoRow('Faz força para evacuar', _yesNo(f.forcaParaEvacuar)),
        _InfoRow('Sente dor para evacuar', _yesNo(f.dorParaEvacuar)),
        _InfoRow(
          'Sensação de esvaziamento incompleto',
          _yesNo(f.esvaziamentoIncompleto),
        ),
        _InfoRow('Sensação de obstrução', _yesNo(f.sensacaoObstrucao)),
        _InfoRow('Urgência fecal', _yesNo(f.urgenciaFecal)),
        _InfoRow('Presença de hemorroidas', _yesNo(f.presencaHemorroidas)),
        _InfoRow('Perde gases', _yesNo(f.perdeGases)),
        _InfoRow('Perde fezes', _yesNo(f.perdeFezes)),
        _InfoRow(
          'Escala de Bristol',
          _enumValue(f.escalaBristol, (v) => v.label),
        ),
      ],
    );
  }
}

class _EncerramentoBanner extends StatelessWidget {
  const _EncerramentoBanner({
    required this.encerramento,
    required this.onReabrir,
  });

  final Encerramento encerramento;
  final VoidCallback onReabrir;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.textHint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.event_busy_outlined, color: context.colors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tratamento encerrado em ${AppDateField.format(encerramento.data)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Motivo: ${encerramento.motivo.label}',
                  style: TextStyle(color: context.colors.textSecondary),
                ),
                if ((encerramento.observacaoFinal ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    encerramento.observacaoFinal!,
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          TextButton(onPressed: onReabrir, child: const Text('Reabrir')),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: context.colors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isMissing = value == _naoInformado;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: isMissing
                    ? context.colors.textHint
                    : context.colors.textPrimary,
                fontStyle: isMissing ? FontStyle.italic : FontStyle.normal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GestacaoCard extends StatelessWidget {
  const _GestacaoCard({required this.index, required this.gestacao});

  final int index;
  final Gestacao gestacao;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gestação ${index + 1}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: 8),
          _InfoRow('Perda gestacional', _yesNo(gestacao.perdaGestacional)),
          if (gestacao.perdaGestacional == true)
            _InfoRow('Detalhe da perda', _text(gestacao.descricaoPerda))
          else if (gestacao.perdaGestacional == false) ...[
            _InfoRow(
              'Via de parto',
              _enumValue(gestacao.viaDeParto, (v) => v.label),
            ),
            if (gestacao.viaDeParto == ViaDeParto.normal)
              _InfoRow(
                'Complicação no parto',
                _enumValue(gestacao.complicacaoParto, (v) => v.label),
              ),
            if (gestacao.viaDeParto == ViaDeParto.normal)
              _InfoRow(
                'Uso de fórceps ou vácuo',
                _yesNo(gestacao.usoForcepsOuVacuo),
              ),
            _InfoRow(
              'Peso aproximado do bebê',
              _text(gestacao.pesoAproximadoBebe),
            ),
            _InfoRow('Teve complicações', _yesNo(gestacao.teveComplicacoes)),
            if (gestacao.teveComplicacoes == true)
              _InfoRow(
                'Detalhe das complicações',
                _text(gestacao.descricaoComplicacao),
              ),
          ],
        ],
      ),
    );
  }
}
