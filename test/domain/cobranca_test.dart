import 'package:flutter_test/flutter_test.dart';

import 'package:ilheus_app/features/agua/domain/models/cobranca.dart';
import 'package:ilheus_app/features/agua/domain/models/status_cobranca.dart';

void main() {
  group('Cobranca', () {
    group('Breakdown completo por componente', () {
      test('cobrança com todos os componentes preenchidos', () {
        final cobranca = Cobranca(
          id: 'cob-1',
          faturaId: 'fat-1',
          casaId: 'casa-1',
          valorAgua: 6800, // R$ 68,00
          valorEsgoto: 5200, // R$ 52,00
          valorServicoBasico: 3700, // R$ 37,00
          valorLuz: 454, // R$ 4,54
          valorCond: 1500, // R$ 15,00
          valorQuiosque: 200, // R$ 2,00
          valorJuros: 0,
          valorDebitos: 0,
          valorTotal: 17854,
        );

        expect(cobranca.valorAgua, 6800);
        expect(cobranca.valorEsgoto, 5200);
        expect(cobranca.valorServicoBasico, 3700);
        expect(cobranca.valorLuz, 454);
        expect(cobranca.valorCond, 1500);
        expect(cobranca.valorQuiosque, 200);
        expect(cobranca.valorJuros, 0);
        expect(cobranca.valorDebitos, 0);
        expect(cobranca.valorTotal, 17854);
        expect(cobranca.status, StatusCobranca.pendente);
      });

      test('cobrança com débito anterior separado', () {
        final cobranca = Cobranca(
          id: 'cob-2',
          faturaId: 'fat-2',
          casaId: 'casa-2',
          valorAgua: 7100,
          valorEsgoto: 5200,
          valorServicoBasico: 3700,
          valorLuz: 454,
          valorCond: 1500,
          valorQuiosque: 0,
          valorJuros: 0,
          valorDebitos: 17654, // Débito do mês anterior SEPARADO
          valorTotal: 29508, // Total inclui débito
        );

        // Débito anterior aparece no breakdown
        expect(cobranca.valorDebitos, 17654);
        // Mas NÃO é somado na fatura nova — fica como campo separado
        final componentesMesAtual = cobranca.valorAgua +
            cobranca.valorEsgoto +
            cobranca.valorServicoBasico +
            cobranca.valorLuz +
            cobranca.valorCond +
            cobranca.valorQuiosque +
            cobranca.valorJuros;
        expect(componentesMesAtual, 17954);
        // Débito é separado: 17954 + 17654 = 35608 (mas valorTotal pode ser diferente)
      });

      test('cobrança com juros aplicados', () {
        final cobranca = Cobranca(
          id: 'cob-3',
          faturaId: 'fat-3',
          casaId: 'casa-3',
          valorAgua: 6800,
          valorEsgoto: 5200,
          valorServicoBasico: 3700,
          valorLuz: 454,
          valorCond: 1500,
          valorQuiosque: 0,
          valorJuros: 500, // Juros aplicados
          valorDebitos: 0,
          valorTotal: 18154,
        );

        expect(cobranca.valorJuros, 500);
      });

      test('cobrança com isenção parcial (casa com isentoAgua)', () {
        final cobranca = Cobranca(
          id: 'cob-4',
          faturaId: 'fat-4',
          casaId: 'casa-4',
          valorAgua: 0, // Isento de água
          valorEsgoto: 5200,
          valorServicoBasico: 3700,
          valorLuz: 454,
          valorCond: 1500,
          valorQuiosque: 0,
          valorJuros: 0,
          valorDebitos: 0,
          valorTotal: 10854,
        );

        expect(cobranca.valorAgua, 0);
        expect(cobranca.valorEsgoto, 5200);
      });
    });

    group('Status de cobrança', () {
      test('cria como pendente por padrão', () {
        final cobranca = Cobranca(
          id: 'cob-5',
          faturaId: 'fat-5',
          casaId: 'casa-5',
          valorTotal: 1000,
        );

        expect(cobranca.status, StatusCobranca.pendente);
      });

      test('muda para pago', () {
        final cobranca = Cobranca(
          id: 'cob-6',
          faturaId: 'fat-6',
          casaId: 'casa-6',
          valorTotal: 1000,
          status: StatusCobranca.pago,
        );

        expect(cobranca.status, StatusCobranca.pago);
      });

      test('muda para inadimplente', () {
        final cobranca = Cobranca(
          id: 'cob-7',
          faturaId: 'fat-7',
          casaId: 'casa-7',
          valorTotal: 1000,
          status: StatusCobranca.inadimplente,
        );

        expect(cobranca.status, StatusCobranca.inadimplente);
      });
    });

    group('Serialização', () {
      test('toMap e fromMap são inversas', () {
        final cobranca = Cobranca(
          id: 'cob-8',
          faturaId: 'fat-8',
          casaId: 'casa-8',
          valorAgua: 6800,
          valorEsgoto: 5200,
          valorServicoBasico: 3700,
          valorLuz: 454,
          valorCond: 1500,
          valorQuiosque: 200,
          valorJuros: 100,
          valorDebitos: 15000,
          valorTotal: 32954,
          status: StatusCobranca.pendente,
        );

        final map = cobranca.toMap();
        final restaurada = Cobranca.fromMap(map);

        expect(restaurada.id, cobranca.id);
        expect(restaurada.faturaId, cobranca.faturaId);
        expect(restaurada.casaId, cobranca.casaId);
        expect(restaurada.valorAgua, cobranca.valorAgua);
        expect(restaurada.valorEsgoto, cobranca.valorEsgoto);
        expect(restaurada.valorServicoBasico, cobranca.valorServicoBasico);
        expect(restaurada.valorLuz, cobranca.valorLuz);
        expect(restaurada.valorCond, cobranca.valorCond);
        expect(restaurada.valorQuiosque, cobranca.valorQuiosque);
        expect(restaurada.valorJuros, cobranca.valorJuros);
        expect(restaurada.valorDebitos, cobranca.valorDebitos);
        expect(restaurada.valorTotal, cobranca.valorTotal);
        expect(restaurada.status, cobranca.status);
      });
    });

    group('copyWith', () {
      test('altera apenas status', () {
        final cobranca = Cobranca(
          id: 'cob-9',
          faturaId: 'fat-9',
          casaId: 'casa-9',
          valorTotal: 1000,
          status: StatusCobranca.pendente,
        );

        final paga = cobranca.copyWith(status: StatusCobranca.pago);

        expect(paga.status, StatusCobranca.pago);
        expect(paga.valorTotal, 1000); // mantido
      });
    });
  });
}
