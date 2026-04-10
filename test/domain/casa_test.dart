import 'package:flutter_test/flutter_test.dart';

import 'package:ilheus_app/features/agua/domain/models/casa.dart';

void main() {
  group('Casa', () {
    group('Isenção parcial', () {
      test('casa ativa com isenção só de água', () {
        final casa = Casa(
          id: 'casa-1',
          numero: 5,
          ativa: true,
          isentoAgua: true,
          isentoEsgoto: false,
          isentoServicoBasico: false,
          isentoLuz: false,
          isentoCond: false,
        );

        expect(casa.isentoAgua, isTrue);
        expect(casa.isentoEsgoto, isFalse);
        expect(casa.isentoServicoBasico, isFalse);
        expect(casa.isentoLuz, isFalse);
        expect(casa.isentoCond, isFalse);
        expect(casa.ativa, isTrue);
        expect(casa.isQuiosque, isFalse);
      });

      test('casa com múltiplas isenções', () {
        final casa = Casa(
          id: 'casa-2',
          numero: 10,
          ativa: true,
          isentoAgua: true,
          isentoEsgoto: true,
          isentoServicoBasico: false,
          isentoLuz: true,
          isentoCond: false,
        );

        expect(casa.isentoAgua, isTrue);
        expect(casa.isentoEsgoto, isTrue);
        expect(casa.isentoLuz, isTrue);
      });

      test('casa sem isenções (padrão)', () {
        final casa = Casa(id: 'casa-3', numero: 7);

        expect(casa.isentoAgua, isFalse);
        expect(casa.isentoEsgoto, isFalse);
        expect(casa.isentoServicoBasico, isFalse);
        expect(casa.isentoLuz, isFalse);
        expect(casa.isentoCond, isFalse);
      });
    });

    group('Casa inativa (vazia)', () {
      test('casa inativa ainda paga componentes fixos', () {
        final casa = Casa(
          id: 'casa-4',
          numero: 12,
          ativa: false,
        );

        expect(casa.ativa, isFalse);
        // Casa vazia não paga água (consumo zero) mas paga fixos
        // O sistema deve considerar isentoAgua=false, mas consumo será 0
        expect(casa.isentoEsgoto, isFalse);
        expect(casa.isentoServicoBasico, isFalse);
        expect(casa.isentoLuz, isFalse);
        expect(casa.isentoCond, isFalse);
      });

      test('casa inativa não é quiosque', () {
        final casa = Casa(id: 'casa-5', numero: 3, ativa: false);
        expect(casa.isQuiosque, isFalse);
      });
    });

    group('Quiosque', () {
      test('casa 23 é quiosque', () {
        final quiosque = Casa(id: 'casa-23', numero: 23);
        expect(quiosque.isQuiosque, isTrue);
      });

      test('quiosque pode ter isenções independentes', () {
        final quiosque = Casa(
          id: 'casa-23',
          numero: 23,
          isentoAgua: false,
          isentoEsgoto: true,
          isentoServicoBasico: true,
          isentoLuz: true,
          isentoCond: true,
        );

        expect(quiosque.isQuiosque, isTrue);
        expect(quiosque.isentoEsgoto, isTrue);
      });
    });

    group('Serialização', () {
      test('toMap e fromMap são inversas', () {
        final casa = Casa(
          id: 'casa-6',
          numero: 15,
          ativa: false,
          isentoAgua: true,
          isentoEsgoto: false,
          isentoServicoBasico: true,
          isentoLuz: false,
          isentoCond: true,
        );

        final map = casa.toMap();
        final restaurada = Casa.fromMap(map);

        expect(restaurada.id, casa.id);
        expect(restaurada.numero, casa.numero);
        expect(restaurada.ativa, casa.ativa);
        expect(restaurada.isentoAgua, casa.isentoAgua);
        expect(restaurada.isentoEsgoto, casa.isentoEsgoto);
        expect(restaurada.isentoServicoBasico, casa.isentoServicoBasico);
        expect(restaurada.isentoLuz, casa.isentoLuz);
        expect(restaurada.isentoCond, casa.isentoCond);
      });
    });

    group('copyWith', () {
      test('altera apenas campos especificados', () {
        final casa = Casa(id: 'casa-7', numero: 8);
        final copia = casa.copyWith(isentoAgua: true, ativa: false);

        expect(copia.isentoAgua, isTrue);
        expect(copia.ativa, isFalse);
        expect(copia.numero, 8); // mantido
        expect(copia.isentoEsgoto, isFalse); // mantido
      });
    });
  });
}
