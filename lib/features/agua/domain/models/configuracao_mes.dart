import 'package:ilheus_app/features/agua/domain/models/modelo_juros.dart';
import 'package:ilheus_app/features/agua/domain/models/valor_monetario.dart';

class ConfiguracaoMes {
  final String? id;
  final String mesAno;
  final ValorMonetario valorCond;
  final ModeloJuros modeloJuros;
  final bool componenteAguaAtivo;
  final bool componenteEsgotoAtivo;
  final bool componenteServicoBasicoAtivo;
  final bool componenteLuzAtivo;
  final bool componenteCondAtivo;

  const ConfiguracaoMes({
    this.id,
    required this.mesAno,
    this.valorCond = const ValorMonetario.zero(),
    this.modeloJuros = ModeloJuros.igualitario,
    this.componenteAguaAtivo = true,
    this.componenteEsgotoAtivo = true,
    this.componenteServicoBasicoAtivo = true,
    this.componenteLuzAtivo = true,
    this.componenteCondAtivo = true,
  });

  ConfiguracaoMes copyWith({
    String? id,
    String? mesAno,
    ValorMonetario? valorCond,
    ModeloJuros? modeloJuros,
    bool? componenteAguaAtivo,
    bool? componenteEsgotoAtivo,
    bool? componenteServicoBasicoAtivo,
    bool? componenteLuzAtivo,
    bool? componenteCondAtivo,
  }) {
    return ConfiguracaoMes(
      id: id ?? this.id,
      mesAno: mesAno ?? this.mesAno,
      valorCond: valorCond ?? this.valorCond,
      modeloJuros: modeloJuros ?? this.modeloJuros,
      componenteAguaAtivo: componenteAguaAtivo ?? this.componenteAguaAtivo,
      componenteEsgotoAtivo: componenteEsgotoAtivo ?? this.componenteEsgotoAtivo,
      componenteServicoBasicoAtivo: componenteServicoBasicoAtivo ?? this.componenteServicoBasicoAtivo,
      componenteLuzAtivo: componenteLuzAtivo ?? this.componenteLuzAtivo,
      componenteCondAtivo: componenteCondAtivo ?? this.componenteCondAtivo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'mes_ano': mesAno,
      'valor_cond_centavos': valorCond.centavos,
      'modelo_juros': modeloJuros.name,
      'componente_agua_ativo': componenteAguaAtivo ? 1 : 0,
      'componente_esgoto_ativo': componenteEsgotoAtivo ? 1 : 0,
      'componente_servico_basico_ativo': componenteServicoBasicoAtivo ? 1 : 0,
      'componente_luz_ativo': componenteLuzAtivo ? 1 : 0,
      'componente_cond_ativo': componenteCondAtivo ? 1 : 0,
    };
  }

  factory ConfiguracaoMes.fromMap(Map<String, dynamic> map) {
    return ConfiguracaoMes(
      id: map['id'] as String?,
      mesAno: map['mes_ano'] as String,
      valorCond: ValorMonetario.fromCentavos(map['valor_cond_centavos'] as int),
      modeloJuros: ModeloJuros.values.firstWhere(
        (e) => e.name == map['modelo_juros'],
        orElse: () => ModeloJuros.igualitario,
      ),
      componenteAguaAtivo: (map['componente_agua_ativo'] as int) == 1,
      componenteEsgotoAtivo: (map['componente_esgoto_ativo'] as int) == 1,
      componenteServicoBasicoAtivo:
          (map['componente_servico_basico_ativo'] as int) == 1,
      componenteLuzAtivo: (map['componente_luz_ativo'] as int) == 1,
      componenteCondAtivo: (map['componente_cond_ativo'] as int) == 1,
    );
  }
}
