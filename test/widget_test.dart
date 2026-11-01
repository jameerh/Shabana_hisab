import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snaphisaab/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ShabanaHisaabApp initialization smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ShabanaHisaabApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
