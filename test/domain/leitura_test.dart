import 'package:flutter_test/flutter_test.dart';

import 'package:ilheus_app/features/agua/domain/models/leitura.dart';

void main() {
  group('Leitura', () {
    group('Consumo derivado', () {
      test('consumo correto: atual - anterior', () {
        final leitura = Leitura(
          id: 'leit-1',
          mesAno: '04/2026',
          casaId: 'casa-1',
          leituraAnteriorM3: 100,
          leituraAtualM3: 135,
        );

        expect(leitura.consumoM3, 35);
      });

      test('consumo zero quando anterior == atual', () {
        final leitura = Leitura(
          id: 'leit-2',
          mesAno: '04/2026',
          casaId: 'casa-2',
          leituraAnteriorM3: 200,
          leituraAtualM3: 200,
        );

        expect(leitura.consumoM3, 0);
      });

      test('consumo negativo se atual < anterior (erro de leitura)', () {
        final leitura = Leitura(
          id: 'leit-3',
          mesAno: '04/2026',
          casaId: 'casa-3',
          leituraAnteriorM3: 300,
          leituraAtualM3: 250,
        );

        // O sistema permite valor negativo — a validação é na camada de negócio
        expect(leitura.consumoM3, -50);
      });
    });

    group('Casa sem leitura', () {
      test('leitura com valor zero indica ausência de dados', () {
        final leitura = Leitura(
          id: 'leit-4',
          mesAno: '04/2026',
          casaId: 'casa-4',
          leituraAnteriorM3: 0,
          leituraAtualM3: 0,
        );

        expect(leitura.consumoM3, 0);
        // Cabe à camada de negócio bloquear cálculo quando
        // leituraAtualM3 == 0 e não é o primeiro mês da casa
      });

      test('leitura só com anterior indica mês incompleto', () {
        final leitura = Leitura(
          id: 'leit-5',
          mesAno: '04/2026',
          casaId: 'casa-5',
          leituraAnteriorM3: 150,
          leituraAtualM3: 0,
        );

        expect(leitura.consumoM3, -150);
        // Valor negativo sinaliza leitura incompleta
      });
    });

    group('Serialização', () {
      test('toMap e fromMap são inversas', () {
        final leitura = Leitura(
          id: 'leit-6',
          mesAno: '04/2026',
          casaId: 'casa-6',
          leituraAnteriorM3: 500,
          leituraAtualM3: 542,
        );

        final map = leitura.toMap();
        final restaurada = Leitura.fromMap(map);

        expect(restaurada.id, leitura.id);
        expect(restaurada.mesAno, leitura.mesAno);
        expect(restaurada.casaId, leitura.casaId);
        expect(restaurada.leituraAnteriorM3, leitura.leituraAnteriorM3);
        expect(restaurada.leituraAtualM3, leitura.leituraAtualM3);
        expect(restaurada.consumoM3, leitura.consumoM3);
      });
    });

    group('copyWith', () {
      test('atualiza apenas campos especificados', () {
        final leitura = Leitura(
          id: 'leit-7',
          mesAno: '03/2026',
          casaId: 'casa-7',
          leituraAnteriorM3: 100,
          leituraAtualM3: 120,
        );

        final copia = leitura.copyWith(
          mesAno: '04/2026',
          leituraAnteriorM3: 120,
          leituraAtualM3: 145,
        );

        expect(copia.mesAno, '04/2026');
        expect(copia.leituraAnteriorM3, 120);
        expect(copia.leituraAtualM3, 145);
        expect(copia.casaId, 'casa-7'); // mantido
      });
    });
  });
}
