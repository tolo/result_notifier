import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:result_notifier/result_notifier.dart';

void main() {
  group('ResultBuilder - build', () {
    testWidgets('ResultBuilder returns correct widget for state',
        (tester) async {
      final notifier = ResultNotifier<String>(data: 'Data');

      final app = MaterialApp(
        home: notifier.builder((context, result, child) => switch (result) {
              (final Data<String> d) => Text(d.data),
              (final Error<String> e) => Text('Error - ${e.data} - ${e.error}'),
              (final Loading<String> l) => Text('Loading - ${l.data}'),
            }),
      );

      await tester.pumpWidget(app);
      expect(find.text('Data'), findsOneWidget);

      notifier.toLoading();
      await tester.pumpAndSettle();
      expect(find.text('Loading - Data'), findsOneWidget);

      notifier.toError(error: 'E');
      await tester.pumpAndSettle();
      expect(find.text('Error - Data - E'), findsOneWidget);
    });

    testWidgets('ResultBuilder.data returns correct widget for state',
        (tester) async {
      final notifier = ResultNotifier<String>(data: 'Data');

      final app = MaterialApp(
        home: notifier.builder((context, result, child) => switch (result) {
              (final Data<String> d) => Text(d.data),
              (final Result<String> r) =>
                Text('No data - loading: ${r.isLoading} - error: ${r.error}'),
            }),
      );

      await tester.pumpWidget(app);
      expect(find.text('Data'), findsOneWidget);

      notifier.value = Loading();
      await tester.pumpAndSettle();
      expect(
          find.text('No data - loading: true - error: null'), findsOneWidget);

      notifier.value = Error(error: 'E');
      await tester.pumpAndSettle();
      expect(find.text('No data - loading: false - error: E'), findsOneWidget);
    });

    testWidgets('ResultBuilder.result returns correct widget for state',
        (tester) async {
      final notifier = ResultNotifier<String>(data: 'Data');

      final app = MaterialApp(
        home: notifier.builder((context, result, child) => switch (result) {
              (final Data<String> d) => Text(d.data),
              (final Result<String> r) => Text(
                  'Catch-all - data: ${r.data} - loading: ${r.isLoading} - error: ${r.error}'),
            }),
      );

      await tester.pumpWidget(app);
      expect(find.text('Data'), findsOneWidget);

      notifier.toLoading();
      await tester.pumpAndSettle();
      expect(find.text('Catch-all - data: Data - loading: true - error: null'),
          findsOneWidget);

      notifier.toError(error: 'E');
      await tester.pumpAndSettle();
      expect(find.text('Catch-all - data: Data - loading: false - error: E'),
          findsOneWidget);
    });
  });

  group('ValueListenableBuilder', () {
    testWidgets('Returns correct widget for state', (tester) async {
      final notifier = ResultNotifier<String>(data: 'Data');

      final app = MaterialApp(
        home: notifier.builder((context, result, child) => switch (result) {
              (final Data<String> d) => Text(d.data),
              (final Error<String> e) => Text('Error - ${e.data} - ${e.error}'),
              (final Loading<String> l) => Text('Loading - ${l.data}'),
            }),
      );

      await tester.pumpWidget(app);
      expect(find.text('Data'), findsOneWidget);

      notifier.toLoading();
      await tester.pumpAndSettle();
      expect(find.text('Loading - Data'), findsOneWidget);

      notifier.toError(error: 'E');
      await tester.pumpAndSettle();
      expect(find.text('Error - Data - E'), findsOneWidget);
    });
  });

  group('ResourceProvider', () {
    testWidgets('Returns correct widget for state', (tester) async {
      late final ResultNotifier<String> notifier;

      final app = MaterialApp(
        home: ResourceProvider(
          create: (context) => notifier = ResultNotifier<String>(data: 'Data'),
          builder: (context, notifier) =>
              notifier.builder((context, result, child) => switch (result) {
                    (final Data<String> d) => Text(d.data),
                    (final Error<String> e) =>
                      Text('Error - ${e.data} - ${e.error}'),
                    (final Loading<String> l) => Text('Loading - ${l.data}'),
                  }),
        ),
      );
      await tester.pumpWidget(app);
      expect(find.text('Data'), findsOneWidget);

      notifier.toLoading();
      await tester.pumpAndSettle();
      expect(find.text('Loading - Data'), findsOneWidget);

      notifier.toError(error: 'E');
      await tester.pumpAndSettle();
      expect(find.text('Error - Data - E'), findsOneWidget);
    });
  });
}
