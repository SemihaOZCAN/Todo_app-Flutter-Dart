import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/main.dart'; // Doğru ana dosya import edildiğinden emin olun.

void main() {
  testWidgets('TodoApp - Yeni bir görev ekle ve sil', (WidgetTester tester) async {
    // Uygulamayı başlat.
    await tester.pumpWidget(TodoApp());

    // Uygulama başlangıcında todo listesi boş olmalı.
    expect(find.text('Görev girin'), findsNothing);

    // '+' butonuna tıkla ve bir görev ekleme penceresini aç.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();  // Yeni frame oluşturur.

    // Görev metnini gir.
    await tester.enterText(find.byType(TextField), 'Yeni Görev');
    await tester.pump();  // Yeni frame oluşturur.

    // Ekle butonuna tıkla.
    await tester.tap(find.text('Ekle'));
    await tester.pump();  // Yeni frame oluşturur.

    // Yeni görev eklenmiş olmalı.
    expect(find.text('Yeni Görev'), findsOneWidget);

    // Uzun basarak görevi sil.
    await tester.longPress(find.text('Yeni Görev'));
    await tester.pump();  // Yeni frame oluşturur.

    // Görev silinmiş olmalı.
    expect(find.text('Yeni Görev'), findsNothing);
  });
}
