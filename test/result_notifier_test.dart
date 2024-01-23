import 'package:flutter_test/flutter_test.dart';

import 'package:result_notifier/result_notifier.dart';

void main() {
  group('ResultNotifier - states', () {
    test('Initial default states', () {
      final fetcher = Fetcher();
      final notifier = ResultNotifier<String>(onFetch: fetcher.onFetch);
      expect(notifier.isData, false);
      expect(notifier.isStale, true);
      expect(notifier.isLoading, true);
      expect(notifier.isInitial, true);
      expect(fetcher.didFetch, isFalse);
    });

    test('Initial result', () {
      final fetcher = Fetcher();
      final notifier = ResultNotifier<String>(onFetch: fetcher.onFetch, result: Data('data'));
      expect(notifier.isData, true);
      expect(notifier.isStale, false);
      expect(notifier.isLoading, false);
      expect(notifier.isInitial, false);
      expect(fetcher.didFetch, isFalse);
    });

    test('Initial data', () {
      final fetcher = Fetcher();
      final notifier = ResultNotifier<String>(onFetch: fetcher.onFetch, data: 'data');
      expect(notifier.isData, true);
      expect(notifier.isStale, false);
      expect(notifier.isLoading, false);
      expect(notifier.isInitial, false);
      expect(fetcher.didFetch, isFalse);
    });

    test('toData (orElse)', () {
      final fetcher = Fetcher();
      final notifier = ResultNotifier<String>(onFetch: fetcher.onFetch);
      notifier.toData(orElse: () => 'data');
      expect(notifier.isData, true);
      expect(notifier.isStale, false);
      expect(notifier.isLoading, false);
      expect(notifier.isError, false);
      expect(notifier.data, equals('data'));
      notifier.toData(orElse: () => 'data2');
      expect(notifier.data, equals('data'));
      expect(fetcher.didFetch, isFalse);
    });

    test('toLoading', () {
      final fetcher = Fetcher();
      final notifier = ResultNotifier<String>(onFetch: fetcher.onFetch, data: 'data');
      notifier.toLoading();
      expect(notifier.isData, false);
      expect(notifier.isLoading, true);
      expect(notifier.isError, false);
      expect(notifier.data, equals('data'));
      expect(fetcher.didFetch, isFalse);
    });

    test('toError', () {
      final fetcher = Fetcher();
      final notifier = ResultNotifier<String>(onFetch: fetcher.onFetch, data: 'data');
      notifier.toError(error: 'error');
      expect(notifier.isData, false);
      expect(notifier.isLoading, false);
      expect(notifier.isError, true);
      expect(notifier.data, equals('data'));
      expect(fetcher.didFetch, isFalse);
    });

    test('onErrorReturn', () {
      final fetcher = Fetcher();
      final notifier = ResultNotifier<String>(
        onFetch: fetcher.onFetch,
        data: 'data',
        onErrorReturn: (e) => 'Default$e',
      );
      notifier.toError(error: '1');
      expect(notifier.isData, true);
      expect(notifier.isError, false);
      expect(notifier.data, equals('Default1'));

      notifier.value = Error(error: '2');
      expect(notifier.isData, true);
      expect(notifier.isError, false);
      expect(notifier.data, equals('Default2'));

      expect(fetcher.didFetch, isFalse);
    });
  });

  group('ResultNotifier - refresh and fetch', () {
    test('Fetch is NOT invoked upon creation', () {
      final fetcher = Fetcher();
      final notifier = ResultNotifier<String>(onFetch: fetcher.onFetch);
      expect(notifier.value, isA<Initial<String>>());
      expect(fetcher.didFetch, isFalse);
    });

    test('Fetch is NOT invoked for fresh data (if expiration is set)', () {
      final fetcher = Fetcher();
      final notifier = ResultNotifier<String>(
        data: 'test',
        onFetch: fetcher.onFetch,
        expiration: const Duration(seconds: 42),
      );
      expect(notifier.value, isA<Data<String>>());
      notifier.refresh();
      expect(notifier.value, isA<Data<String>>());
      expect(fetcher.didFetch, isFalse);
    });

    test('Fetch is NOT invoked when loading', () {
      final fetcher = Fetcher();
      final notifier = ResultNotifier<String>(data: 'test', onFetch: fetcher.onFetch);
      notifier.toLoading();
      expect(notifier.value, isA<Loading<String>>());
      notifier.refresh();
      expect(notifier.value, isA<Loading<String>>());
      expect(fetcher.didFetch, isFalse);
    });

    test('Fetch IS invoked for fresh data when forced', () {
      final fetcher = Fetcher();
      final notifier = ResultNotifier<String>(data: 'test', onFetch: fetcher.onFetch);
      expect(notifier.value, isA<Data<String>>());
      notifier.refresh(force: true);
      expect(notifier.value, isA<Data<String>>());
      expect(fetcher.didFetch, isTrue);
    });

    test('Fetch IS invoked for stale data', () {
      final fetcher = Fetcher(touch: true);
      final initialData = Data.stale('data');
      final notifier = ResultNotifier<String>(
        result: initialData,
        onFetch: fetcher.onFetch,
        expiration: const Duration(seconds: 1),
      );
      expect(notifier.isStale, true);
      expect(notifier.value, isA<Data<String>>());
      notifier.refresh();
      expect(notifier.value, isA<Data<String>>());
      expect(notifier.value, isNot(equals(initialData)));
      expect(fetcher.didFetch, isTrue);
    });

    test('Fetch IS invoked after data has expired', () async {
      final fetcher = Fetcher(touch: true);
      final initialData = Data('data');
      final notifier = ResultNotifier<String>(
        result: initialData,
        onFetch: fetcher.onFetch,
        expiration: const Duration(milliseconds: 100),
      );
      expect(notifier.isFresh, true);
      expect(notifier.value, isA<Data<String>>());
      await Future.delayed(const Duration(milliseconds: 200));
      expect(notifier.isStale, true);
      notifier.refresh();
      expect(notifier.value, isA<Data<String>>());
      expect(notifier.value, isNot(equals(initialData)));
      expect(fetcher.didFetch, isTrue);
    });

    test('Fetch IS always invoked when there is no cache expiration', () async {
      final fetcher = Fetcher(touch: true);
      final initialData = Data('data');
      final notifier = ResultNotifier<String>(result: initialData, onFetch: fetcher.onFetch);
      expect(notifier.isFresh, true);
      expect(notifier.value, isA<Data<String>>());
      expect(fetcher.didFetch, isFalse);
      notifier.refresh();
      expect(fetcher.didFetch, isTrue);
      expect(notifier.value, isA<Data<String>>());
      expect(notifier.value, isNot(equals(initialData)));
    });
  });

  group('FutureNotifier', () {
    test('Fetch sync', () async {
      bool didFetch = false;
      String fetch(FutureNotifier<String> n) {
        didFetch = true;
        return 'data';
      }

      final notifier = ResultNotifier<String>.future(fetch);
      final result = await notifier.refreshAwait();
      expect(result, equals('data'));
      expect(didFetch, isTrue);
    });

    test('Fetch async', () async {
      final fetcher = AsyncFetcher(id: 'data');
      final notifier = ResultNotifier<String>.future(fetcher.fetch);
      final result = await notifier.refreshAwait();
      expect(result, equals(fetcher.id));
      expect(fetcher.didFetch, isTrue);
    });

    test('Fetch async result', () async {
      final fetcher = AsyncFetcher(id: 'data');
      final notifier = FutureNotifier<String>.result(fetcher.fetchResult);
      final result = await notifier.refreshAwait();
      expect(result, equals(fetcher.id));
      expect(fetcher.didFetch, isTrue);
    });

    test('Fetch is correctly cancelled', () async {
      final fetcher = AsyncFetcher(id: 'data', delayMs: 100);
      final notifier = ResultNotifier<String>.future(fetcher.fetch);
      notifier.refresh();
      await Future.delayed(const Duration(milliseconds: 1)); // Delay a bit to allow fetch to start executing
      notifier.cancel();
      await Future.delayed(const Duration(milliseconds: 50)); // Wait to give time for fetch to finish executing
      expect(notifier.isCancelled, true);
      expect(notifier.isData, false);
      expect(notifier.hasData, false);
      expect(fetcher.didFetch, isTrue);
    });

    test('Fetch is correctly aborted when notifier is disposed', () async {
      final fetcher = AsyncFetcher(id: 'data', delayMs: 100);
      final notifier = ResultNotifier<String>.future(fetcher.fetch);
      notifier.refresh();
      await Future.delayed(const Duration(milliseconds: 1)); // Delay a bit to allow fetch to start executing
      notifier.dispose();
      await Future.delayed(const Duration(milliseconds: 50)); // Wait to give time for fetch to finish executing
      expect(notifier.isActive, false);
      expect(fetcher.didFetch, isTrue);
    });

    test('Fetch after cancellation is performed', () async {
      final List<AsyncFetcher> fetchers = [];
      Future<String> fetch(FutureNotifier<String> n) {
        final fetcher = AsyncFetcher(id: 'data${fetchers.length + 1}', delayMs: fetchers.isEmpty ? 100 : 10);
        fetchers.add(fetcher);
        return fetcher.fetch(n);
      }

      final notifier = ResultNotifier<String>.future(fetch);
      notifier.refresh();
      notifier.cancel();
      final result = await notifier.refreshAwait();
      await Future.delayed(const Duration(milliseconds: 200));
      expect(notifier.isCancelled, false);
      expect(notifier.isData, true);
      expect(result, equals('data2'));
      expect(fetchers.length, equals(2));
      expect(fetchers.map((e) => e.didFetch), equals([true, true]));
    });
  });

  group('StreamNotifier', () {
    test('Fetch streamed data', () async {
      Stream<String> fetch(StreamNotifier<String> n) async* {
        yield 'data1';
        await Future.delayed(const Duration(milliseconds: 50));
        yield 'data2';
      }

      int invokeListenerCount = 0;
      String? lastData;
      void listener(String data) {
        invokeListenerCount++;
        lastData = data;
      }

      final notifier = StreamNotifier(fetch);
      final disposer = notifier.onData(listener);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(lastData, equals('data1'));
      expect(notifier.data, equals('data1'));
      expect(invokeListenerCount, equals(1));

      await Future.delayed(const Duration(milliseconds: 100));

      expect(lastData, equals('data2'));
      expect(notifier.data, equals('data2'));
      expect(invokeListenerCount, equals(2));

      disposer();
    });
  });

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

class Fetcher {
  Fetcher({this.touch = false});
  final bool touch;

  bool didFetch = false;

  void onFetch<T>(ResultNotifier<T> notifier) {
    didFetch = true;
    if (touch) notifier.touch();
  }
}

class AsyncFetcher {
  AsyncFetcher({required this.id, int delayMs = 10}) : delay = Duration(milliseconds: delayMs);
  final String id;
  final Duration delay;
  int fetchCount = 0;
  bool get didFetch => fetchCount > 0;

  Future<String> fetch(FutureNotifier<String> notifier) async {
    fetchCount++;
    await Future.delayed(const Duration(milliseconds: 10));
    if (notifier.isCancelled || !notifier.isActive) throw CancelledException();
    final result = await Future.delayed(delay, () => id);
    if (notifier.isCancelled || !notifier.isActive) throw CancelledException();
    return result;
  }

  Future<Result<String>> fetchResult(FutureNotifier<String> notifier) async {
    fetchCount++;
    await Future.delayed(const Duration(milliseconds: 10));
    if (notifier.isCancelled || !notifier.isActive) throw CancelledException();
    final result = await Future.delayed(delay, () => Data(id));
    if (notifier.isCancelled || !notifier.isActive) throw CancelledException();
    return result;
  }
}
