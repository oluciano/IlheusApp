import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:ilheus_app/features/agua/domain/models/models.dart';
import 'package:ilheus_app/features/agua/domain/repositories/abertura_mes_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/leitura_repository.dart';
import 'package:ilheus_app/features/agua/presentation/providers/abertura_mes_form_state.dart';
import 'package:ilheus_app/features/agua/presentation/providers/database_providers.dart';

final aberturaMesFormProvider =
    StateNotifierProvider<AberturaMesNotifier, AberturaMesFormState>((ref) {
  final repo = ref.watch(aberturaMesRepositoryProvider);
  final leituraRepo = ref.watch(leituraRepositoryProvider);
  final repository = repo ?? _WebNotImplemented();
  return AberturaMesNotifier(repository, leituraRepo);
});

class AberturaMesNotifier extends StateNotifier<AberturaMesFormState> {
  final AberturaMesRepository _repository;
  final LeituraRepository? _leituraRepository;
  AberturaMesFormState? _originalState;
  final _uuid = const Uuid();

  AberturaMesNotifier(this._repository, this._leituraRepository)
      : super(const AberturaMesFormState());

  bool get hasChanges {
    if (_originalState == null) return false;
    return state.contaCorsan != _originalState!.contaCorsan ||
           state.contaLuz != _originalState!.contaLuz ||
           state.configuracaoMes != _originalState!.configuracaoMes ||
           state.despesasExtras.length != _originalState!.despesasExtras.length;
  }

  Future<void> abrirNovoMes(String mesAno) async {
    state = state.mesSelecionado(mesAno);
    await _carregarDadosReferenciaAnterior(mesAno);
    await _verificarLeituraCompleta(mesAno);
    _originalState = state;
  }

  Future<void> abrirMesExistente(String mesAno) async {
    state = state.mesSelecionado(mesAno);
    await _carregarDadosMes(mesAno);
    await _carregarDadosReferenciaAnterior(mesAno);
    await _verificarLeituraCompleta(mesAno);
    _originalState = state;
  }

  Future<void> _carregarDadosReferenciaAnterior(String mesAtual) async {
    final partes = mesAtual.split('/');
    if (partes.length != 2) return;
    
    int mes = int.parse(partes[0]);
    int ano = int.parse(partes[1]);
    
    if (mes == 1) {
      mes = 12;
      ano--;
    } else {
      mes--;
    }
    
    final mesAnterior = '${mes.toString().padLeft(2, '0')}/$ano';
    
    final corsan = await _repository.getContaCorsan(mesAnterior);
    final luz = await _repository.getContaLuz(mesAnterior);
    final config = await _repository.getConfiguracaoMes(mesAnterior);
    
    state = state.copyWith(
      contaCorsanAnterior: corsan,
      contaLuzAnterior: luz,
      configuracaoAnterior: config,
    );
  }

  Future<void> _verificarLeituraCompleta(String mesAno) async {
    if (_leituraRepository == null) return;
    final completa = await _leituraRepository!.verificarLeituraCompleta(mesAno);
    state = state.copyWith(leituraCompleta: completa);
  }

  Future<bool> mesJaCadastrado(String mesAno) async {
    return await _repository.mesSalvo(mesAno);
  }

  void atualizarContaCorsan(ContaCorsan conta) {
    state = state.copyWith(contaCorsan: conta, isSalvo: false);
  }

  void atualizarContaLuz(ContaLuz conta) {
    state = state.copyWith(contaLuz: conta, isSalvo: false);
  }

  void atualizarConfiguracaoMes(ConfiguracaoMes config) {
    state = state.copyWith(configuracaoMes: config, isSalvo: false);
  }

  void adicionarDespesaExtra(DespesaExtra despesa) {
    final novaDespesa = despesa.id == null 
        ? despesa.copyWith(id: _uuid.v4()) 
        : despesa;

    state = state.copyWith(
      despesasExtras: [...state.despesasExtras, novaDespesa],
      isSalvo: false,
    );
  }

  void atualizarDespesaExtra(DespesaExtra despesa) {
    state = state.copyWith(
      despesasExtras: state.despesasExtras
          .map((d) => d.id == despesa.id ? despesa : d)
          .toList(),
      isSalvo: false,
    );
  }

  void removerDespesaExtra(String id) {
    state = state.copyWith(
      despesasExtras: state.despesasExtras.where((d) => d.id != id).toList(),
      isSalvo: false,
    );
  }

  Future<bool> salvar() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.runInTransaction(() async {
        await _repository.saveContaCorsan(state.contaCorsan);
        await _repository.saveContaLuz(state.contaLuz);
        await _repository.saveConfiguracaoMes(state.configuracaoMes);
        for (final despesa in state.despesasExtras) {
          await _repository.saveDespesaExtra(despesa);
        }
      });
      state = state.copyWith(isSalvo: true, isLoading: false);
      _originalState = state;
      return true;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<void> _carregarDadosMes(String mesAno) async {
    state = state.copyWith(isLoading: true);
    try {
      final corsan = await _repository.getContaCorsan(mesAno);
      final luz = await _repository.getContaLuz(mesAno);
      final config = await _repository.getConfiguracaoMes(mesAno);
      final extras = await _repository.getDespesasExtras(mesAno);
      state = state.copyWith(
        contaCorsan: corsan ?? ContaCorsan(mesAno: mesAno),
        contaLuz: luz ?? ContaLuz(mesAno: mesAno),
        configuracaoMes: config ?? ConfiguracaoMes(mesAno: mesAno),
        despesasExtras: extras,
        isSalvo: corsan != null,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void reset() {
    state = const AberturaMesFormState();
    _originalState = null;
  }
}

class _WebNotImplemented implements AberturaMesRepository {
  @override
  Future<ContaCorsan?> getContaCorsan(String mesAno) async => null;
  @override
  Future<void> saveContaCorsan(ContaCorsan conta) async {}
  @override
  Future<ContaLuz?> getContaLuz(String mesAno) async => null;
  @override
  Future<void> saveContaLuz(ContaLuz conta) async {}
  @override
  Future<ConfiguracaoMes?> getConfiguracaoMes(String mesAno) async => null;
  @override
  Future<void> saveConfiguracaoMes(ConfiguracaoMes config) async {}
  @override
  Future<List<DespesaExtra>> getDespesasExtras(String mesAno) async => [];
  @override
  Future<void> saveDespesaExtra(DespesaExtra despesa) async {}
  @override
  Future<void> deleteDespesaExtra(String id) async {}
  @override
  Future<bool> mesSalvo(String mesAno) async => false;
  @override
  Future<List<String>> listarTodosMeses() async => [];
  @override
  Future<T> runInTransaction<T>(Future<T> Function() body) async => await body();
}
