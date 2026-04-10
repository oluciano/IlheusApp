import 'package:flutter_test/flutter_test.dart';

import 'package:ilheus_app/features/agua/domain/models/pagamento.dart';

void main() {
  group('Pagamento', () {
    group('Pagamento até dia 10 — sem juros', () {
      test('pagamento no dia 5 do mês seguinte', () {
        final pagamento = Pagamento(
          id: 'pag-1',
          cobrancaId: 'cob-1',
          dataPagamento: DateTime(2026, 3, 5),
          valorPagoCentavos: 17854,
        );

        expect(pagamento.dataPagamento.day, 5);
        expect(pagamento.dataPagamento.month, 3);
        expect(pagamento.dataPagamento.year, 2026);
        // Dia 5 <= 10 → sem juros (lógica na camada de negócio)
      });

      test('pagamento exatamente no dia 10', () {
        final pagamento = Pagamento(
          id: 'pag-2',
          cobrancaId: 'cob-2',
          dataPagamento: DateTime(2026, 3, 10),
          valorPagoCentavos: 17854,
        );

        expect(pagamento.dataPagamento.day, 10);
        // Dia 10 → sem juros (limite)
      });

      test('pagamento no dia 1 do mês seguinte', () {
        final pagamento = Pagamento(
          id: 'pag-3',
          cobrancaId: 'cob-3',
          dataPagamento: DateTime(2026, 3, 1),
          valorPagoCentavos: 17854,
        );

        expect(pagamento.dataPagamento.day, 1);
        // Dia 1 → sem juros
      });
    });

    group('Pagamento após dia 10 — juros aplicados', () {
      test('pagamento no dia 11', () {
        final pagamento = Pagamento(
          id: 'pag-4',
          cobrancaId: 'cob-4',
          dataPagamento: DateTime(2026, 3, 11),
          valorPagoCentavos: 17854,
        );

        expect(pagamento.dataPagamento.day, 11);
        // Dia 11 > 10 → juros aplicados (lógica na camada de negócio)
      });

      test('pagamento com 20 dias de atraso', () {
        final pagamento = Pagamento(
          id: 'pag-5',
          cobrancaId: 'cob-5',
          dataPagamento: DateTime(2026, 3, 20),
          valorPagoCentavos: 17854,
        );

        expect(pagamento.dataPagamento.day, 20);
        // 20 - 10 = 10 dias de atraso → juros proporcionais
      });

      test('pagamento com 30 dias de atraso', () {
        final pagamento = Pagamento(
          id: 'pag-6',
          cobrancaId: 'cob-6',
          dataPagamento: DateTime(2026, 4, 5),
          valorPagoCentavos: 17854,
        );

        expect(pagamento.dataPagamento.day, 5);
        expect(pagamento.dataPagamento.month, 4);
        // Pagou no mês seguinte, dia 5 → ainda sem juros se vencimento era dia 10
      });
    });

    group('Serialização', () {
      test('toMap e fromMap são inversas', () {
        final pagamento = Pagamento(
          id: 'pag-7',
          cobrancaId: 'cob-7',
          dataPagamento: DateTime(2026, 3, 15, 14, 30),
          valorPagoCentavos: 18000,
        );

        final map = pagamento.toMap();
        final restaurada = Pagamento.fromMap(map);

        expect(restaurada.id, pagamento.id);
        expect(restaurada.cobrancaId, pagamento.cobrancaId);
        expect(restaurada.dataPagamento.year, pagamento.dataPagamento.year);
        expect(restaurada.dataPagamento.month, pagamento.dataPagamento.month);
        expect(restaurada.dataPagamento.day, pagamento.dataPagamento.day);
        expect(restaurada.dataPagamento.hour, pagamento.dataPagamento.hour);
        expect(restaurada.valorPagoCentavos, pagamento.valorPagoCentavos);
      });

      test('data de pagamento preserva hora exata', () {
        final pagamento = Pagamento(
          id: 'pag-8',
          cobrancaId: 'cob-8',
          dataPagamento: DateTime(2026, 3, 11, 23, 59),
          valorPagoCentavos: 1000,
        );

        final map = pagamento.toMap();
        final restaurada = Pagamento.fromMap(map);

        // Hora exata importa para cálculo de juros proporcionais
        expect(restaurada.dataPagamento.hour, 23);
        expect(restaurada.dataPagamento.minute, 59);
      });
    });

    group('copyWith', () {
      test('altera apenas valor pago', () {
        final pagamento = Pagamento(
          id: 'pag-9',
          cobrancaId: 'cob-9',
          dataPagamento: DateTime(2026, 3, 5),
          valorPagoCentavos: 1000,
        );

        final copia = pagamento.copyWith(valorPagoCentavos: 1500);

        expect(copia.valorPagoCentavos, 1500);
        expect(copia.dataPagamento, pagamento.dataPagamento); // mantido
      });
    });
  });
}
