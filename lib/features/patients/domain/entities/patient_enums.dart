enum Sexo { feminino, masculino }

extension SexoLabel on Sexo {
  String get label => switch (this) {
    Sexo.feminino => 'Feminino',
    Sexo.masculino => 'Masculino',
  };
}

enum MetodoContraceptivo { pilula, injecao, diu, implanon, camisinha, nenhum }

extension MetodoContraceptivoLabel on MetodoContraceptivo {
  String get label => switch (this) {
    MetodoContraceptivo.pilula => 'Pílula',
    MetodoContraceptivo.injecao => 'Injeção',
    MetodoContraceptivo.diu => 'DIU',
    MetodoContraceptivo.implanon => 'Implanon',
    MetodoContraceptivo.camisinha => 'Camisinha',
    MetodoContraceptivo.nenhum => 'Nenhum',
  };
}

enum ViaDeParto { normal, cesarea }

extension ViaDePartoLabel on ViaDeParto {
  String get label => switch (this) {
    ViaDeParto.normal => 'Normal',
    ViaDeParto.cesarea => 'Cesárea',
  };
}

enum MotivoEncerramento { alta, abandono, encaminhamento, outro }

extension MotivoEncerramentoLabel on MotivoEncerramento {
  String get label => switch (this) {
    MotivoEncerramento.alta => 'Alta',
    MotivoEncerramento.abandono => 'Abandono',
    MotivoEncerramento.encaminhamento => 'Encaminhamento',
    MotivoEncerramento.outro => 'Outro',
  };
}

enum ComplicacaoParto { nenhuma, laceracao, episiotomia }

extension ComplicacaoPartoLabel on ComplicacaoParto {
  String get label => switch (this) {
    ComplicacaoParto.nenhuma => 'Nenhuma',
    ComplicacaoParto.laceracao => 'Laceração',
    ComplicacaoParto.episiotomia => 'Episiotomia',
  };
}

enum CirurgiaGinecologica {
  histerectomia,
  laqueadura,
  perineoplastia,
  sling,
  outro,
  nenhum,
}

extension CirurgiaGinecologicaLabel on CirurgiaGinecologica {
  String get label => switch (this) {
    CirurgiaGinecologica.histerectomia => 'Histerectomia',
    CirurgiaGinecologica.laqueadura => 'Laqueadura',
    CirurgiaGinecologica.perineoplastia => 'Perineoplastia',
    CirurgiaGinecologica.sling => 'Sling',
    CirurgiaGinecologica.outro => 'Outro',
    CirurgiaGinecologica.nenhum => 'Nenhum',
  };
}

enum GatilhoIncontinencia {
  tosse,
  espirro,
  peso,
  agachar,
  caminhando,
  mudandoDePosicao,
  outros,
}

extension GatilhoIncontinenciaLabel on GatilhoIncontinencia {
  String get label => switch (this) {
    GatilhoIncontinencia.tosse => 'Tosse',
    GatilhoIncontinencia.espirro => 'Espirro',
    GatilhoIncontinencia.peso => 'Peso',
    GatilhoIncontinencia.agachar => 'Agachar',
    GatilhoIncontinencia.caminhando => 'Caminhando',
    GatilhoIncontinencia.mudandoDePosicao => 'Mudando de posição',
    GatilhoIncontinencia.outros => 'Outros',
  };
}

enum FrequenciaEvacuatoria {
  umaVezAoDia,
  algumasVezesPorSemana,
  menosDeTresVezesPorSemana,
  personalizado,
}

extension FrequenciaEvacuatoriaLabel on FrequenciaEvacuatoria {
  String get label => switch (this) {
    FrequenciaEvacuatoria.umaVezAoDia => 'Uma vez ao dia',
    FrequenciaEvacuatoria.algumasVezesPorSemana => 'Algumas vezes por semana',
    FrequenciaEvacuatoria.menosDeTresVezesPorSemana =>
      'Menos de três vezes por semana',
    FrequenciaEvacuatoria.personalizado => 'Personalizado',
  };
}

enum FluxoMenstrual { leve, moderado, intenso }

extension FluxoMenstrualLabel on FluxoMenstrual {
  String get label => switch (this) {
    FluxoMenstrual.leve => 'Leve',
    FluxoMenstrual.moderado => 'Moderado',
    FluxoMenstrual.intenso => 'Intenso',
  };
}

enum QuantidadePerda { gotas, pequena, moderada, grande }

extension QuantidadePerdaLabel on QuantidadePerda {
  String get label => switch (this) {
    QuantidadePerda.gotas => 'Gotas',
    QuantidadePerda.pequena => 'Pequena',
    QuantidadePerda.moderada => 'Moderada',
    QuantidadePerda.grande => 'Grande',
  };
}

enum TipoDorPenetracao { superficial, profunda }

extension TipoDorPenetracaoLabel on TipoDorPenetracao {
  String get label => switch (this) {
    TipoDorPenetracao.superficial => 'Superficial',
    TipoDorPenetracao.profunda => 'Profunda',
  };
}

enum DesejoSexual { preservado, reduzido, ausente, aumentado }

extension DesejoSexualLabel on DesejoSexual {
  String get label => switch (this) {
    DesejoSexual.preservado => 'Preservado',
    DesejoSexual.reduzido => 'Reduzido',
    DesejoSexual.ausente => 'Ausente',
    DesejoSexual.aumentado => 'Aumentado',
  };
}

enum EscalaBristol { tipo1, tipo2, tipo3, tipo4, tipo5, tipo6, tipo7 }

extension EscalaBristolLabel on EscalaBristol {
  String get label => switch (this) {
    EscalaBristol.tipo1 => 'Tipo 1',
    EscalaBristol.tipo2 => 'Tipo 2',
    EscalaBristol.tipo3 => 'Tipo 3',
    EscalaBristol.tipo4 => 'Tipo 4',
    EscalaBristol.tipo5 => 'Tipo 5',
    EscalaBristol.tipo6 => 'Tipo 6',
    EscalaBristol.tipo7 => 'Tipo 7',
  };
}
