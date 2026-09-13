import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PopupMenuButton does not crash when hidden immediately', (
    WidgetTester tester,
  ) async {
    var showPopupMenu = true;

    Widget buildWidget() {
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: <Widget>[
              if (showPopupMenu)
                PopupMenuButton<String>(
                  itemBuilder: (BuildContext context) {
                    return const <PopupMenuItem<String>>[
                      PopupMenuItem<String>(
                        value: 'add',
                        child: Text('Add'),
                      ),
                      PopupMenuItem<String>(
                        value: 'hide',
                        child: Text('Hide'),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ];
                  },
                  onSelected: (String value) {
                    if (value == 'hide') {
                      showPopupMenu = false;
                    }
                  },
                ),
            ],
          ),
          body: Text(
            'PopupMenuButton:${showPopupMenu ? 'showing' : 'hidden'}',
          ),
        ),
      );
    }

    await tester.pumpWidget(buildWidget());

    final popupMenuButton = find.byType(PopupMenuButton<String>);
    expect(popupMenuButton, findsOneWidget);

    await tester.tap(popupMenuButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hide'));

    await tester.pumpWidget(buildWidget());

    expect(tester.takeException(), isNull);
  });
}
