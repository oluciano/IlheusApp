import 'package:sqflite/sqflite.dart';

import 'package:ilheus_app/features/agua/data/datasources/abertura_mes_datasource.dart';
import 'package:ilheus_app/features/agua/data/repositories/abertura_mes_repository_impl.dart';
import 'package:ilheus_app/features/agua/data/repositories/casa_repository_impl.dart';
import 'package:ilheus_app/features/agua/data/repositories/cobranca_repository_impl.dart';
import 'package:ilheus_app/features/agua/data/repositories/debito_repository_impl.dart';
import 'package:ilheus_app/features/agua/data/repositories/evento_uso_quiosque_repository_impl.dart';
import 'package:ilheus_app/features/agua/data/repositories/fatura_calculada_repository_impl.dart';
import 'package:ilheus_app/features/agua/data/repositories/leitura_repository_impl.dart';
import 'package:ilheus_app/features/agua/data/repositories/pagamento_repository_impl.dart';
import 'package:ilheus_app/features/agua/domain/repositories/abertura_mes_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/casa_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/cobranca_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/debito_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/evento_uso_quiosque_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/fatura_calculada_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/leitura_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/pagamento_repository.dart';

class RepositoryLocator {
  RepositoryLocator._();

  static AberturaMesRepository? _aberturaMes;
  static LeituraRepository? _leitura;
  static CobrancaRepository? _cobranca;
  static PagamentoRepository? _pagamento;
  static DebitoRepository? _debito;
  static CasaRepository? _casa;
  static EventoUsoQuiosqueRepository? _eventoUsoQuiosque;
  static FaturaCalculadaRepository? _faturaCalculada;

  static Future<void> init(Database db) async {
    final dataSource = AberturaMesDataSource(db);
    await dataSource.createTables();
    _aberturaMes = AberturaMesRepositoryImpl(dataSource);
    _leitura = LeituraRepositoryImpl(LeituraDataSource(db));
    _cobranca = CobrancaRepositoryImpl(CobrancaDataSource(db));
    _pagamento = PagamentoRepositoryImpl(PagamentoDataSource(db));
    _debito = DebitoRepositoryImpl(DebitoDataSource(db));
    _casa = CasaRepositoryImpl(CasaDataSource(db));
    _eventoUsoQuiosque =
        EventoUsoQuiosqueRepositoryImpl(EventoUsoQuiosqueDataSource(db));
    _faturaCalculada =
        FaturaCalculadaRepositoryImpl(FaturaCalculadaDataSource(db));
  }

  static AberturaMesRepository? get aberturaMes => _aberturaMes;
  static LeituraRepository? get leitura => _leitura;
  static CobrancaRepository? get cobranca => _cobranca;
  static PagamentoRepository? get pagamento => _pagamento;
  static DebitoRepository? get debito => _debito;
  static CasaRepository? get casa => _casa;
  static EventoUsoQuiosqueRepository? get eventoUsoQuiosque =>
      _eventoUsoQuiosque;
  static FaturaCalculadaRepository? get faturaCalculada =>
      _faturaCalculada;
}
