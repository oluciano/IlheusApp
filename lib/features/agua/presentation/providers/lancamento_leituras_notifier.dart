import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ilheus_app/features/agua/domain/models/leitura.dart';
import 'package:ilheus_app/features/agua/domain/models/casa.dart';
import 'package:ilheus_app/features/agua/domain/repositories/casa_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/leitura_repository.dart';
import 'package:ilheus_app/features/agua/presentation/providers/lancamento_leituras_state.dart';
import 'package:ilheus_app/features/agua/presentation/providers/database_providers.dart';
import 'package:ilheus_app/features/agua/presentation/providers/home_providers.dart';
import 'package:uuid/uuid.dart';

/// Provider principal da tela de lançamento de leituras.
final lancamentoLeiturasProvider = StateNotifierProvider.family<
    LancamentoLeiturasNotifier, LancamentoLeiturasState, String>((ref, mesAno) {
  final casaRepo = ref.watch(casaRepositoryProvider);
  final leituraRepo = ref.watch(leituraRepositoryProvider);

  if (casaRepo == null || leituraRepo == null) {
    return LancamentoLeiturasNotifier(
      ref: ref,
      casaRepository: null,
      leituraRepository: null,
      mesAno: mesAno,
    );
  }

  return LancamentoLeiturasNotifier(
    ref: ref,
    casaRepository: casaRepo,
    leituraRepository: leituraRepo,
    mesAno: mesAno,
  );
});

class LancamentoLeiturasNotifier
    extends StateNotifier<LancamentoLeiturasState> {
  final CasaRepository? _casaRepository;
  final LeituraRepository? _leituraRepository;
  final String mesAno;
  final StateNotifierProviderRef ref;
  final _uuid = const Uuid();

  LancamentoLeiturasNotifier({
    required this.ref,
    CasaRepository? casaRepository,
    LeituraRepository? leituraRepository,
    required this.mesAno,
  })  : _casaRepository = casaRepository,
        _leituraRepository = leituraRepository,
        super(LancamentoLeiturasState(mesAno: mesAno));

  /// Calcula o mes_ano do mês anterior.
  String? _getMesAnoAnterior() {
    final parts = mesAno.split('/');
    if (parts.length != 2) return null;

    final mes = int.tryParse(parts[0]);
    final ano = int.tryParse(parts[1]);
    if (mes == null || ano == null) return null;

    int mesAnterior = mes - 1;
    int anoAnterior = ano;
    if (mesAnterior < 1) {
      mesAnterior = 12;
      anoAnterior--;
    }

    return '${mesAnterior.toString().padLeft(2, '0')}/$anoAnterior';
  }

  /// Carrega casas, leituras do mês atual e do mês anterior.
  Future<void> carregarDados() async {
    if (_casaRepository == null || _leituraRepository == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Persistência desabilitada no web (sqflite não suportado).',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Carrega casas ativas
      final casas = await _casaRepository.buscarAtivas();
      // Filtra quiiosque (numero 23) — só 22 residenciais
      final casasResidenciais = casas.where((c) => !c.isQuiosque).toList();

      // Leituras do mês atual
      final leiturasAtuais =
          await _leituraRepository.buscarLeiturasPorMes(mesAno);

      // Ordenação por relevância (Pendentes no topo, seguidas por ordem numérica)
      final casasOrdenadas = List<Casa>.from(casasResidenciais)..sort((a, b) {
        final temLeituraA = leiturasAtuais.any((l) => l.casaId == a.id);
        final temLeituraB = leiturasAtuais.any((l) => l.casaId == b.id);
        
        if (temLeituraA != temLeituraB) {
          return temLeituraA ? 1 : -1; // Sem leitura (false) vem antes
        }
        return a.numero.compareTo(b.numero);
      });

      // Leituras do mês anterior (para exibir "anterior")
      // Se não existir no mês imediatamente anterior, buscamos a última de qualquer mês
      final mesAnterior = _getMesAnoAnterior();
      final List<Leitura> leiturasAnterioresFinal = [];
      
      for (final casa in casasResidenciais) {
        // Tenta primeiro o mês imediatamente anterior
        Leitura? anterior;
        if (mesAnterior != null) {
          anterior = await _leituraRepository.buscarLeituraCasa(casa.id, mesAnterior);
        }
        
        // Se não achou, busca a leitura mais recente de qualquer mês
        // Mas atenção: se já tivermos leitura para o mês ATUAL, buscarUltimaLeitura
        // vai retornar ela mesma. Precisamos da última leitura *antes* desta.
        if (anterior == null) {
          final ultima = await _leituraRepository.buscarUltimaLeitura(casa.id);
          if (ultima != null) {
            // Se a última for deste mês, ela não serve como "anterior"
            if (ultima.mesAno == mesAno) {
              // TODO: Se precisarmos mesmo da anterior à atual quando já existe atual,
              // precisaríamos de um buscarUltimaLeituraAntesDe(mesAno).
              // Mas para o caso de "lançar novo mês", buscarUltimaLeitura já resolve
              // pois ainda não existe leitura para o mês atual.
              
              // Se já existe leitura no mês atual, a 'leituraAnteriorM3' dela 
              // JÁ É a leitura que queremos usar como base.
              final atual = leiturasAtuais.firstWhere((l) => l.casaId == casa.id, orElse: () => ultima);
              // Criamos uma leitura "fake" do mês anterior usando os dados da atual
              anterior = Leitura(
                id: 'fake-prev-${casa.id}',
                mesAno: 'anterior',
                casaId: casa.id,
                leituraAnteriorM3: 0,
                leituraAtualM3: atual.leituraAnteriorM3,
              );
            } else {
              anterior = ultima;
            }
          }
        }
        
        if (anterior != null) {
          leiturasAnterioresFinal.add(anterior);
        }
      }

      state = state.copyWith(
        casas: casasOrdenadas,
        leiturasSalvas: leiturasAtuais,
        leiturasMesAnterior: leiturasAnterioresFinal,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar dados: $e',
      );
    }
  }

  /// Salva (ou atualiza) a leitura de uma casa.
  Future<bool> salvarLeitura({
    required String casaId,
    required int leituraAtual,
  }) async {
    if (_casaRepository == null || _leituraRepository == null) {
      state = state.copyWith(
        errorMessage:
            'Persistência desabilitada no web (sqflite não suportado).',
      );
      return false;
    }

    final leituraAnterior = state.getLeituraAnterior(casaId);

    // Validação: leitura atual >= anterior
    if (leituraAtual < leituraAnterior) {
      state = state.copyWith(
        errorMessage:
            'Leitura atual ($leituraAtual) não pode ser menor '
            'que a anterior ($leituraAnterior).',
      );
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      // Verifica se já existe leitura para esta casa neste mês
      final leituraExistente =
          await _leituraRepository.buscarLeituraCasa(casaId, mesAno);

      final leitura = Leitura(
        id: leituraExistente?.id ?? _uuid.v4(),
        mesAno: mesAno,
        casaId: casaId,
        leituraAnteriorM3: leituraAnterior,
        leituraAtualM3: leituraAtual,
      );

      await _leituraRepository.salvarLeitura(leitura);

      // Invalida provider da home para atualizar Dashboard
      ref.invalidate(mesesSalvosProvider);

      // Recarrega estado local
      await carregarDados();

      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Erro ao salvar leitura: $e',
      );
      return false;
    }
  }

  /// Limpa mensagem de erro.
  void limparErro() {
    state = state.copyWith(errorMessage: null);
  }
}
