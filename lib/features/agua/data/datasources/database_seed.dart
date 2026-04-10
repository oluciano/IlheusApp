import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Seed inicial: 22 casas residenciais + 1 quiiosque (numero 23).
///
/// Regras de seed:
/// - Casa 08 → isento = true (leiturista), ehAdministrador = false
/// - Casa 02 → isento = false, ehAdministrador = true
/// - Demais → isento = false, ehAdministrador = false
class DatabaseSeed {
  static const _uuid = Uuid();

  /// Verifica se o seed já foi aplicado e aplica se necessário.
  static Future<void> seedIfEmpty(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM casas'),
    );
    if (count != null && count > 0) return; // já possui dados

    await seedCasas(db);
  }

  static Future<void> seedCasas(Database db) async {
    final batch = db.batch();

    // Casas 1-22
    for (var i = 1; i <= 22; i++) {
      final isento = i == 8; // leiturista
      final ehAdministrador = i == 2;

      batch.insert('casas', {
        'id': _uuid.v4(),
        'numero': i,
        'ativa': 1,
        'isento': isento ? 1 : 0,
        'eh_administrador': ehAdministrador ? 1 : 0,
      });
    }

    // Quiosque (numero 23)
    batch.insert('casas', {
      'id': _uuid.v4(),
      'numero': 23,
      'ativa': 1,
      'isento': 0,
      'eh_administrador': 0,
    });

    await batch.commit(noResult: true);
  }
}
