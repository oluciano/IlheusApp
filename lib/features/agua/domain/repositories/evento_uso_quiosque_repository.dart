import 'package:ilheus_app/features/agua/domain/models/evento_uso_quiosque.dart';

abstract class EventoUsoQuiosqueRepository {
  Future<void> salvarEvento(EventoUsoQuiosque evento);
  Future<EventoUsoQuiosque?> buscarPorMes(String mesAno);
}
