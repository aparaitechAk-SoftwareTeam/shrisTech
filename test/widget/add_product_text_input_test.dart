import 'package:bbs_gold/Product Module/AddProductFormWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('multiline note input uses a compatible keyboard type', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddProductTextInput(
            controller: TextEditingController(),
            label: 'Note',
            hint: 'Describe validity, terms and products.',
            icon: Icons.notes_rounded,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.keyboardType, TextInputType.multiline);
  });
}
