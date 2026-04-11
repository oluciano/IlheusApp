import 'package:ilheus_app/features/agua/domain/models/casa.dart';
import 'package:ilheus_app/features/agua/domain/models/leitura.dart';

/// Estado da tela de lançamento de leituras mensais.
class LancamentoLeiturasState {
  /// Mês/ano sendo editado (ex: "04/2026")
  final String mesAno;

  /// Lista das 22 casas (residenciais)
  final List<Casa> casas;

  /// Leituras já salvas do mês atual
  final List<Leitura> leiturasSalvas;

  /// Leituras do mês anterior (para exibir "anterior")
  final List<Leitura> leiturasMesAnterior;

  /// Loading — carregando dados iniciais
  final bool isLoading;

  /// Loading — salvando leitura individual
  final bool isSaving;

  /// Mensagem de erro (validação, etc.)
  final String? errorMessage;

  const LancamentoLeiturasState({
    required this.mesAno,
    this.casas = const [],
    this.leiturasSalvas = const [],
    this.leiturasMesAnterior = const [],
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
  });

  /// Retorna um mapa: casaId → Leitura (do mês atual)
  Map<String, Leitura> get _mapLeiturasAtuais {
    return {for (final l in leiturasSalvas) l.casaId: l};
  }

  /// Retorna um mapa: casaId → leituraAnteriorM3 (do mês anterior)
  Map<String, int> get _mapLeiturasAnteriores {
    return {for (final l in leiturasMesAnterior) l.casaId: l.leituraAtualM3};
  }

  /// Retorna a leitura anterior de uma casa (0 se não existir)
  int getLeituraAnterior(String casaId) {
    return _mapLeiturasAnteriores[casaId] ?? 0;
  }

  /// Retorna a leitura atual salva de uma casa (null se não tiver)
  Leitura? getLeituraAtual(String casaId) {
    return _mapLeiturasAtuais[casaId];
  }

  /// Quantidade de casas com leitura lançada
  int get casasComLeitura => leiturasSalvas.length;

  /// Total de casas (sempre 22)
  int get totalCasas => casas.length;

  /// Todas as 22 casas têm leitura?
  bool get leituraCompleta => totalCasas > 0 && casasComLeitura >= totalCasas;

  LancamentoLeiturasState copyWith({
    String? mesAno,
    List<Casa>? casas,
    List<Leitura>? leiturasSalvas,
    List<Leitura>? leiturasMesAnterior,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return LancamentoLeiturasState(
      mesAno: mesAno ?? this.mesAno,
      casas: casas ?? this.casas,
      leiturasSalvas: leiturasSalvas ?? this.leiturasSalvas,
      leiturasMesAnterior: leiturasMesAnterior ?? this.leiturasMesAnterior,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }
}
