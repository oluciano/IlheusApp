import 'package:sqflite/sqflite.dart';

import 'package:ilheus_app/features/agua/data/datasources/abertura_mes_datasource.dart';
import 'package:ilheus_app/features/agua/data/repositories/abertura_mes_repository_impl.dart';
import 'package:ilheus_app/features/agua/domain/repositories/abertura_mes_repository.dart';

class RepositoryLocator {
  RepositoryLocator._();

  static AberturaMesRepository? _aberturaMes;

  static Future<void> init(Database db) async {
    final dataSource = AberturaMesDataSource(db);
    await dataSource.createTables();
    _aberturaMes = AberturaMesRepositoryImpl(dataSource);
  }

  static AberturaMesRepository? get aberturaMes => _aberturaMes;
}
