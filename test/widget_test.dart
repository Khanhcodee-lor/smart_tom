import 'package:flutter_test/flutter_test.dart';
import 'package:thuy_san/main.dart';

void main() {
  testWidgets('AquaSmart app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AquaSmartApp());
    expect(find.text('AquaSmart'), findsOneWidget);
  });
}
