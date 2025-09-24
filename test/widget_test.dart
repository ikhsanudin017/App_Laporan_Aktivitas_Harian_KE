import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Menampilkan halaman login saat aplikasi dimulai',
      (tester) async {
    await tester.pumpWidget(const ActivityApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Sistem Laporan Aktivitas'), findsOneWidget);
  });
}
