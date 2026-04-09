import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ilheus_app/app.dart';

void main() {
  testWidgets('App inicializa sem erros', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: IlheusApp(),
      ),
    );

    // Verifica que o app renderiza
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
