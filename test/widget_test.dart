import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:virtual_wardrobe_ai/app.dart';

void main() {
  testWidgets('app boots into a MaterialApp shell',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const VirtualWardrobeApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
