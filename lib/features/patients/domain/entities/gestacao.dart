import 'package:equatable/equatable.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/shared/utils/enum_from_name.dart';
import 'package:fisioterapia_pelvica/shared/utils/unset.dart';

class Gestacao extends Equatable {
  const Gestacao({
    this.perdaGestacional,
    this.descricaoPerda,
    this.viaDeParto,
    this.complicacaoParto,
    this.teveComplicacoes,
    this.descricaoComplicacao,
    this.pesoAproximadoBebe,
    this.usoForcepsOuVacuo,
  });

  final bool? perdaGestacional;
  final String? descricaoPerda;
  final ViaDeParto? viaDeParto;
  final ComplicacaoParto? complicacaoParto;
  final bool? teveComplicacoes;
  final String? descricaoComplicacao;
  final String? pesoAproximadoBebe;
  final bool? usoForcepsOuVacuo;

  Gestacao copyWith({
    Object? perdaGestacional = kUnset,
    String? descricaoPerda,
    ViaDeParto? viaDeParto,
    ComplicacaoParto? complicacaoParto,
    Object? teveComplicacoes = kUnset,
    String? descricaoComplicacao,
    String? pesoAproximadoBebe,
    Object? usoForcepsOuVacuo = kUnset,
  }) {
    return Gestacao(
      perdaGestacional: unsetOr(perdaGestacional, this.perdaGestacional),
      descricaoPerda: descricaoPerda ?? this.descricaoPerda,
      viaDeParto: viaDeParto ?? this.viaDeParto,
      complicacaoParto: complicacaoParto ?? this.complicacaoParto,
      teveComplicacoes: unsetOr(teveComplicacoes, this.teveComplicacoes),
      descricaoComplicacao: descricaoComplicacao ?? this.descricaoComplicacao,
      pesoAproximadoBebe: pesoAproximadoBebe ?? this.pesoAproximadoBebe,
      usoForcepsOuVacuo: unsetOr(usoForcepsOuVacuo, this.usoForcepsOuVacuo),
    );
  }

  Map<String, dynamic> toJson() => {
    'perdaGestacional': perdaGestacional,
    'descricaoPerda': descricaoPerda,
    'viaDeParto': viaDeParto?.name,
    'complicacaoParto': complicacaoParto?.name,
    'teveComplicacoes': teveComplicacoes,
    'descricaoComplicacao': descricaoComplicacao,
    'pesoAproximadoBebe': pesoAproximadoBebe,
    'usoForcepsOuVacuo': usoForcepsOuVacuo,
  };

  factory Gestacao.fromJson(Map<String, dynamic> json) => Gestacao(
    perdaGestacional: json['perdaGestacional'] as bool?,
    descricaoPerda: json['descricaoPerda'] as String?,
    viaDeParto: enumFromName(ViaDeParto.values, json['viaDeParto']),
    complicacaoParto: enumFromName(
      ComplicacaoParto.values,
      json['complicacaoParto'],
    ),
    teveComplicacoes: json['teveComplicacoes'] as bool?,
    descricaoComplicacao: json['descricaoComplicacao'] as String?,
    pesoAproximadoBebe: json['pesoAproximadoBebe'] as String?,
    usoForcepsOuVacuo: json['usoForcepsOuVacuo'] as bool?,
  );

  @override
  List<Object?> get props => [
    perdaGestacional,
    descricaoPerda,
    viaDeParto,
    complicacaoParto,
    teveComplicacoes,
    descricaoComplicacao,
    pesoAproximadoBebe,
    usoForcepsOuVacuo,
  ];
}
