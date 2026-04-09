import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'features/agua/data/repositories/repository_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    final dbInstance = AppDatabase();
    final db = await dbInstance.database;
    await RepositoryLocator.init(db);
  }

  runApp(
    const ProviderScope(
      child: IlheusApp(),
    ),
  );
}
