import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:result_notifier/result_notifier.dart';

void main() {
  group('ResultBuilder - init', () {
    testWidgets('ResultBuilder.result allows single builder and catch-all', (tester) async {
      expect(
        () => ResultBuilder.result(
          ResultNotifier<String>(data: 'Data'),
          onData: (_, d) => Text(d),
          onResult: (_, r) => Text(r.toString()),
        ),
        returnsNormally,
      );
    });

    testWidgets('ResultBuilder.result throws if all builders and catch-all', (tester) async {
      expect(
          () => ResultBuilder.result(
                ResultNotifier<String>(data: 'Data'),
                onData: (_, d) => Text(d),
                onLoading: (_, d) => Text('Loading - $d'),
                onError: (_, e, st, d) => Text('Error - $d - $e'),
                onResult: (_, r) => Text(r.toString()),
              ),
          throwsAssertionError);
    });
  });

  group('ResultBuilder - build', () {
    testWidgets('ResultBuilder returns correct widget for state', (tester) async {
      final notifier = ResultNotifier<String>(data: 'Data');

      final app = MaterialApp(
        home: ResultBuilder(
          notifier,
          onData: (context, data) => Text(data),
          onError: (context, error, stackTrace, data) => Text('Error - $data - $error'),
          onLoading: (context, data) => Text('Loading - $data'),
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

    testWidgets('ResultBuilder.data returns correct widget for state', (tester) async {
      final notifier = ResultNotifier<String>(data: 'Data');

      final app = MaterialApp(
        home: ResultBuilder.data(
          notifier,
          hasData: (context, data) => Text(data),
          orElse: (context, result) => Text('No data - loading: ${result.isLoading} - error: ${result.error}'),
        ),
      );

      await tester.pumpWidget(app);
      expect(find.text('Data'), findsOneWidget);

      notifier.value = Loading();
      await tester.pumpAndSettle();
      expect(find.text('No data - loading: true - error: null'), findsOneWidget);

      notifier.value = Error(error: 'E');
      await tester.pumpAndSettle();
      expect(find.text('No data - loading: false - error: E'), findsOneWidget);
    });

    testWidgets('ResultBuilder.result returns correct widget for state', (tester) async {
      final notifier = ResultNotifier<String>(data: 'Data');

      final app = MaterialApp(
        home: ResultBuilder.result(
          notifier,
          onData: (context, data) => Text(data),
          onResult: (context, result) => Text('Catch-all - data: ${result.data} - loading: ${result.isLoading} - error: ${result.error}'),
        ),
      );

      await tester.pumpWidget(app);
      expect(find.text('Data'), findsOneWidget);

      notifier.toLoading();
      await tester.pumpAndSettle();
      expect(find.text('Catch-all - data: Data - loading: true - error: null'), findsOneWidget);

      notifier.toError(error: 'E');
      await tester.pumpAndSettle();
      expect(find.text('Catch-all - data: Data - loading: false - error: E'), findsOneWidget);
    });
  });

  group('ValueListenableBuilder', () {
    testWidgets('Returns correct widget for state', (tester) async {
      final notifier = ResultNotifier<String>(data: 'Data');

      final app = MaterialApp(
        home: ValueListenableBuilder(
          valueListenable: notifier,
          builder: (context, result, _) => result.when(
            data: (data) => Text(data),
            error: (error, stackTrace, data) => Text('Error - $data - $error'),
            loading: (data) => Text('Loading - $data'),
          ),
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

  group('ResultNotifierProvider', () {
    testWidgets('Returns correct widget for state', (tester) async {
      late final ResultNotifier<String> notifier;

      final app = MaterialApp(
        home: ResultNotifierProvider(
          create: (context) {
            notifier = ResultNotifier<String>(data: 'Data');
            return notifier;
          },
          resultBuilder: (context, notifier, result) => result.when(
            data: (data) => Text(data),
            error: (error, stackTrace, data) => Text('Error - $data - $error'),
            loading: (data) => Text('Loading - $data'),
          ),
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
