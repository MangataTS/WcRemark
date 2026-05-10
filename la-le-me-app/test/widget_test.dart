import 'package:flutter_test/flutter_test.dart';
import 'package:la_le_me_app/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const LaLeMeApp());
    expect(find.text('拉了么'), findsOneWidget);
  });
}