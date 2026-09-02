import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker_app/widgets/app_cover_image.dart';

void main() {
  testWidgets('AppCoverImage muestra placeholder por defecto cuando la URL es nula o vacía',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppCoverImage(coverUrl: null, width: 100, height: 150),
        ),
      ),
    );

    expect(find.byIcon(Icons.sports_esports_rounded), findsOneWidget);
  });

  testWidgets('AppCoverImage respeta el borderRadius especificado',
      (WidgetTester tester) async {
    const radius = BorderRadius.all(Radius.circular(12));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppCoverImage(
            coverUrl: '',
            width: 100,
            height: 150,
            borderRadius: radius,
          ),
        ),
      ),
    );

    final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
    expect(clipRRect.borderRadius, equals(radius));
  });

  testWidgets('AppCoverImage renderiza placeholder personalizado si se provee',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppCoverImage(
            coverUrl: '',
            width: 80,
            height: 120,
            placeholder: Text('Custom Placeholder'),
          ),
        ),
      ),
    );

    expect(find.text('Custom Placeholder'), findsOneWidget);
  });
}
