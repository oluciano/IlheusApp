import 'package:flutter_test/flutter_test.dart';

import 'package:ilheus_app/features/agua/domain/models/evento_uso_quiosque.dart';

void main() {
  group('EventoUsoQuiosque', () {
    group('Denominador dinâmico', () {
      test('mês sem uso → lista vazia → denominador = 22', () {
        final evento = EventoUsoQuiosque(
          id: 'evt-1',
          mesAno: '04/2026',
          casaIds: [],
        );

        expect(evento.qtdCasasQueUsaram, 0);
        expect(evento.casaIds, isEmpty);
      });

      test('mês com uso → denominador = 23', () {
        final evento = EventoUsoQuiosque(
          id: 'evt-2',
          mesAno: '04/2026',
          casaIds: ['casa-1', 'casa-5', 'casa-12'],
        );

        expect(evento.qtdCasasQueUsaram, 3);
        expect(evento.casaIds.length, 3);
      });

      test('uma única casa usou o quiosque', () {
        final evento = EventoUsoQuiosque(
          id: 'evt-3',
          mesAno: '05/2026',
          casaIds: ['casa-7'],
        );

        expect(evento.qtdCasasQueUsaram, 1);
      });
    });

    group('Serialização JSON', () {
      test('toMap serializa casaIds como JSON array', () {
        final evento = EventoUsoQuiosque(
          id: 'evt-4',
          mesAno: '04/2026',
          casaIds: ['casa-1', 'casa-3'],
        );

        final map = evento.toMap();
        expect(map['mes_ano'], '04/2026');
        expect(map['casa_ids'], isA<String>());
        // Deve ser JSON válido
        expect(map['casa_ids'], contains('['));
      });

      test('fromMap desserializa JSON array', () {
        final evento = EventoUsoQuiosque(
          id: 'evt-5',
          mesAno: '04/2026',
          casaIds: ['casa-1', 'casa-3', 'casa-15'],
        );

        final map = evento.toMap();
        final restaurada = EventoUsoQuiosque.fromMap(map);

        expect(restaurada.casaIds, unorderedEquals(evento.casaIds));
        expect(restaurada.qtdCasasQueUsaram, evento.qtdCasasQueUsaram);
      });

      test('fromMap com lista vazia', () {
        final evento = EventoUsoQuiosque(
          id: 'evt-6',
          mesAno: '04/2026',
          casaIds: [],
        );

        final map = evento.toMap();
        final restaurada = EventoUsoQuiosque.fromMap(map);

        expect(restaurada.casaIds, isEmpty);
        expect(restaurada.qtdCasasQueUsaram, 0);
      });

      test('fromMap com campo nulo retorna lista vazia', () {
        final map = <String, dynamic>{
          'id': 'evt-7',
          'mes_ano': '04/2026',
          'casa_ids': null,
        };

        final evento = EventoUsoQuiosque.fromMap(map);
        expect(evento.casaIds, isEmpty);
      });
    });

    group('copyWith', () {
      test('adiciona casa à lista', () {
        final evento = EventoUsoQuiosque(
          id: 'evt-8',
          mesAno: '04/2026',
          casaIds: ['casa-1'],
        );

        final copia = evento.copyWith(
          casaIds: ['casa-1', 'casa-5'],
        );

        expect(copia.qtdCasasQueUsaram, 2);
      });
    });
  });
}
