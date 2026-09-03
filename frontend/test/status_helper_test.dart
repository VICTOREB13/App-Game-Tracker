import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker_app/views/widgets/status_helper.dart';

void main() {
  group('StatusHelper Unit Tests', () {
    test('Constantes de estado están debidamente definidas y alineadas', () {
      expect(StatusHelper.porJugar, equals('Por jugar'));
      expect(StatusHelper.jugando, equals('Jugando'));
      expect(StatusHelper.jugado, equals('Jugado'));
      expect(StatusHelper.backlog, equals('Por jugar'));
      expect(StatusHelper.playing, equals('Jugando'));
      expect(StatusHelper.completed, equals('Jugado'));

      expect(StatusHelper.allStatuses, containsAll(['Todos', 'Jugando', 'Por jugar', 'Jugado']));
      expect(StatusHelper.gameStatuses, containsAll(['Por jugar', 'Jugando', 'Jugado']));
      expect(StatusHelper.gameStatuses, isNot(contains('Todos')));
    });

    test('getColor retorna colores específicos por estado y fallback neutro', () {
      expect(StatusHelper.getColor(StatusHelper.jugando), equals(const Color(0xFFDC2626)));
      expect(StatusHelper.getColor(StatusHelper.porJugar), equals(const Color(0xFFF59E0B)));
      expect(StatusHelper.getColor(StatusHelper.jugado), equals(const Color(0xFF10B981)));
      expect(StatusHelper.getColor('Desconocido'), equals(const Color(0xFFA1A1AA)));
      expect(StatusHelper.getColor(null), equals(const Color(0xFFA1A1AA)));
    });

    test('getIcon retorna iconos específicos por estado y fallback temático', () {
      expect(StatusHelper.getIcon(StatusHelper.jugando), equals(Icons.play_circle_outline_rounded));
      expect(StatusHelper.getIcon(StatusHelper.porJugar), equals(Icons.watch_later_outlined));
      expect(StatusHelper.getIcon(StatusHelper.jugado), equals(Icons.check_circle_outline_rounded));
      expect(StatusHelper.getIcon('Desconocido'), equals(Icons.sports_esports_rounded));
      expect(StatusHelper.getIcon(null), equals(Icons.sports_esports_rounded));
    });
  });

  group('StatusHelper Widget Tests', () {
    testWidgets('buildStatusPill renderiza el texto y estilos esperados', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => StatusHelper.buildStatusPill(context, StatusHelper.jugado),
            ),
          ),
        ),
      );

      expect(find.text('Jugado'), findsOneWidget);
    });

    testWidgets('buildStatusChip interactúa correctamente con el callback de selección', (tester) async {
      String selected = 'Todos';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return StatusHelper.buildStatusChip(
                  context: context,
                  status: StatusHelper.jugando,
                  isSelected: selected == StatusHelper.jugando,
                  onSelected: (val) {
                    setState(() {
                      selected = val;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Jugando'), findsOneWidget);
      await tester.tap(find.text('Jugando'));
      await tester.pumpAndSettle();

      expect(selected, equals(StatusHelper.jugando));
    });

    testWidgets('StatusBadge renderiza con padding y tamaño configurables', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              status: 'Por jugar',
              fontSize: 10,
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            ),
          ),
        ),
      );

      expect(find.text('Por jugar'), findsOneWidget);
    });
  });
}
