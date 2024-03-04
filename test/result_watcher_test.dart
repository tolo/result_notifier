import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:result_notifier/result_notifier.dart';

void main() {
  group('Watcher', () {
    testWidgets('Watcher returns correct widget for state', (tester) async {
      final notifier = ResultNotifier<String>(data: 'Data');

      final app = MaterialApp(
        home: Watcher(builder: (ref) {
          final result = notifier.watch(ref);
          return Text(result.when(
            data: (data) => data,
            loading: (data) => 'Loading - $data',
            error: (error, _, data) => 'Error - $data - $error',
          ));
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

    testWidgets('Multiple watches results in single subscription', (tester) async {
      final not = TestNotifier('1');
      final shouldWatch = ValueNotifier(true);

      final app = MaterialApp(
        home: ValueListenableBuilder(
            valueListenable: shouldWatch,
            builder: (_, shouldWatch, __) {
              if (shouldWatch) {
                return Watcher(builder: (ref) {
                  not.watch(ref);
                  final result = not.watch(ref);
                  return Text(result);
                });
              } else {
                return const Text('crickets');
              }
            }),
      );

      await tester.pumpWidget(app);
      expect(find.text('1'), findsOneWidget);
      expect(not.listenersCount, equals(1));

      shouldWatch.value = false;
      await tester.pumpAndSettle();
      expect(find.text('crickets'), findsOneWidget);
      expect(not.listenersCount, equals(0));
    });

    testWidgets('Watcher returns correct widget for multiple notifiers', (tester) async {
      final message = ResultNotifier<String>();
      final counter = ResultNotifier<int>(data: 0);

      final app = MaterialApp(
        home: Watcher(builder: (ref) {
          final result1 = message.watch(ref);
          final result2 = counter.watch(ref);

          if ([result1, result2].isError()) {
            return const Text('Error');
          } else {
            final combined = (result1, result2).combineData((a, b) => '$a$b');
            return Text(combined ?? 'Loading');
          }
        }),
      );

      await tester.pumpWidget(app);
      expect(find.text('Loading'), findsOneWidget);

      message.data = 'counter:';
      await tester.pumpAndSettle();
      expect(find.text('counter:0'), findsOneWidget);

      counter.data = 1;
      await tester.pumpAndSettle();
      expect(find.text('counter:1'), findsOneWidget);

      message.toError(error: 'E');
      await tester.pumpAndSettle();
      expect(find.text('Error'), findsOneWidget);
    });

    testWidgets('Watcher removes listener when Listenable is no longer watched', (tester) async {
      final notA = TestNotifier('1');
      final notB = TestNotifier('1');
      bool listenA = true;
      bool listenB = true;
      int buildCount = 0;

      final app = MaterialApp(
        home: Watcher(builder: (ref) {
          buildCount++;
          String result = 'Result:';
          result += listenA ? notA.watch(ref) : '-';
          result += listenB ? notB.watch(ref) : '-';
          return Text(result);
        }),
      );

      await tester.pumpWidget(app);
      expect(find.text('Result:11'), findsOneWidget);
      expect(notA.gotListeners, isTrue);
      expect(notB.gotListeners, isTrue);

      notA.value = '2';
      await tester.pumpAndSettle();
      expect(find.text('Result:21'), findsOneWidget);

      notB.value = '2';
      await tester.pumpAndSettle();
      expect(find.text('Result:22'), findsOneWidget);

      listenA = false;
      notB.value = '3';
      await tester.pumpAndSettle();
      expect(find.text('Result:-3'), findsOneWidget);
      expect(notA.gotListeners, isFalse);
      expect(notB.gotListeners, isTrue);

      listenB = false;
      notB.value = 'this value will not be used'; // Just to trigger rebuild
      await tester.pumpAndSettle();
      expect(find.text('Result:--'), findsOneWidget);
      expect(notA.gotListeners, isFalse);
      expect(notB.gotListeners, isFalse);

      final last = buildCount;
      // Should not trigger a rebuild
      notA.value = '';
      notB.value = '';
      await tester.pumpAndSettle();
      expect(buildCount, equals(last));
    });

    testWidgets('Watcher removes listeners when disposed', (tester) async {
      final notA = TestNotifier('1');
      final notB = TestNotifier('1');
      final shouldWatch = ValueNotifier(true);

      final app = MaterialApp(
        home: ValueListenableBuilder(
            valueListenable: shouldWatch,
            builder: (_, shouldWatch, __) {
              if (shouldWatch) {
                return Watcher(builder: (ref) {
                  String result = 'Result:';
                  result += notA.watch(ref);
                  result += notB.watch(ref);
                  return Text(result);
                });
              } else {
                return const Text('crickets');
              }
            }),
      );

      await tester.pumpWidget(app);
      expect(find.text('Result:11'), findsOneWidget);
      expect(notA.gotListeners, isTrue);
      expect(notB.gotListeners, isTrue);

      notA.value = '2';
      await tester.pumpAndSettle();
      expect(find.text('Result:21'), findsOneWidget);

      shouldWatch.value = false;
      await tester.pumpAndSettle();
      expect(find.text('crickets'), findsOneWidget);
      expect(notA.gotListeners, isFalse);
      expect(notB.gotListeners, isFalse);
    });

    testWidgets('Watch must be performed in build of Watcher/WatcherMixin', (tester) async {
      final not = TestNotifier('1');

      final app = MaterialApp(
        home: Watcher(builder: (ref) {
          return Builder(builder: (_) {
            try {
              final result = not.watch(ref);
              return Text(result);
            }
            // ignore: avoid_catching_errors
            on AssertionError catch (_) {
              return const Text('AssertionError');
            }
          });
        }),
      );

      await tester.pumpWidget(app);
      expect(find.text('AssertionError'), findsOneWidget);
    });
  });
}

class TestNotifier<T> extends ValueNotifier<T> {
  TestNotifier(super.value);

  int listenersCount = 0;
  bool get gotListeners => hasListeners;

  @override
  void addListener(VoidCallback listener) {
    listenersCount++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listenersCount--;
    super.removeListener(listener);
  }
}
