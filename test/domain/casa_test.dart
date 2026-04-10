import 'package:flutter_test/flutter_test.dart';

import 'package:ilheus_app/features/agua/domain/models/casa.dart';

void main() {
  group('Casa', () {
    group('Isenção simplificada', () {
      test('casa ativa com isento = true', () {
        final casa = Casa(
          id: 'casa-8',
          numero: 8,
          ativa: true,
          isento: true,
        );

        expect(casa.isento, isTrue);
        expect(casa.ehAdministrador, isFalse);
      });

      test('casa com isento = false e ehAdministrador = true', () {
        final casa = Casa(
          id: 'casa-2',
          numero: 2,
          ativa: true,
          isento: false,
          ehAdministrador: true,
        );

        expect(casa.isento, isFalse);
        expect(casa.ehAdministrador, isTrue);
      });

      test('casa padrão — sem isenção, sem admin', () {
        final casa = Casa(
          id: 'casa-5',
          numero: 5,
        );

        expect(casa.isento, isFalse);
        expect(casa.ehAdministrador, isFalse);
      });
    });

    group('Casa inativa (vazia)', () {
      test('casa inativa ainda paga componentes fixos', () {
        final casa = Casa(
          id: 'casa-10',
          numero: 10,
          ativa: false,
        );

        expect(casa.ativa, isFalse);
        // O sistema deve considerar isento=false, mas consumo será 0
        expect(casa.isento, isFalse);
        expect(casa.ehAdministrador, isFalse);
      });

      test('casa inativa não é quiiosque', () {
        final casa = Casa(
          id: 'casa-10',
          numero: 10,
          ativa: false,
        );

        expect(casa.isQuiosque, isFalse);
      });
    });

    group('Quiosque', () {
      test('casa 23 é quiiosque', () {
        final casa = Casa(
          id: 'casa-23',
          numero: 23,
        );

        expect(casa.isQuiosque, isTrue);
      });

      test('quiiosque pode ter isenção independente', () {
        final quiosque = Casa(
          id: 'casa-23',
          numero: 23,
          isento: true,
          ehAdministrador: true,
        );

        expect(quiosque.isQuiosque, isTrue);
        expect(quiosque.isento, isTrue);
        expect(quiosque.ehAdministrador, isTrue);
      });
    });

    group('Serialização', () {
      test('toMap e fromMap são inversas', () {
        final casa = Casa(
          id: 'casa-8',
          numero: 8,
          ativa: true,
          isento: true,
          ehAdministrador: false,
        );

        final map = casa.toMap();
        final restaurada = Casa.fromMap(map);

        expect(restaurada.id, casa.id);
        expect(restaurada.numero, casa.numero);
        expect(restaurada.ativa, casa.ativa);
        expect(restaurada.isento, casa.isento);
        expect(restaurada.ehAdministrador, casa.ehAdministrador);
      });
    });

    group('copyWith', () {
      test('altera apenas campos especificados', () {
        final casa = Casa(
          id: 'casa-5',
          numero: 5,
          ativa: true,
          isento: false,
          ehAdministrador: false,
        );

        final copia = casa.copyWith(isento: true, ativa: false);

        expect(copia.isento, isTrue);
        expect(copia.ativa, isFalse);
        expect(copia.numero, 5); // mantido
        expect(copia.ehAdministrador, isFalse); // mantido
      });
    });
  });
}
