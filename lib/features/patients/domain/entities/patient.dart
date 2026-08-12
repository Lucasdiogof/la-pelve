import 'package:equatable/equatable.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/gestacao.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/shared/utils/enum_from_name.dart';
import 'package:fisioterapia_pelvica/shared/utils/unset.dart';

class DadosPessoais extends Equatable {
  const DadosPessoais({
    this.nome = '',
    this.idade,
    this.telefone = '',
    this.profissao = '',
    this.sexo,
  });

  final String nome;
  final int? idade;
  final String telefone;
  final String profissao;
  final Sexo? sexo;

  DadosPessoais copyWith({
    String? nome,
    int? idade,
    String? telefone,
    String? profissao,
    Sexo? sexo,
  }) {
    return DadosPessoais(
      nome: nome ?? this.nome,
      idade: idade ?? this.idade,
      telefone: telefone ?? this.telefone,
      profissao: profissao ?? this.profissao,
      sexo: sexo ?? this.sexo,
    );
  }

  @override
  List<Object?> get props => [nome, idade, telefone, profissao, sexo];
}

class Anamnese extends Equatable {
  const Anamnese({
    this.queixaPrincipal = '',
    this.temDiagnosticoMedico,
    this.diagnosticoMedico,
    this.inicioSintomas = '',
    this.realizouTratamento,
    this.descricaoTratamento,
    this.doencasCronicas,
    this.descricaoDoencasCronicas,
    this.usoContinuoMedicamentos,
    this.descricaoMedicamentos,
    this.tabagismo,
    this.consomeAlcool,
    this.praticaAtividadeFisica,
    this.examesImagem,
  });

  final String queixaPrincipal;
  final bool? temDiagnosticoMedico;
  final String? diagnosticoMedico;
  final String inicioSintomas;
  final bool? realizouTratamento;
  final String? descricaoTratamento;
  final bool? doencasCronicas;
  final String? descricaoDoencasCronicas;
  final bool? usoContinuoMedicamentos;
  final String? descricaoMedicamentos;
  final bool? tabagismo;
  final bool? consomeAlcool;
  final bool? praticaAtividadeFisica;
  final String? examesImagem;

  Anamnese copyWith({
    String? queixaPrincipal,
    Object? temDiagnosticoMedico = kUnset,
    String? diagnosticoMedico,
    String? inicioSintomas,
    Object? realizouTratamento = kUnset,
    String? descricaoTratamento,
    Object? doencasCronicas = kUnset,
    String? descricaoDoencasCronicas,
    Object? usoContinuoMedicamentos = kUnset,
    String? descricaoMedicamentos,
    Object? tabagismo = kUnset,
    Object? consomeAlcool = kUnset,
    Object? praticaAtividadeFisica = kUnset,
    String? examesImagem,
  }) {
    return Anamnese(
      queixaPrincipal: queixaPrincipal ?? this.queixaPrincipal,
      temDiagnosticoMedico: unsetOr(
        temDiagnosticoMedico,
        this.temDiagnosticoMedico,
      ),
      diagnosticoMedico: diagnosticoMedico ?? this.diagnosticoMedico,
      inicioSintomas: inicioSintomas ?? this.inicioSintomas,
      realizouTratamento: unsetOr(realizouTratamento, this.realizouTratamento),
      descricaoTratamento: descricaoTratamento ?? this.descricaoTratamento,
      doencasCronicas: unsetOr(doencasCronicas, this.doencasCronicas),
      descricaoDoencasCronicas:
          descricaoDoencasCronicas ?? this.descricaoDoencasCronicas,
      usoContinuoMedicamentos: unsetOr(
        usoContinuoMedicamentos,
        this.usoContinuoMedicamentos,
      ),
      descricaoMedicamentos:
          descricaoMedicamentos ?? this.descricaoMedicamentos,
      tabagismo: unsetOr(tabagismo, this.tabagismo),
      consomeAlcool: unsetOr(consomeAlcool, this.consomeAlcool),
      praticaAtividadeFisica: unsetOr(
        praticaAtividadeFisica,
        this.praticaAtividadeFisica,
      ),
      examesImagem: examesImagem ?? this.examesImagem,
    );
  }

  Map<String, dynamic> toJson() => {
    'queixaPrincipal': queixaPrincipal,
    'temDiagnosticoMedico': temDiagnosticoMedico,
    'diagnosticoMedico': diagnosticoMedico,
    'inicioSintomas': inicioSintomas,
    'realizouTratamento': realizouTratamento,
    'descricaoTratamento': descricaoTratamento,
    'doencasCronicas': doencasCronicas,
    'descricaoDoencasCronicas': descricaoDoencasCronicas,
    'usoContinuoMedicamentos': usoContinuoMedicamentos,
    'descricaoMedicamentos': descricaoMedicamentos,
    'tabagismo': tabagismo,
    'consomeAlcool': consomeAlcool,
    'praticaAtividadeFisica': praticaAtividadeFisica,
    'examesImagem': examesImagem,
  };

  factory Anamnese.fromJson(Map<String, dynamic> json) => Anamnese(
    queixaPrincipal: json['queixaPrincipal'] as String? ?? '',
    temDiagnosticoMedico: json['temDiagnosticoMedico'] as bool?,
    diagnosticoMedico: json['diagnosticoMedico'] as String?,
    inicioSintomas: json['inicioSintomas'] as String? ?? '',
    realizouTratamento: json['realizouTratamento'] as bool?,
    descricaoTratamento: json['descricaoTratamento'] as String?,
    doencasCronicas: json['doencasCronicas'] as bool?,
    descricaoDoencasCronicas: json['descricaoDoencasCronicas'] as String?,
    usoContinuoMedicamentos: json['usoContinuoMedicamentos'] as bool?,
    descricaoMedicamentos: json['descricaoMedicamentos'] as String?,
    tabagismo: json['tabagismo'] as bool?,
    consomeAlcool: json['consomeAlcool'] as bool?,
    praticaAtividadeFisica: json['praticaAtividadeFisica'] as bool?,
    examesImagem: json['examesImagem'] as String?,
  );

  @override
  List<Object?> get props => [
    queixaPrincipal,
    temDiagnosticoMedico,
    diagnosticoMedico,
    inicioSintomas,
    realizouTratamento,
    descricaoTratamento,
    doencasCronicas,
    descricaoDoencasCronicas,
    usoContinuoMedicamentos,
    descricaoMedicamentos,
    tabagismo,
    consomeAlcool,
    praticaAtividadeFisica,
    examesImagem,
  ];
}

class HistoricoGinecologico extends Equatable {
  const HistoricoGinecologico({
    this.idadePrimeiraMenstruacao,
    this.menstruaAtualmente,
    this.cicloRegular,
    this.metodoContraceptivo,
    this.menopausa,
    this.reposicaoHormonal,
    this.descricaoReposicaoHormonal,
    this.fluxoMenstrual,
    this.colica0a10,
    this.estaNaMenopausa,
    this.dataUltimaMenstruacaoAproximada,
    this.dorPelvicaForaPeriodo,
    this.sangramentoForaPeriodo,
    this.endometriose,
    this.sindromeOvariosPolicisticos,
    this.infeccoesUrinariasRecorrentes,
    this.infeccoesVaginaisRecorrentes,
  });

  final int? idadePrimeiraMenstruacao;
  final bool? menstruaAtualmente;
  final bool? cicloRegular;
  final MetodoContraceptivo? metodoContraceptivo;
  final bool? menopausa;
  final bool? reposicaoHormonal;
  final String? descricaoReposicaoHormonal;
  final FluxoMenstrual? fluxoMenstrual;
  final int? colica0a10;
  final bool? estaNaMenopausa;
  final DateTime? dataUltimaMenstruacaoAproximada;
  final bool? dorPelvicaForaPeriodo;
  final bool? sangramentoForaPeriodo;
  final bool? endometriose;
  final bool? sindromeOvariosPolicisticos;
  final bool? infeccoesUrinariasRecorrentes;
  final bool? infeccoesVaginaisRecorrentes;

  HistoricoGinecologico copyWith({
    int? idadePrimeiraMenstruacao,
    Object? menstruaAtualmente = kUnset,
    Object? cicloRegular = kUnset,
    MetodoContraceptivo? metodoContraceptivo,
    Object? menopausa = kUnset,
    Object? reposicaoHormonal = kUnset,
    String? descricaoReposicaoHormonal,
    FluxoMenstrual? fluxoMenstrual,
    int? colica0a10,
    Object? estaNaMenopausa = kUnset,
    DateTime? dataUltimaMenstruacaoAproximada,
    Object? dorPelvicaForaPeriodo = kUnset,
    Object? sangramentoForaPeriodo = kUnset,
    Object? endometriose = kUnset,
    Object? sindromeOvariosPolicisticos = kUnset,
    Object? infeccoesUrinariasRecorrentes = kUnset,
    Object? infeccoesVaginaisRecorrentes = kUnset,
  }) {
    return HistoricoGinecologico(
      idadePrimeiraMenstruacao:
          idadePrimeiraMenstruacao ?? this.idadePrimeiraMenstruacao,
      menstruaAtualmente: unsetOr(menstruaAtualmente, this.menstruaAtualmente),
      cicloRegular: unsetOr(cicloRegular, this.cicloRegular),
      metodoContraceptivo: metodoContraceptivo ?? this.metodoContraceptivo,
      menopausa: unsetOr(menopausa, this.menopausa),
      reposicaoHormonal: unsetOr(reposicaoHormonal, this.reposicaoHormonal),
      descricaoReposicaoHormonal:
          descricaoReposicaoHormonal ?? this.descricaoReposicaoHormonal,
      fluxoMenstrual: fluxoMenstrual ?? this.fluxoMenstrual,
      colica0a10: colica0a10 ?? this.colica0a10,
      estaNaMenopausa: unsetOr(estaNaMenopausa, this.estaNaMenopausa),
      dataUltimaMenstruacaoAproximada:
          dataUltimaMenstruacaoAproximada ??
          this.dataUltimaMenstruacaoAproximada,
      dorPelvicaForaPeriodo: unsetOr(
        dorPelvicaForaPeriodo,
        this.dorPelvicaForaPeriodo,
      ),
      sangramentoForaPeriodo: unsetOr(
        sangramentoForaPeriodo,
        this.sangramentoForaPeriodo,
      ),
      endometriose: unsetOr(endometriose, this.endometriose),
      sindromeOvariosPolicisticos: unsetOr(
        sindromeOvariosPolicisticos,
        this.sindromeOvariosPolicisticos,
      ),
      infeccoesUrinariasRecorrentes: unsetOr(
        infeccoesUrinariasRecorrentes,
        this.infeccoesUrinariasRecorrentes,
      ),
      infeccoesVaginaisRecorrentes: unsetOr(
        infeccoesVaginaisRecorrentes,
        this.infeccoesVaginaisRecorrentes,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'idadePrimeiraMenstruacao': idadePrimeiraMenstruacao,
    'menstruaAtualmente': menstruaAtualmente,
    'cicloRegular': cicloRegular,
    'metodoContraceptivo': metodoContraceptivo?.name,
    'menopausa': menopausa,
    'reposicaoHormonal': reposicaoHormonal,
    'descricaoReposicaoHormonal': descricaoReposicaoHormonal,
    'fluxoMenstrual': fluxoMenstrual?.name,
    'colica0a10': colica0a10,
    'estaNaMenopausa': estaNaMenopausa,
    'dataUltimaMenstruacaoAproximada': dataUltimaMenstruacaoAproximada
        ?.toIso8601String(),
    'dorPelvicaForaPeriodo': dorPelvicaForaPeriodo,
    'sangramentoForaPeriodo': sangramentoForaPeriodo,
    'endometriose': endometriose,
    'sindromeOvariosPolicisticos': sindromeOvariosPolicisticos,
    'infeccoesUrinariasRecorrentes': infeccoesUrinariasRecorrentes,
    'infeccoesVaginaisRecorrentes': infeccoesVaginaisRecorrentes,
  };

  factory HistoricoGinecologico.fromJson(
    Map<String, dynamic> json,
  ) => HistoricoGinecologico(
    idadePrimeiraMenstruacao: json['idadePrimeiraMenstruacao'] as int?,
    menstruaAtualmente: json['menstruaAtualmente'] as bool?,
    cicloRegular: json['cicloRegular'] as bool?,
    metodoContraceptivo: enumFromName(
      MetodoContraceptivo.values,
      json['metodoContraceptivo'],
    ),
    menopausa: json['menopausa'] as bool?,
    reposicaoHormonal: json['reposicaoHormonal'] as bool?,
    descricaoReposicaoHormonal: json['descricaoReposicaoHormonal'] as String?,
    fluxoMenstrual: enumFromName(FluxoMenstrual.values, json['fluxoMenstrual']),
    colica0a10: json['colica0a10'] as int?,
    estaNaMenopausa: json['estaNaMenopausa'] as bool?,
    dataUltimaMenstruacaoAproximada:
        json['dataUltimaMenstruacaoAproximada'] == null
        ? null
        : DateTime.parse(json['dataUltimaMenstruacaoAproximada'] as String),
    dorPelvicaForaPeriodo: json['dorPelvicaForaPeriodo'] as bool?,
    sangramentoForaPeriodo: json['sangramentoForaPeriodo'] as bool?,
    endometriose: json['endometriose'] as bool?,
    sindromeOvariosPolicisticos: json['sindromeOvariosPolicisticos'] as bool?,
    infeccoesUrinariasRecorrentes:
        json['infeccoesUrinariasRecorrentes'] as bool?,
    infeccoesVaginaisRecorrentes: json['infeccoesVaginaisRecorrentes'] as bool?,
  );

  @override
  List<Object?> get props => [
    idadePrimeiraMenstruacao,
    menstruaAtualmente,
    cicloRegular,
    metodoContraceptivo,
    menopausa,
    reposicaoHormonal,
    descricaoReposicaoHormonal,
    fluxoMenstrual,
    colica0a10,
    estaNaMenopausa,
    dataUltimaMenstruacaoAproximada,
    dorPelvicaForaPeriodo,
    sangramentoForaPeriodo,
    endometriose,
    sindromeOvariosPolicisticos,
    infeccoesUrinariasRecorrentes,
    infeccoesVaginaisRecorrentes,
  ];
}

class HistoricoObstetrico extends Equatable {
  const HistoricoObstetrico({
    this.jaEngravidou,
    this.numeroGestacoes,
    this.gestacoes = const [],
    this.estaGestanteAtualmente,
    this.viaDePartoDesejado,
    this.semanasGestacao,
    this.dataProvavelParto,
    this.gestacaoDeRisco,
    this.descricaoGestacaoRisco,
  });

  final bool? jaEngravidou;
  final int? numeroGestacoes;
  final List<Gestacao> gestacoes;
  final bool? estaGestanteAtualmente;
  final ViaDeParto? viaDePartoDesejado;
  final int? semanasGestacao;
  final DateTime? dataProvavelParto;
  final bool? gestacaoDeRisco;
  final String? descricaoGestacaoRisco;

  HistoricoObstetrico copyWith({
    Object? jaEngravidou = kUnset,
    int? numeroGestacoes,
    List<Gestacao>? gestacoes,
    Object? estaGestanteAtualmente = kUnset,
    ViaDeParto? viaDePartoDesejado,
    int? semanasGestacao,
    DateTime? dataProvavelParto,
    Object? gestacaoDeRisco = kUnset,
    String? descricaoGestacaoRisco,
  }) {
    return HistoricoObstetrico(
      jaEngravidou: unsetOr(jaEngravidou, this.jaEngravidou),
      numeroGestacoes: numeroGestacoes ?? this.numeroGestacoes,
      gestacoes: gestacoes ?? this.gestacoes,
      estaGestanteAtualmente: unsetOr(
        estaGestanteAtualmente,
        this.estaGestanteAtualmente,
      ),
      viaDePartoDesejado: viaDePartoDesejado ?? this.viaDePartoDesejado,
      semanasGestacao: semanasGestacao ?? this.semanasGestacao,
      dataProvavelParto: dataProvavelParto ?? this.dataProvavelParto,
      gestacaoDeRisco: unsetOr(gestacaoDeRisco, this.gestacaoDeRisco),
      descricaoGestacaoRisco:
          descricaoGestacaoRisco ?? this.descricaoGestacaoRisco,
    );
  }

  Map<String, dynamic> toJson() => {
    'jaEngravidou': jaEngravidou,
    'numeroGestacoes': numeroGestacoes,
    'gestacoes': gestacoes.map((g) => g.toJson()).toList(),
    'estaGestanteAtualmente': estaGestanteAtualmente,
    'viaDePartoDesejado': viaDePartoDesejado?.name,
    'semanasGestacao': semanasGestacao,
    'dataProvavelParto': dataProvavelParto?.toIso8601String(),
    'gestacaoDeRisco': gestacaoDeRisco,
    'descricaoGestacaoRisco': descricaoGestacaoRisco,
  };

  factory HistoricoObstetrico.fromJson(Map<String, dynamic> json) =>
      HistoricoObstetrico(
        jaEngravidou: json['jaEngravidou'] as bool?,
        numeroGestacoes: json['numeroGestacoes'] as int?,
        gestacoes: (json['gestacoes'] as List<dynamic>? ?? [])
            .map((g) => Gestacao.fromJson(g as Map<String, dynamic>))
            .toList(),
        estaGestanteAtualmente: json['estaGestanteAtualmente'] as bool?,
        viaDePartoDesejado: enumFromName(
          ViaDeParto.values,
          json['viaDePartoDesejado'],
        ),
        semanasGestacao: json['semanasGestacao'] as int?,
        dataProvavelParto: json['dataProvavelParto'] == null
            ? null
            : DateTime.parse(json['dataProvavelParto'] as String),
        gestacaoDeRisco: json['gestacaoDeRisco'] as bool?,
        descricaoGestacaoRisco: json['descricaoGestacaoRisco'] as String?,
      );

  @override
  List<Object?> get props => [
    jaEngravidou,
    numeroGestacoes,
    gestacoes,
    estaGestanteAtualmente,
    viaDePartoDesejado,
    semanasGestacao,
    dataProvavelParto,
    gestacaoDeRisco,
    descricaoGestacaoRisco,
  ];
}

class HistoricoCirurgico extends Equatable {
  const HistoricoCirurgico({
    this.cirurgias = const {},
    this.descricaoOutraCirurgia,
  });

  final Set<CirurgiaGinecologica> cirurgias;
  final String? descricaoOutraCirurgia;

  HistoricoCirurgico copyWith({
    Set<CirurgiaGinecologica>? cirurgias,
    String? descricaoOutraCirurgia,
  }) {
    return HistoricoCirurgico(
      cirurgias: cirurgias ?? this.cirurgias,
      descricaoOutraCirurgia:
          descricaoOutraCirurgia ?? this.descricaoOutraCirurgia,
    );
  }

  Map<String, dynamic> toJson() => {
    'cirurgias': cirurgias.map((c) => c.name).toList(),
    'descricaoOutraCirurgia': descricaoOutraCirurgia,
  };

  factory HistoricoCirurgico.fromJson(Map<String, dynamic> json) =>
      HistoricoCirurgico(
        cirurgias: (json['cirurgias'] as List<dynamic>? ?? [])
            .map((name) => enumFromName(CirurgiaGinecologica.values, name))
            .whereType<CirurgiaGinecologica>()
            .toSet(),
        descricaoOutraCirurgia: json['descricaoOutraCirurgia'] as String?,
      );

  @override
  List<Object?> get props => [cirurgias, descricaoOutraCirurgia];
}

class FuncaoUrinaria extends Equatable {
  const FuncaoUrinaria({
    this.urgencia,
    this.descricaoUrgencia,
    this.incontinenciaEsforco,
    this.gatilhosIncontinencia = const {},
    this.descricaoOutroGatilho,
    this.enureseNoturna,
    this.descricaoEnurese,
    this.hesitacao,
    this.descricaoHesitacao,
    this.esforcoMiccional,
    this.descricaoEsforcoMiccional,
    this.gotejamentoPosMiccional,
    this.descricaoGotejamento,
    this.esvaziamentoIncompleto,
    this.descricaoEsvaziamentoIncompleto,
    this.perdaAssociadaUrgencia,
    this.quantidadePerda,
    this.utilizaAbsorvente,
    this.quantosAbsorventes,
    this.dorArdenciaAoUrinar,
    this.jatoUrinarioFraco,
  });

  final bool? urgencia;
  final String? descricaoUrgencia;
  final bool? incontinenciaEsforco;
  final Set<GatilhoIncontinencia> gatilhosIncontinencia;
  final String? descricaoOutroGatilho;
  final bool? enureseNoturna;
  final String? descricaoEnurese;
  final bool? hesitacao;
  final String? descricaoHesitacao;
  final bool? esforcoMiccional;
  final String? descricaoEsforcoMiccional;
  final bool? gotejamentoPosMiccional;
  final String? descricaoGotejamento;
  final bool? esvaziamentoIncompleto;
  final String? descricaoEsvaziamentoIncompleto;
  final bool? perdaAssociadaUrgencia;
  final QuantidadePerda? quantidadePerda;
  final bool? utilizaAbsorvente;
  final int? quantosAbsorventes;
  final bool? dorArdenciaAoUrinar;
  final bool? jatoUrinarioFraco;

  FuncaoUrinaria copyWith({
    Object? urgencia = kUnset,
    String? descricaoUrgencia,
    Object? incontinenciaEsforco = kUnset,
    Set<GatilhoIncontinencia>? gatilhosIncontinencia,
    String? descricaoOutroGatilho,
    Object? enureseNoturna = kUnset,
    String? descricaoEnurese,
    Object? hesitacao = kUnset,
    String? descricaoHesitacao,
    Object? esforcoMiccional = kUnset,
    String? descricaoEsforcoMiccional,
    Object? gotejamentoPosMiccional = kUnset,
    String? descricaoGotejamento,
    Object? esvaziamentoIncompleto = kUnset,
    String? descricaoEsvaziamentoIncompleto,
    Object? perdaAssociadaUrgencia = kUnset,
    QuantidadePerda? quantidadePerda,
    Object? utilizaAbsorvente = kUnset,
    int? quantosAbsorventes,
    Object? dorArdenciaAoUrinar = kUnset,
    Object? jatoUrinarioFraco = kUnset,
  }) {
    return FuncaoUrinaria(
      urgencia: unsetOr(urgencia, this.urgencia),
      descricaoUrgencia: descricaoUrgencia ?? this.descricaoUrgencia,
      incontinenciaEsforco: unsetOr(
        incontinenciaEsforco,
        this.incontinenciaEsforco,
      ),
      gatilhosIncontinencia:
          gatilhosIncontinencia ?? this.gatilhosIncontinencia,
      descricaoOutroGatilho:
          descricaoOutroGatilho ?? this.descricaoOutroGatilho,
      enureseNoturna: unsetOr(enureseNoturna, this.enureseNoturna),
      descricaoEnurese: descricaoEnurese ?? this.descricaoEnurese,
      hesitacao: unsetOr(hesitacao, this.hesitacao),
      descricaoHesitacao: descricaoHesitacao ?? this.descricaoHesitacao,
      esforcoMiccional: unsetOr(esforcoMiccional, this.esforcoMiccional),
      descricaoEsforcoMiccional:
          descricaoEsforcoMiccional ?? this.descricaoEsforcoMiccional,
      gotejamentoPosMiccional: unsetOr(
        gotejamentoPosMiccional,
        this.gotejamentoPosMiccional,
      ),
      descricaoGotejamento: descricaoGotejamento ?? this.descricaoGotejamento,
      esvaziamentoIncompleto: unsetOr(
        esvaziamentoIncompleto,
        this.esvaziamentoIncompleto,
      ),
      descricaoEsvaziamentoIncompleto:
          descricaoEsvaziamentoIncompleto ??
          this.descricaoEsvaziamentoIncompleto,
      perdaAssociadaUrgencia: unsetOr(
        perdaAssociadaUrgencia,
        this.perdaAssociadaUrgencia,
      ),
      quantidadePerda: quantidadePerda ?? this.quantidadePerda,
      utilizaAbsorvente: unsetOr(utilizaAbsorvente, this.utilizaAbsorvente),
      quantosAbsorventes: quantosAbsorventes ?? this.quantosAbsorventes,
      dorArdenciaAoUrinar: unsetOr(
        dorArdenciaAoUrinar,
        this.dorArdenciaAoUrinar,
      ),
      jatoUrinarioFraco: unsetOr(jatoUrinarioFraco, this.jatoUrinarioFraco),
    );
  }

  Map<String, dynamic> toJson() => {
    'urgencia': urgencia,
    'descricaoUrgencia': descricaoUrgencia,
    'incontinenciaEsforco': incontinenciaEsforco,
    'gatilhosIncontinencia': gatilhosIncontinencia.map((g) => g.name).toList(),
    'descricaoOutroGatilho': descricaoOutroGatilho,
    'enureseNoturna': enureseNoturna,
    'descricaoEnurese': descricaoEnurese,
    'hesitacao': hesitacao,
    'descricaoHesitacao': descricaoHesitacao,
    'esforcoMiccional': esforcoMiccional,
    'descricaoEsforcoMiccional': descricaoEsforcoMiccional,
    'gotejamentoPosMiccional': gotejamentoPosMiccional,
    'descricaoGotejamento': descricaoGotejamento,
    'esvaziamentoIncompleto': esvaziamentoIncompleto,
    'descricaoEsvaziamentoIncompleto': descricaoEsvaziamentoIncompleto,
    'perdaAssociadaUrgencia': perdaAssociadaUrgencia,
    'quantidadePerda': quantidadePerda?.name,
    'utilizaAbsorvente': utilizaAbsorvente,
    'quantosAbsorventes': quantosAbsorventes,
    'dorArdenciaAoUrinar': dorArdenciaAoUrinar,
    'jatoUrinarioFraco': jatoUrinarioFraco,
  };

  factory FuncaoUrinaria.fromJson(Map<String, dynamic> json) => FuncaoUrinaria(
    urgencia: json['urgencia'] as bool?,
    descricaoUrgencia: json['descricaoUrgencia'] as String?,
    incontinenciaEsforco: json['incontinenciaEsforco'] as bool?,
    gatilhosIncontinencia:
        (json['gatilhosIncontinencia'] as List<dynamic>? ?? [])
            .map((name) => enumFromName(GatilhoIncontinencia.values, name))
            .whereType<GatilhoIncontinencia>()
            .toSet(),
    descricaoOutroGatilho: json['descricaoOutroGatilho'] as String?,
    enureseNoturna: json['enureseNoturna'] as bool?,
    descricaoEnurese: json['descricaoEnurese'] as String?,
    hesitacao: json['hesitacao'] as bool?,
    descricaoHesitacao: json['descricaoHesitacao'] as String?,
    esforcoMiccional: json['esforcoMiccional'] as bool?,
    descricaoEsforcoMiccional: json['descricaoEsforcoMiccional'] as String?,
    gotejamentoPosMiccional: json['gotejamentoPosMiccional'] as bool?,
    descricaoGotejamento: json['descricaoGotejamento'] as String?,
    esvaziamentoIncompleto: json['esvaziamentoIncompleto'] as bool?,
    descricaoEsvaziamentoIncompleto:
        json['descricaoEsvaziamentoIncompleto'] as String?,
    perdaAssociadaUrgencia: json['perdaAssociadaUrgencia'] as bool?,
    quantidadePerda: enumFromName(
      QuantidadePerda.values,
      json['quantidadePerda'],
    ),
    utilizaAbsorvente: json['utilizaAbsorvente'] as bool?,
    quantosAbsorventes: json['quantosAbsorventes'] as int?,
    dorArdenciaAoUrinar: json['dorArdenciaAoUrinar'] as bool?,
    jatoUrinarioFraco: json['jatoUrinarioFraco'] as bool?,
  );

  @override
  List<Object?> get props => [
    urgencia,
    descricaoUrgencia,
    incontinenciaEsforco,
    gatilhosIncontinencia,
    descricaoOutroGatilho,
    enureseNoturna,
    descricaoEnurese,
    hesitacao,
    descricaoHesitacao,
    esforcoMiccional,
    descricaoEsforcoMiccional,
    gotejamentoPosMiccional,
    descricaoGotejamento,
    esvaziamentoIncompleto,
    descricaoEsvaziamentoIncompleto,
    perdaAssociadaUrgencia,
    quantidadePerda,
    utilizaAbsorvente,
    quantosAbsorventes,
    dorArdenciaAoUrinar,
    jatoUrinarioFraco,
  ];
}

class FuncaoSexual extends Equatable {
  const FuncaoSexual({
    this.vidaSexualAtiva,
    this.precisaLubrificante,
    this.dificuldadeOrgasmo,
    this.descricaoDificuldadeOrgasmo,
    this.desejoSexual,
    this.frequenciaAtividadeSexual,
    this.dorNaPenetracao,
    this.tipoDorPenetracao,
    this.dorDuranteOuDepoisRelacao,
    this.intensidadeDor0a10,
    this.ressecamento,
  });

  final bool? vidaSexualAtiva;
  final bool? precisaLubrificante;
  final bool? dificuldadeOrgasmo;
  final String? descricaoDificuldadeOrgasmo;
  final DesejoSexual? desejoSexual;
  final String? frequenciaAtividadeSexual;
  final bool? dorNaPenetracao;
  final TipoDorPenetracao? tipoDorPenetracao;
  final bool? dorDuranteOuDepoisRelacao;
  final int? intensidadeDor0a10;
  final bool? ressecamento;

  FuncaoSexual copyWith({
    Object? vidaSexualAtiva = kUnset,
    Object? precisaLubrificante = kUnset,
    Object? dificuldadeOrgasmo = kUnset,
    String? descricaoDificuldadeOrgasmo,
    DesejoSexual? desejoSexual,
    String? frequenciaAtividadeSexual,
    Object? dorNaPenetracao = kUnset,
    TipoDorPenetracao? tipoDorPenetracao,
    Object? dorDuranteOuDepoisRelacao = kUnset,
    int? intensidadeDor0a10,
    Object? ressecamento = kUnset,
  }) {
    return FuncaoSexual(
      vidaSexualAtiva: unsetOr(vidaSexualAtiva, this.vidaSexualAtiva),
      precisaLubrificante: unsetOr(
        precisaLubrificante,
        this.precisaLubrificante,
      ),
      dificuldadeOrgasmo: unsetOr(dificuldadeOrgasmo, this.dificuldadeOrgasmo),
      descricaoDificuldadeOrgasmo:
          descricaoDificuldadeOrgasmo ?? this.descricaoDificuldadeOrgasmo,
      desejoSexual: desejoSexual ?? this.desejoSexual,
      frequenciaAtividadeSexual:
          frequenciaAtividadeSexual ?? this.frequenciaAtividadeSexual,
      dorNaPenetracao: unsetOr(dorNaPenetracao, this.dorNaPenetracao),
      tipoDorPenetracao: tipoDorPenetracao ?? this.tipoDorPenetracao,
      dorDuranteOuDepoisRelacao: unsetOr(
        dorDuranteOuDepoisRelacao,
        this.dorDuranteOuDepoisRelacao,
      ),
      intensidadeDor0a10: intensidadeDor0a10 ?? this.intensidadeDor0a10,
      ressecamento: unsetOr(ressecamento, this.ressecamento),
    );
  }

  Map<String, dynamic> toJson() => {
    'vidaSexualAtiva': vidaSexualAtiva,
    'precisaLubrificante': precisaLubrificante,
    'dificuldadeOrgasmo': dificuldadeOrgasmo,
    'descricaoDificuldadeOrgasmo': descricaoDificuldadeOrgasmo,
    'desejoSexual': desejoSexual?.name,
    'frequenciaAtividadeSexual': frequenciaAtividadeSexual,
    'dorNaPenetracao': dorNaPenetracao,
    'tipoDorPenetracao': tipoDorPenetracao?.name,
    'dorDuranteOuDepoisRelacao': dorDuranteOuDepoisRelacao,
    'intensidadeDor0a10': intensidadeDor0a10,
    'ressecamento': ressecamento,
  };

  factory FuncaoSexual.fromJson(Map<String, dynamic> json) => FuncaoSexual(
    vidaSexualAtiva: json['vidaSexualAtiva'] as bool?,
    precisaLubrificante: json['precisaLubrificante'] as bool?,
    dificuldadeOrgasmo: json['dificuldadeOrgasmo'] as bool?,
    descricaoDificuldadeOrgasmo: json['descricaoDificuldadeOrgasmo'] as String?,
    desejoSexual: enumFromName(DesejoSexual.values, json['desejoSexual']),
    frequenciaAtividadeSexual: json['frequenciaAtividadeSexual'] as String?,
    dorNaPenetracao: json['dorNaPenetracao'] as bool?,
    tipoDorPenetracao: enumFromName(
      TipoDorPenetracao.values,
      json['tipoDorPenetracao'],
    ),
    dorDuranteOuDepoisRelacao: json['dorDuranteOuDepoisRelacao'] as bool?,
    intensidadeDor0a10: json['intensidadeDor0a10'] as int?,
    ressecamento: json['ressecamento'] as bool?,
  );

  @override
  List<Object?> get props => [
    vidaSexualAtiva,
    precisaLubrificante,
    dificuldadeOrgasmo,
    descricaoDificuldadeOrgasmo,
    desejoSexual,
    frequenciaAtividadeSexual,
    dorNaPenetracao,
    tipoDorPenetracao,
    dorDuranteOuDepoisRelacao,
    intensidadeDor0a10,
    ressecamento,
  ];
}

class FuncaoIntestinal extends Equatable {
  const FuncaoIntestinal({
    this.frequenciaEvacuatoria,
    this.frequenciaPersonalizadaValor,
    this.usaLaxante,
    this.descricaoLaxante,
    this.forcaParaEvacuar,
    this.dorParaEvacuar,
    this.esvaziamentoIncompleto,
    this.perdeGases,
    this.perdeFezes,
    this.escalaBristol,
    this.sensacaoObstrucao,
    this.urgenciaFecal,
    this.presencaHemorroidas,
  });

  final FrequenciaEvacuatoria? frequenciaEvacuatoria;
  final int? frequenciaPersonalizadaValor;
  final bool? usaLaxante;
  final String? descricaoLaxante;
  final bool? forcaParaEvacuar;
  final bool? dorParaEvacuar;
  final bool? esvaziamentoIncompleto;
  final bool? perdeGases;
  final bool? perdeFezes;
  final EscalaBristol? escalaBristol;
  final bool? sensacaoObstrucao;
  final bool? urgenciaFecal;
  final bool? presencaHemorroidas;

  FuncaoIntestinal copyWith({
    FrequenciaEvacuatoria? frequenciaEvacuatoria,
    int? frequenciaPersonalizadaValor,
    Object? usaLaxante = kUnset,
    String? descricaoLaxante,
    Object? forcaParaEvacuar = kUnset,
    Object? dorParaEvacuar = kUnset,
    Object? esvaziamentoIncompleto = kUnset,
    Object? perdeGases = kUnset,
    Object? perdeFezes = kUnset,
    EscalaBristol? escalaBristol,
    Object? sensacaoObstrucao = kUnset,
    Object? urgenciaFecal = kUnset,
    Object? presencaHemorroidas = kUnset,
  }) {
    return FuncaoIntestinal(
      frequenciaEvacuatoria:
          frequenciaEvacuatoria ?? this.frequenciaEvacuatoria,
      frequenciaPersonalizadaValor:
          frequenciaPersonalizadaValor ?? this.frequenciaPersonalizadaValor,
      usaLaxante: unsetOr(usaLaxante, this.usaLaxante),
      descricaoLaxante: descricaoLaxante ?? this.descricaoLaxante,
      forcaParaEvacuar: unsetOr(forcaParaEvacuar, this.forcaParaEvacuar),
      dorParaEvacuar: unsetOr(dorParaEvacuar, this.dorParaEvacuar),
      esvaziamentoIncompleto: unsetOr(
        esvaziamentoIncompleto,
        this.esvaziamentoIncompleto,
      ),
      perdeGases: unsetOr(perdeGases, this.perdeGases),
      perdeFezes: unsetOr(perdeFezes, this.perdeFezes),
      escalaBristol: escalaBristol ?? this.escalaBristol,
      sensacaoObstrucao: unsetOr(sensacaoObstrucao, this.sensacaoObstrucao),
      urgenciaFecal: unsetOr(urgenciaFecal, this.urgenciaFecal),
      presencaHemorroidas: unsetOr(
        presencaHemorroidas,
        this.presencaHemorroidas,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'frequenciaEvacuatoria': frequenciaEvacuatoria?.name,
    'frequenciaPersonalizadaValor': frequenciaPersonalizadaValor,
    'usaLaxante': usaLaxante,
    'descricaoLaxante': descricaoLaxante,
    'forcaParaEvacuar': forcaParaEvacuar,
    'dorParaEvacuar': dorParaEvacuar,
    'esvaziamentoIncompleto': esvaziamentoIncompleto,
    'perdeGases': perdeGases,
    'perdeFezes': perdeFezes,
    'escalaBristol': escalaBristol?.name,
    'sensacaoObstrucao': sensacaoObstrucao,
    'urgenciaFecal': urgenciaFecal,
    'presencaHemorroidas': presencaHemorroidas,
  };

  factory FuncaoIntestinal.fromJson(
    Map<String, dynamic> json,
  ) => FuncaoIntestinal(
    frequenciaEvacuatoria: enumFromName(
      FrequenciaEvacuatoria.values,
      json['frequenciaEvacuatoria'],
    ),
    frequenciaPersonalizadaValor: json['frequenciaPersonalizadaValor'] as int?,
    usaLaxante: json['usaLaxante'] as bool?,
    descricaoLaxante: json['descricaoLaxante'] as String?,
    forcaParaEvacuar: json['forcaParaEvacuar'] as bool?,
    dorParaEvacuar: json['dorParaEvacuar'] as bool?,
    esvaziamentoIncompleto: json['esvaziamentoIncompleto'] as bool?,
    perdeGases: json['perdeGases'] as bool?,
    perdeFezes: json['perdeFezes'] as bool?,
    escalaBristol: enumFromName(EscalaBristol.values, json['escalaBristol']),
    sensacaoObstrucao: json['sensacaoObstrucao'] as bool?,
    urgenciaFecal: json['urgenciaFecal'] as bool?,
    presencaHemorroidas: json['presencaHemorroidas'] as bool?,
  );

  @override
  List<Object?> get props => [
    frequenciaEvacuatoria,
    frequenciaPersonalizadaValor,
    usaLaxante,
    descricaoLaxante,
    forcaParaEvacuar,
    dorParaEvacuar,
    esvaziamentoIncompleto,
    perdeGases,
    perdeFezes,
    escalaBristol,
    sensacaoObstrucao,
    urgenciaFecal,
    presencaHemorroidas,
  ];
}

class PlanoTratamento extends Equatable {
  const PlanoTratamento({
    this.diagnosticoFisioterapeutico,
    this.objetivoTratamento,
    this.condutaTratamento,
    this.frequenciaSugerida,
  });

  final String? diagnosticoFisioterapeutico;
  final String? objetivoTratamento;
  final String? condutaTratamento;
  final String? frequenciaSugerida;

  PlanoTratamento copyWith({
    String? diagnosticoFisioterapeutico,
    String? objetivoTratamento,
    String? condutaTratamento,
    String? frequenciaSugerida,
  }) {
    return PlanoTratamento(
      diagnosticoFisioterapeutico:
          diagnosticoFisioterapeutico ?? this.diagnosticoFisioterapeutico,
      objetivoTratamento: objetivoTratamento ?? this.objetivoTratamento,
      condutaTratamento: condutaTratamento ?? this.condutaTratamento,
      frequenciaSugerida: frequenciaSugerida ?? this.frequenciaSugerida,
    );
  }

  Map<String, dynamic> toJson() => {
    'diagnosticoFisioterapeutico': diagnosticoFisioterapeutico,
    'objetivoTratamento': objetivoTratamento,
    'condutaTratamento': condutaTratamento,
    'frequenciaSugerida': frequenciaSugerida,
  };

  factory PlanoTratamento.fromJson(Map<String, dynamic> json) =>
      PlanoTratamento(
        diagnosticoFisioterapeutico:
            json['diagnosticoFisioterapeutico'] as String?,
        objetivoTratamento: json['objetivoTratamento'] as String?,
        condutaTratamento: json['condutaTratamento'] as String?,
        frequenciaSugerida: json['frequenciaSugerida'] as String?,
      );

  @override
  List<Object?> get props => [
    diagnosticoFisioterapeutico,
    objetivoTratamento,
    condutaTratamento,
    frequenciaSugerida,
  ];
}

class Encerramento extends Equatable {
  const Encerramento({
    required this.data,
    required this.motivo,
    this.observacaoFinal,
  });

  final DateTime data;
  final MotivoEncerramento motivo;
  final String? observacaoFinal;

  Map<String, dynamic> toJson() => {
    'data': data.toIso8601String(),
    'motivo': motivo.name,
    'observacaoFinal': observacaoFinal,
  };

  factory Encerramento.fromJson(Map<String, dynamic> json) => Encerramento(
    data: DateTime.parse(json['data'] as String),
    motivo:
        enumFromName(MotivoEncerramento.values, json['motivo']) ??
        MotivoEncerramento.outro,
    observacaoFinal: json['observacaoFinal'] as String?,
  );

  @override
  List<Object?> get props => [data, motivo, observacaoFinal];
}

class Patient extends Equatable {
  const Patient({
    required this.id,
    required this.createdAt,
    this.dadosPessoais = const DadosPessoais(),
    this.anamnese = const Anamnese(),
    this.historicoGinecologico = const HistoricoGinecologico(),
    this.historicoObstetrico = const HistoricoObstetrico(),
    this.historicoCirurgico = const HistoricoCirurgico(),
    this.funcaoUrinaria = const FuncaoUrinaria(),
    this.funcaoSexual = const FuncaoSexual(),
    this.funcaoIntestinal = const FuncaoIntestinal(),
    this.planoTratamento = const PlanoTratamento(),
    this.encerramento,
    this.valorConsulta,
  });

  final String id;
  final DateTime createdAt;
  final DadosPessoais dadosPessoais;
  final Anamnese anamnese;
  final HistoricoGinecologico historicoGinecologico;
  final HistoricoObstetrico historicoObstetrico;
  final HistoricoCirurgico historicoCirurgico;
  final FuncaoUrinaria funcaoUrinaria;
  final FuncaoSexual funcaoSexual;
  final FuncaoIntestinal funcaoIntestinal;
  final PlanoTratamento planoTratamento;
  final Encerramento? encerramento;
  final double? valorConsulta;

  Patient copyWith({
    DadosPessoais? dadosPessoais,
    Anamnese? anamnese,
    HistoricoGinecologico? historicoGinecologico,
    HistoricoObstetrico? historicoObstetrico,
    HistoricoCirurgico? historicoCirurgico,
    FuncaoUrinaria? funcaoUrinaria,
    FuncaoSexual? funcaoSexual,
    FuncaoIntestinal? funcaoIntestinal,
    PlanoTratamento? planoTratamento,
    Object? encerramento = kUnset,
    double? valorConsulta,
  }) {
    return Patient(
      id: id,
      createdAt: createdAt,
      dadosPessoais: dadosPessoais ?? this.dadosPessoais,
      anamnese: anamnese ?? this.anamnese,
      historicoGinecologico:
          historicoGinecologico ?? this.historicoGinecologico,
      historicoObstetrico: historicoObstetrico ?? this.historicoObstetrico,
      historicoCirurgico: historicoCirurgico ?? this.historicoCirurgico,
      funcaoUrinaria: funcaoUrinaria ?? this.funcaoUrinaria,
      funcaoSexual: funcaoSexual ?? this.funcaoSexual,
      funcaoIntestinal: funcaoIntestinal ?? this.funcaoIntestinal,
      planoTratamento: planoTratamento ?? this.planoTratamento,
      encerramento: unsetOr(encerramento, this.encerramento),
      valorConsulta: valorConsulta ?? this.valorConsulta,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt.toIso8601String(),
    'nome': dadosPessoais.nome,
    'idade': dadosPessoais.idade,
    'telefone': dadosPessoais.telefone,
    'profissao': dadosPessoais.profissao,
    'sexo': dadosPessoais.sexo?.name,
    'anamnese': anamnese.toJson(),
    'historico_ginecologico': historicoGinecologico.toJson(),
    'historico_obstetrico': historicoObstetrico.toJson(),
    'historico_cirurgico': historicoCirurgico.toJson(),
    'funcao_urinaria': funcaoUrinaria.toJson(),
    'funcao_sexual': funcaoSexual.toJson(),
    'funcao_intestinal': funcaoIntestinal.toJson(),
    'plano_tratamento': planoTratamento.toJson(),
    'encerramento': encerramento?.toJson(),
    'valor_consulta': valorConsulta,
  };

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
    id: json['id'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    dadosPessoais: DadosPessoais(
      nome: json['nome'] as String? ?? '',
      idade: json['idade'] as int?,
      telefone: json['telefone'] as String? ?? '',
      profissao: json['profissao'] as String? ?? '',
      sexo: enumFromName(Sexo.values, json['sexo']),
    ),
    anamnese: Anamnese.fromJson(
      (json['anamnese'] as Map<String, dynamic>?) ?? {},
    ),
    historicoGinecologico: HistoricoGinecologico.fromJson(
      (json['historico_ginecologico'] as Map<String, dynamic>?) ?? {},
    ),
    historicoObstetrico: HistoricoObstetrico.fromJson(
      (json['historico_obstetrico'] as Map<String, dynamic>?) ?? {},
    ),
    historicoCirurgico: HistoricoCirurgico.fromJson(
      (json['historico_cirurgico'] as Map<String, dynamic>?) ?? {},
    ),
    funcaoUrinaria: FuncaoUrinaria.fromJson(
      (json['funcao_urinaria'] as Map<String, dynamic>?) ?? {},
    ),
    funcaoSexual: FuncaoSexual.fromJson(
      (json['funcao_sexual'] as Map<String, dynamic>?) ?? {},
    ),
    funcaoIntestinal: FuncaoIntestinal.fromJson(
      (json['funcao_intestinal'] as Map<String, dynamic>?) ?? {},
    ),
    planoTratamento: PlanoTratamento.fromJson(
      (json['plano_tratamento'] as Map<String, dynamic>?) ?? {},
    ),
    encerramento: json['encerramento'] == null
        ? null
        : Encerramento.fromJson(json['encerramento'] as Map<String, dynamic>),
    valorConsulta: (json['valor_consulta'] as num?)?.toDouble(),
  );

  @override
  List<Object?> get props => [
    id,
    createdAt,
    dadosPessoais,
    anamnese,
    historicoGinecologico,
    historicoObstetrico,
    historicoCirurgico,
    funcaoUrinaria,
    funcaoSexual,
    funcaoIntestinal,
    planoTratamento,
    encerramento,
    valorConsulta,
  ];
}
