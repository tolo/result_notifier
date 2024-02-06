import 'package:flutter_test/flutter_test.dart';

import 'package:result_notifier/result_notifier.dart';

void main() {
  group('NotifierStore', () {
    test('Creates ResultNotifier', () async {
      final store = ResultStore<String, String>(create: (key, _) => ResultNotifier<String>(data: 'data$key'));
      String value = store.data('1');
      expect(value, equals('data1'));
      value = store.data('2');
      expect(value, equals('data2'));
      expect(store.length, equals(2));
    });

    test('Caches ResultNotifier', () async {
      int createCount = 0;
      final store = ResultStore<String, String>(
        create: (key, _) {
          createCount++;
          return ResultNotifier<String>(data: 'data$key');
        },
      );
      String value = store.data('1');
      expect(value, equals('data1'));
      value = store.data('1');
      expect(value, equals('data1'));
      expect(createCount, equals(1));
      expect(store.length, equals(1));
    });

    test('Notifies listener', () async {
      int invokeListenerCount = 0;
      void listener() => invokeListenerCount++;
      final store = ResultStore<String, String>(create: (key, _) => ResultNotifier<String>(data: 'data$key'));
      store.addListener(listener);

      expect(store.data('1'), equals('data1'));
      final notifier = store.getNotifier('1');
      notifier.data = 'updated';

      expect(store.data('1'), equals('updated'));
      expect(store.length, equals(1));
      expect(invokeListenerCount, equals(1));
    });

    test('Auto-disposes ResultNotifier', () async {
      void listener() {}
      final store = ResultStore<String, String>(create: (key, _) => ResultNotifier<String>(data: 'data$key'));
      store.addListener(listener);

      final notifier = store.getNotifier('1');
      expect(store.length, equals(1));

      store.removeListener(listener);
      expect(store.length, equals(0));
      expect(notifier.isActive, isFalse);
    });

    test('Auto-disposes stale ResultNotifier', () async {
      int invokeListenerCount = 0;
      void listener() => invokeListenerCount++;
      final store = ResultStore<String, String>(
        create: (key, store) => ResultNotifier<String>(data: 'data$key', expiration: store.autoDisposeTimerInterval),
        autoDisposeTimerInterval: const Duration(milliseconds: 100),
      );
      store.addListener(listener);

      final notifier = store.getNotifier('1');
      expect(store.length, equals(1));
      expect(store.autoDisposeTimer, isNotNull);

      await Future.delayed(const Duration(milliseconds: 200));
      expect(store.length, equals(0));
      expect(notifier.isStale, isTrue);
      expect(store.autoDisposeTimer, isNull);
      expect(invokeListenerCount, equals(1));
    });

    test('OnResult is correctly invoked', () async {
      int invokeListenerCount = 0;
      String? lastKey;
      Result<String>? lastResult;
      void listener(String key, Result<String> result) {
        invokeListenerCount++;
        lastKey = key;
        lastResult = result;
      }

      final store = ResultStore<String, String>(create: (key, store) => ResultNotifier<String>(data: 'data$key'));
      final disposer = store.onResult(listener);

      String data = store.data('1');
      expect(data, equals('data1'));
      expect(store.length, equals(1));
      await Future.delayed(const Duration(milliseconds: 10)); // Wait for listener to be invoked
      expect(lastKey, equals('1'));
      expect(lastResult, isNotNull);
      expect(lastResult!.data, equals('data1'));
      expect(invokeListenerCount, equals(1));

      data = store.data('2');
      expect(data, equals('data2'));
      expect(store.length, equals(2));
      await Future.delayed(const Duration(milliseconds: 10)); // Wait for listener to be invoked
      expect(lastKey, equals('2'));
      expect(lastResult!.data, equals('data2'));
      expect(invokeListenerCount, equals(2));

      disposer();
    });
  });
}
