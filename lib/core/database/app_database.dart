import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'package:ilheus_app/core/constants/app_constants.dart';
import 'package:ilheus_app/features/agua/data/datasources/abertura_mes_datasource.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase _instance = AppDatabase._();

  static Database? _database;

  factory AppDatabase() => _instance;

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    final db = await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    // Criar tabelas do módulo água
    final dataSource = AberturaMesDataSource(db);
    await dataSource.createTables();

    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabelas criadas pelo dataSource do módulo água
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migrations serão gerenciadas por módulo
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
