import 'package:flutter_test/flutter_test.dart';

import 'package:result_notifier/result_notifier.dart';

import 'test_helpers.dart';

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

    test('toData (existing data)', () {
      final fetcher = Fetcher();
      final notifier = ResultNotifier<String>(data: 'data', onFetch: fetcher.onFetch);
      notifier.toLoading();
      expect(notifier.data, equals('data'));
      expect(notifier.isLoading, true);
      notifier.toData();
      expect(notifier.isData, true);
      expect(notifier.isStale, false);
      expect(notifier.isLoading, false);
      expect(notifier.isError, false);
      expect(notifier.data, equals('data'));
      expect(fetcher.didFetch, isFalse);
    });

    test('toData (explicit data)', () {
      final fetcher = Fetcher();
      final notifier = ResultNotifier<String>(onFetch: fetcher.onFetch);
      notifier.toData(data: 'default');
      expect(notifier.isData, true);
      expect(notifier.data, equals('default'));
      notifier.toLoading();
      expect(notifier.data, equals('default'));
      expect(notifier.isLoading, true);
      notifier.toData(data: 'data');
      expect(notifier.isData, true);
      expect(notifier.isStale, false);
      expect(notifier.isLoading, false);
      expect(notifier.isError, false);
      expect(notifier.data, equals('data'));
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

    test('Fetch callback throws error', () async {
      final fetcher = Fetcher(touch: true);
      final notifier = ResultNotifier<String>(onFetch: fetcher.error);
      notifier.refresh();
      expect(notifier.isError, isTrue);
      expect(fetcher.didFetch, isTrue);
    });
  });

  group('FutureNotifier', () {
    test('Fetch sync', () async {
      bool didFetch = false;
      String fetch(ResultNotifier<String> n) {
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

    test('Fetch async error', () async {
      final fetcher = AsyncFetcher(id: 'data');
      final notifier = FutureNotifier<String>.result(fetcher.error);
      String? result;
      try {
        result = await notifier.refreshAwait();
      } catch (e) {
        expect(e, isA<Exception>());
      }
      expect(result, isNull);
      expect(notifier.isError, isTrue);
      expect(fetcher.didFetch, isTrue);
    });

    test('Fetch async report loading', () async {
      final fetcher = AsyncFetcher(id: 'data');
      final notifier = ResultNotifier<String>.future(fetcher.fetch);
      bool didNotifyOnLoading = false;
      final disposer = notifier.onLoading((data) {
        didNotifyOnLoading = true;
      });
      notifier.refresh();
      expect(notifier.isLoading, isTrue); // Loading is reported immediately
      await Future.delayed(const Duration(milliseconds: 10)); // Delay a bit to allow fetch to start executing
      expect(didNotifyOnLoading, isTrue); // Make sure loading was reported to listeners
      final result = await notifier.future;
      expect(result, equals(fetcher.id));
      expect(fetcher.didFetch, isTrue);
      disposer();
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
      Future<String> fetch(ResultNotifier<String> n) {
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

      expect(notifier.isLoading, isTrue);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(lastData, equals('data1'));
      expect(notifier.isData, isTrue);
      expect(notifier.data, equals('data1'));
      expect(invokeListenerCount, equals(1));

      await Future.delayed(const Duration(milliseconds: 100));

      expect(lastData, equals('data2'));
      expect(notifier.isData, isTrue);
      expect(notifier.data, equals('data2'));
      expect(invokeListenerCount, equals(2));

      disposer();
    });

    test('Stream fetch is correctly cancelled', () async {
      Stream<String> fetch(StreamNotifier<String> n) async* {
        yield 'data1';
        await Future.delayed(const Duration(milliseconds: 50));
        yield 'data2';
      }

      final notifier = StreamNotifier(fetch);
      notifier.refresh();
      await Future.delayed(const Duration(milliseconds: 10)); // Delay a bit to allow first stream event to be emitted
      notifier.cancel();
      await Future.delayed(const Duration(milliseconds: 50)); // Wait to give time for fetch to finish executing
      expect(notifier.isCancelled, true);
      expect(notifier.isData, false);
      expect(notifier.hasData, true);
      expect(notifier.data, 'data1'); // First data should be available
    });

    test('Stream fetch is correctly aborted when notifier is disposed', () async {
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
      notifier.refresh();
      await Future.delayed(const Duration(milliseconds: 1)); // Delay a bit to allow fetch to start executing
      notifier.dispose();
      await Future.delayed(const Duration(milliseconds: 50)); // Wait to give time for fetch to finish executing
      expect(notifier.isActive, false);
      expect(invokeListenerCount, equals(1));
      expect(lastData, equals('data1'));
      disposer();
    });
  });

  group('CombineLatestNotifier', () {
    test('Initial combined result is not data', () async {
      final notifier1 = ResultNotifier<String>(data: 'Hello ');
      final notifier2 = ResultNotifier<String>(data: 'World');
      final combined = CombineLatestNotifier<String, String>(
        [notifier1, notifier2],
        combineData: (data) => data[0] + data[1],
      );

      expect(combined.isData, isFalse);
    });

    test('Combine result on refresh', () async {
      final notifier1 = ResultNotifier<String>(data: 'Hello ');
      final notifier2 = ResultNotifier<String>(data: 'World');
      final combined = CombineLatestNotifier<String, String>(
        [notifier1, notifier2],
        combineData: (data) => data[0] + data[1],
      );
      combined.refresh();

      expect(combined.data, equals('Hello World'));
    });

    test('Combine result on source modification', () async {
      final notifier1 = ResultNotifier<String>(data: 'Hello ');
      final notifier2 = ResultNotifier<String>(data: '');
      final combined = CombineLatestNotifier<String, String>(
        [notifier1, notifier2],
        combineData: (data) => data[0] + data[1],
      );
      notifier2.data = 'World';

      expect(combined.data, equals('Hello World'));
    });

    test('Combine different result type', () async {
      final notifier1 = ResultNotifier<int>(data: 4);
      final notifier2 = ResultNotifier<int>(data: 2);
      final combined = CombineLatestNotifier<int, String>(
        [notifier1, notifier2],
        combineData: (data) => '${data[0]}${data[1]}',
      )..refresh();

      expect(combined.data, equals('42'));
    });

    test('Combine updated result', () async {
      final notifier1 = ResultNotifier<String>(data: '');
      final notifier2 = ResultNotifier<String>(data: '');
      final combined = CombineLatestNotifier<String, String>(
        [notifier1, notifier2],
        combineData: (data) => data[0] + data[1],
      )..refresh();

      notifier1.value = Data('Hello ');
      expect(combined.data, equals('Hello '));

      notifier2.value = Data('World');
      expect(combined.data, equals('Hello World'));
    });

    test('Combine loading result', () async {
      final notifier1 = ResultNotifier<String>(data: '');
      final notifier2 = ResultNotifier<String>(data: '');
      final combined = CombineLatestNotifier<String, String>(
        [notifier1, notifier2],
        combineData: (data) => data[0] + data[1],
      )..refresh();

      notifier1.value = Data('Hello ');
      notifier2.value = Data('World');
      expect(combined.data, equals('Hello World'));
      expect(combined.isLoading, isFalse);

      notifier1.toLoading();
      expect(combined.data, equals('Hello World'));
      expect(combined.isLoading, isTrue);
    });

    test('Combine error result', () async {
      final notifier1 = ResultNotifier<String>(data: '');
      final notifier2 = ResultNotifier<String>(data: '');
      final combined = CombineLatestNotifier<String, String>(
        [notifier1, notifier2],
        combineData: (data) => data[0] + data[1],
      )..refresh();

      notifier1.value = Data('Hello ');
      notifier2.value = Data('World');
      expect(combined.data, equals('Hello World'));
      expect(combined.isError, isFalse);

      notifier1.toError(error: 'error');
      expect(combined.data, equals('Hello World'));
      expect(combined.isError, isTrue);
    });

    test('Combine two', () async {
      final notifier1 = ResultNotifier<String>(data: 'A');
      final notifier2 = ResultNotifier<int>(data: 1);
      String combineData(String a, int b) => a + b.toString();

      final combined = CombineLatestNotifier.combine2(notifier1, notifier2, combineData: combineData)..refresh();
      expect(combined.data, equals('A1'));

      // Test the corresponding Record function
      final combined2 = (notifier1, notifier2).combineData(combineData);
      expect(combined2, equals('A1'));
    });

    test('Combine three', () async {
      final notifier1 = ResultNotifier<String>(data: 'A');
      final notifier2 = ResultNotifier<int>(data: 1);
      final notifier3 = ResultNotifier<String>(data: 'B');
      String combineData(String a, int b, String c) => a + b.toString() + c;

      final combined = CombineLatestNotifier.combine3(
        notifier1,
        notifier2,
        notifier3,
        combineData: combineData,
      )..refresh();
      expect(combined.data, equals('A1B'));

      // Test the corresponding Record function
      final combined3 = (notifier1, notifier2, notifier3).combineData(combineData);
      expect(combined3, equals('A1B'));
    });

    test('Combine four', () async {
      final notifier1 = ResultNotifier<String>(data: 'A');
      final notifier2 = ResultNotifier<int>(data: 1);
      final notifier3 = ResultNotifier<String>(data: 'B');
      final notifier4 = ResultNotifier<int>(data: 2);
      String combineData(String a, int b, String c, int d) => a + b.toString() + c + d.toString();

      final combined = CombineLatestNotifier.combine4(
        notifier1,
        notifier2,
        notifier3,
        notifier4,
        combineData: combineData,
      )..refresh();
      expect(combined.data, equals('A1B2'));

      // Test the corresponding Record function
      final combined4 = (notifier1, notifier2, notifier3, notifier4).combineData(combineData);
      expect(combined4, equals('A1B2'));
    });

    test('Combine five', () async {
      final notifier1 = ResultNotifier<String>(data: 'A');
      final notifier2 = ResultNotifier<int>(data: 1);
      final notifier3 = ResultNotifier<String>(data: 'B');
      final notifier4 = ResultNotifier<int>(data: 2);
      final notifier5 = ResultNotifier<String>(data: 'C');
      String combineData(String a, int b, String c, int d, String e) => a + b.toString() + c + d.toString() + e;

      final combined = CombineLatestNotifier.combine5(
        notifier1,
        notifier2,
        notifier3,
        notifier4,
        notifier5,
        combineData: combineData,
      )..refresh();
      expect(combined.data, equals('A1B2C'));

      // Test the corresponding Record function
      final combined5 = (notifier1, notifier2, notifier3, notifier4, notifier5).combineData(combineData);
      expect(combined5, equals('A1B2C'));
    });
  });

  group('EffectNotifier', () {
    test('Simple effect', () async {
      final sourceFetcher = AsyncFetcher(id: 'data');
      final notifier = ResultNotifier<String>.future(sourceFetcher.fetch);
      final effect = notifier.effect((_, input) => input.toUpperCase());
      final result = await effect.refreshAwait();
      expect(result, equals('DATA'));
      expect(sourceFetcher.didFetch, isTrue);
    });

    test('Nested async effect', () async {
      final sourceFetcher = AsyncFetcher(id: 'data');
      final notifier = ResultNotifier<String>.future(sourceFetcher.fetch);
      final effect = notifier.asyncEffect((_, input) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return input.toUpperCase();
      });
      final result = await effect.refreshAwait();
      expect(result, equals('DATA'));
      expect(sourceFetcher.didFetch, isTrue);
    });

    test('Always data effect (sync)', () async {
      final notifier = ResultNotifier<String>();
      final effect = notifier.alwaysData('default');
      expect(effect.data, equals('default'));
      notifier.toLoading();
      expect(effect.isData, isTrue);
      expect(effect.data, equals('default'));
      notifier.toError();
      expect(effect.isData, isTrue);
      expect(effect.data, equals('default'));
      notifier.data = 'updatedData';
      expect(effect.data, equals('updatedData'));
    });

    test('Always data effect (sync)', () async {
      final notifier = ResultNotifier<String>();
      final effect = notifier.alwaysData('default');
      expect(effect.data, equals('default'));
      notifier.toLoading();
      expect(effect.isData, isTrue);
      expect(effect.data, equals('default'));
      notifier.toError();
      expect(effect.isData, isTrue);
      expect(effect.data, equals('default'));
      notifier.data = 'updatedData';
      expect(effect.data, equals('updatedData'));
    });

    test('Stream effect', () async {
      final notifier = ResultNotifier<String>();
      final effect = notifier.streamEffect((notifier, input) async* {
        yield '$input!';
        await Future.delayed(const Duration(milliseconds: 10));
        yield '$input!'.toUpperCase();
      });
      notifier.data = 'default';
      await effect.future;
      expect(effect.data, equals('default!'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(effect.data, equals('DEFAULT!'));
    });
  });

  group('StreamableResultNotifierMixin', () {
    test('To stream', () async {
      final notifier = StreamableNotifier<String>(data: '');
      final List<String> results = [];
      notifier.stream.listen((event) {
        results.add(event.data ?? '-');
      });
      await Future.delayed(const Duration(milliseconds: 1));
      notifier.data = 'Streams ';
      notifier.data = 'are ';
      notifier.data = 'just ';
      notifier.data = 'streamy!';
      await Future.delayed(const Duration(milliseconds: 1));
      expect(results.join(), equals('Streams are just streamy!'));
    });

    test('To dataStream', () async {
      final notifier = StreamableNotifier<String>(data: 'Value');
      final List<String> results = [];
      notifier.dataStream.listen((data) {
        results.add(data);
      });
      await Future.delayed(const Duration(milliseconds: 1));
      notifier.data = 'Streams ';
      notifier.data = 'are ';
      notifier.data = 'just ';
      notifier.data = 'streamy!';
      await Future.delayed(const Duration(milliseconds: 1));
      expect(results.join(), equals('ValueStreams are just streamy!'));
    });
  });

  group('Extensions', () {
    test('ResultNotifier iterable combine', () async {
      final notifier1 = ResultNotifier<String>();
      final notifier2 = ResultNotifier<String>(data: 'World');
      Result<String> result = [notifier1, notifier2].combine((data) => '${data[0]}${data[1]}');
      expect(result.isLoading, isTrue);
      expect(result.data, isNull);

      notifier1.data = 'Hello ';
      result = [notifier1, notifier2].combine((data) => '${data[0]}${data[1]}');
      expect(result.isData, isTrue);
      expect(result.data, equals('Hello World'));

      notifier2.toError();
      result = [notifier1, notifier2].combine((data) => '${data[0]}${data[1]}');
      expect(result.isError, isTrue);
      expect(result.data, equals('Hello World'));

      notifier1.toLoading();
      notifier2.toData();
      result = [notifier1, notifier2].combine((data) => '${data[0]}${data[1]}');
      expect(result.isLoading, isTrue);
      expect(result.data, equals('Hello World'));
    });

    test('ResultNotifier iterable combineData', () async {
      final notifier1 = ResultNotifier<String>();
      final notifier2 = ResultNotifier<String>(data: 'World');
      String? result = [notifier1, notifier2].combineData((data) => '${data[0]}${data[1]}');
      expect(result, isNull);

      notifier1.data = 'Hello ';
      result = [notifier1, notifier2].combineData((data) => '${data[0]}${data[1]}');
      expect(result, equals('Hello World'));

      notifier2.toError();
      result = [notifier1, notifier2].combineData((data) => '${data[0]}${data[1]}');
      expect(result, equals('Hello World'));

      notifier1.toLoading();
      notifier2.toData();
      result = [notifier1, notifier2].combineData((data) => '${data[0]}${data[1]}');
      expect(result, equals('Hello World'));
    });

    test('ResultNotifier result status', () async {
      final notifier1 = ResultNotifier<String>();
      final notifier2 = ResultNotifier<String>(data: 'World');

      expect([notifier1, notifier2].hasData(), isTrue);
      expect([notifier1, notifier2].hasAllData(), isFalse);

      expect([notifier1, notifier2].isLoading(), isTrue);
      expect([notifier1, notifier2].isAllLoading(), isFalse);
      notifier2.toLoading();
      expect([notifier1, notifier2].isAllLoading(), isTrue);

      notifier2.toData();
      expect([notifier1, notifier2].isData(), isTrue);
      expect([notifier1, notifier2].isAllData(), isFalse);
      notifier1.data = 'Hello ';
      expect([notifier1, notifier2].isAllData(), isTrue);

      notifier1.toError();
      expect([notifier1, notifier2].isError(), isTrue);
      expect([notifier1, notifier2].isAllError(), isFalse);
      notifier2.toError();
      expect([notifier1, notifier2].isAllError(), isTrue);

      expect([notifier1, notifier2].hasData(), isTrue);
      expect([notifier1, notifier2].hasAllData(), isTrue);
    });

    test('Result result status', () async {
      final notifier1 = ResultNotifier<String>();
      final notifier2 = ResultNotifier<String>(data: 'World');

      expect([notifier1.result, notifier2.result].hasData(), isTrue);
      expect([notifier1.result, notifier2.result].hasAllData(), isFalse);

      expect([notifier1.result, notifier2.result].isLoading(), isTrue);
      expect([notifier1.result, notifier2.result].isAllLoading(), isFalse);
      notifier2.toLoading();
      expect([notifier1.result, notifier2.result].isAllLoading(), isTrue);

      notifier2.toData();
      expect([notifier1.result, notifier2.result].isData(), isTrue);
      expect([notifier1.result, notifier2.result].isAllData(), isFalse);
      notifier1.data = 'Hello ';
      expect([notifier1.result, notifier2.result].isAllData(), isTrue);

      notifier1.toError();
      expect([notifier1.result, notifier2.result].isError(), isTrue);
      expect([notifier1.result, notifier2.result].isAllError(), isFalse);
      notifier2.toError();
      expect([notifier1.result, notifier2.result].isAllError(), isTrue);

      expect([notifier1.result, notifier2.result].hasData(), isTrue);
      expect([notifier1.result, notifier2.result].hasAllData(), isTrue);
    });
  });
}
