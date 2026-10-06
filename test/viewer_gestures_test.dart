import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazwall/models/picture.dart';
import 'package:kazwall/screens/viewer_screen.dart';
import 'package:kazwall/services/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Насколько просмотр утянут вниз свайпом
double dragOffset(WidgetTester tester) {
  final transforms = tester.widgetList<Transform>(find.byType(Transform));
  return transforms.map((t) => t.transform.getTranslation().y).reduce((a, b) => a > b ? a : b);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs.init();
  });

  Future<void> open(WidgetTester tester) async {
    final pictures = [
      for (var i = 0; i < 3; i++) Picture(id: '$i', type: 'nature', file: 'images/$i.jpg', thumb: 'images/${i}s.jpg'),
    ];
    await tester.pumpWidget(MaterialApp(home: ViewerScreen(pictures: pictures, index: 0)));
    await tester.pump();
  }

  testWidgets('свайп вниз одним пальцем тянет картинку', (tester) async {
    await open(tester);
    final finger = await tester.startGesture(const Offset(200, 200));
    for (var i = 0; i < 10; i++) {
      await finger.moveBy(const Offset(0, 15));
      await tester.pump();
    }
    expect(dragOffset(tester), greaterThan(50));
    await finger.up();
    await tester.pumpAndSettle();
    // Утянули недалеко — картинка возвращается на место
    expect(dragOffset(tester), 0);
  });

  testWidgets('два пальца — это масштабирование, просмотр вниз не едет', (tester) async {
    await open(tester);
    final first = await tester.startGesture(const Offset(200, 300), pointer: 1);
    final second = await tester.startGesture(const Offset(250, 400), pointer: 2);
    for (var i = 0; i < 10; i++) {
      // Пальцы расходятся, и оба заметно смещаются по вертикали
      await first.moveBy(const Offset(-4, 12));
      await second.moveBy(const Offset(4, 24));
      await tester.pump();
    }
    expect(dragOffset(tester), 0);
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
  });
}
