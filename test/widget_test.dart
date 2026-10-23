import 'package:flutter_test/flutter_test.dart';
import 'package:pose1/main.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Billing app loads smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 3500));
    expect(find.text('PLATANO'), findsOneWidget);
  });
}
