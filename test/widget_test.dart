import 'package:easyadd/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts and shows the EasyAdd name', (tester) async {
    await tester.pumpWidget(const EasyAddApp());
    expect(find.text('EasyAdd'), findsOneWidget);
  });
}
