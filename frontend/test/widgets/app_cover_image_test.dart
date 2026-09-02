import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tracker_app/widgets/app_cover_image.dart';

void main() {
  test('AppCoverImage tiene valores por defecto apropiados para preservación de aspect ratio', () {
    const cover = AppCoverImage(coverUrl: 'https://example.com/cover.jpg');
    expect(cover.memCacheWidth, equals(600));
    expect(cover.memCacheHeight, isNull);
    expect(cover.cacheWidth, equals(600));
    expect(cover.cacheHeight, isNull);
    expect(cover.fit, equals(BoxFit.cover));
  });

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

  testWidgets('AppCoverImage genera CachedNetworkImage con memCacheHeight nulo para aspect ratio dinámico',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppCoverImage(
            coverUrl: 'https://images.igdb.com/igdb/image/upload/t_cover_big/co1r7f.png',
            width: 120,
            height: 160,
          ),
        ),
      ),
    );

    final cachedImageFinder = find.byType(CachedNetworkImage);
    expect(cachedImageFinder, findsOneWidget);
    final cachedImage = tester.widget<CachedNetworkImage>(cachedImageFinder);
    expect(cachedImage.memCacheWidth, equals(600));
    expect(cachedImage.memCacheHeight, isNull);
    expect(cachedImage.fit, equals(BoxFit.cover));
  });

  testWidgets('AppCoverImage con ruta local genera Image.file con fit cover',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppCoverImage(
            coverUrl: '/tmp/local_cover.jpg',
            width: 120,
            height: 160,
          ),
        ),
      ),
    );

    final imageFinder = find.byType(Image);
    expect(imageFinder, findsOneWidget);
    final image = tester.widget<Image>(imageFinder);
    expect(image.fit, equals(BoxFit.cover));
  });
}

