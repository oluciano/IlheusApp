import 'package:flutter_test/flutter_test.dart';

import 'package:ilheus_app/features/agua/domain/models/debito.dart';
import 'package:ilheus_app/features/agua/domain/models/status_debito.dart';

void main() {
  group('Debito', () {
    group('Débito quitado permanece no histórico', () {
      test('débito aberto', () {
        final debito = Debito(
          id: 'deb-1',
          cobrancaId: 'cob-1',
          casaId: 'casa-1',
          mesAnoOrigem: '03/2026',
          valorCentavos: 17654,
          status: StatusDebito.aberto,
        );

        expect(debito.isAberto, isTrue);
        expect(debito.isQuitado, isFalse);
        expect(debito.dataQuitacao, isNull);
      });

      test('débito quitado mantém histórico', () {
        final debitoQuitado = Debito(
          id: 'deb-2',
          cobrancaId: 'cob-2',
          casaId: 'casa-2',
          mesAnoOrigem: '02/2026',
          valorCentavos: 17654,
          status: StatusDebito.quitado,
          dataQuitacao: DateTime(2026, 3, 15),
        );

        expect(debitoQuitado.isQuitado, isTrue);
        expect(debitoQuitado.isAberto, isFalse);
        expect(debitoQuitado.dataQuitacao, isNotNull);
        expect(debitoQuitado.mesAnoOrigem, '02/2026');
        // Débito quitado permanece no histórico com mesAnoOrigem
      });

      test('migrar de aberto para quitado', () {
        final debitoAberto = Debito(
          id: 'deb-3',
          cobrancaId: 'cob-3',
          casaId: 'casa-3',
          mesAnoOrigem: '03/2026',
          valorCentavos: 17654,
        );

        final debitoQuitado = debitoAberto.copyWith(
          status: StatusDebito.quitado,
          dataQuitacao: DateTime(2026, 4, 5),
        );

        expect(debitoQuitado.isQuitado, isTrue);
        expect(debitoQuitado.dataQuitacao, isNotNull);
        expect(debitoQuitado.valorCentavos, 17654); // valor preservado
      });
    });

    group('Casa inativa não zera dívida', () {
      test('casa inativa com débito em aberto mantém valor', () {
        // Casa 12 ficou vazia mas tem débito de mês anterior
        final debitoCasaInativa = Debito(
          id: 'deb-4',
          cobrancaId: 'cob-4',
          casaId: 'casa-12', // casa inativa
          mesAnoOrigem: '03/2026',
          valorCentavos: 17654,
          status: StatusDebito.aberto,
        );

        // Débito NÃO é zerado — casa inativa ainda deve
        expect(debitoCasaInativa.valorCentavos, 17654);
        expect(debitoCasaInativa.isAberto, isTrue);
      });

      test('casa inativa quita débito — valor preservado', () {
        final debitoQuitado = Debito(
          id: 'deb-5',
          cobrancaId: 'cob-5',
          casaId: 'casa-12',
          mesAnoOrigem: '03/2026',
          valorCentavos: 17654,
          status: StatusDebito.quitado,
          dataQuitacao: DateTime(2026, 5, 10),
        );

        expect(debitoQuitado.valorCentavos, 17654);
        expect(debitoQuitado.isQuitado, isTrue);
      });
    });

    group('Débito nunca somado na fatura nova', () {
      test('débito aparece como alerta separado', () {
        // Este teste documenta a invariant do domínio:
        // "Débito anterior não acumula na fatura nova, fica separado"
        final debito = Debito(
          id: 'deb-6',
          cobrancaId: 'cob-6',
          casaId: 'casa-6',
          mesAnoOrigem: '02/2026',
          valorCentavos: 17654,
        );

        // O débito é armazenado separadamente — não faz parte
        // do cálculo da fatura do mês atual.
        // A camada de UI deve exibir como alerta:
        // "🚨 Você possui débitos anteriores em aberto!"
        expect(debito.mesAnoOrigem, '02/2026');
        expect(debito.valorCentavos, 17654);
      });
    });

    group('Serialização', () {
      test('toMap e fromMap são inversas', () {
        final debito = Debito(
          id: 'deb-7',
          cobrancaId: 'cob-7',
          casaId: 'casa-7',
          mesAnoOrigem: '01/2026',
          valorCentavos: 20000,
          status: StatusDebito.aberto,
        );

        final map = debito.toMap();
        final restaurada = Debito.fromMap(map);

        expect(restaurada.id, debito.id);
        expect(restaurada.cobrancaId, debito.cobrancaId);
        expect(restaurada.casaId, debito.casaId);
        expect(restaurada.mesAnoOrigem, debito.mesAnoOrigem);
        expect(restaurada.valorCentavos, debito.valorCentavos);
        expect(restaurada.status, debito.status);
      });

      test('fromMap com dataQuitacao', () {
        final debito = Debito(
          id: 'deb-8',
          cobrancaId: 'cob-8',
          casaId: 'casa-8',
          mesAnoOrigem: '12/2025',
          valorCentavos: 15000,
          status: StatusDebito.quitado,
          dataQuitacao: DateTime(2026, 1, 20),
        );

        final map = debito.toMap();
        final restaurada = Debito.fromMap(map);

        expect(restaurada.dataQuitacao, isNotNull);
        expect(restaurada.dataQuitacao!.day, 20);
        expect(restaurada.dataQuitacao!.month, 1);
      });

      test('fromMap sem dataQuitacao', () {
        final map = <String, dynamic>{
          'id': 'deb-9',
          'cobranca_id': 'cob-9',
          'casa_id': 'casa-9',
          'mes_ano_origem': '03/2026',
          'valor_centavos': 10000,
          'status': 'aberto',
          'data_quitacao': null,
        };

        final debito = Debito.fromMap(map);
        expect(debito.dataQuitacao, isNull);
        expect(debito.isAberto, isTrue);
      });
    });

    group('copyWith', () {
      test('marca como quitado sem alterar outros campos', () {
        final debito = Debito(
          id: 'deb-10',
          cobrancaId: 'cob-10',
          casaId: 'casa-10',
          mesAnoOrigem: '02/2026',
          valorCentavos: 17654,
        );

        final quitado = debito.copyWith(
          status: StatusDebito.quitado,
          dataQuitacao: DateTime(2026, 3, 25),
        );

        expect(quitado.isQuitado, isTrue);
        expect(quitado.mesAnoOrigem, '02/2026'); // preservado
        expect(quitado.valorCentavos, 17654); // preservado
      });
    });
  });
}
