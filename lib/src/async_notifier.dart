import 'dart:async';

import 'exceptions.dart';
import 'result.dart';
import 'result_notifier.dart';

/// Signature for functions that fetches data asynchronously for an [FutureNotifier].
typedef FetchAsync<T> = FutureOr<T> Function(FutureNotifier<T>);

/// Signature for functions that fetches data asynchronously for an [FutureNotifier], and returns a [Result].
///
/// Use this fetcher function with the [FutureNotifier.result] constructor, when you need to control the result type in
/// the fetch operation.
typedef FetchResultAsync<T> = FutureOr<Result<T>> Function(FutureNotifier<T>);

/// ResultNotifier subclass that supports fetching data asynchronously, on demand.
///
/// {@template future_notifier}
/// Data will be fetched using the configured [FetchAsync] function, when a refresh needed (see [refresh]). The fetch
/// function will be invoked in an asynchronous fashion, using [setDataAsync], meaning its result will be awaited.
/// The fetch function can either return a [Future] that completes with data, or return the data directly. Errors will
/// be caught and converted to [Error] states.
///
/// A common use case is to for instance fetch data from a remote HTTP API, and then cache the result for a period of
/// time. Example:
///
/// ```
/// final notifier = FutureNotifier(() async {
///   final response = await http.get(uri);
///   final json = jsonDecode(response.body) as Map<String, dynamic>;
///   return SomeModel.fromJson(json);
/// }, expiration: const Duration(seconds: 30));
/// ```
/// {@endtemplate}
class FutureNotifier<T> extends ResultNotifier<T> {
  /// Creates a FutureNotifier that fetches new data using the provided `fetch` function.
  ///
  /// {@macro result_notifier.constructor}
  FutureNotifier(
    FetchAsync<T> fetch, {
    super.data,
    super.result,
    super.expiration,
    super.onReset,
    super.onErrorReturn,
    super.autoReset,
    super.refreshOnError,
  }) : super(onFetch: _onFetch(fetch));

  /// Creates a FutureNotifier that fetches new data using the provided `fetch` function.
  ///
  /// {@macro result_notifier.constructor}
  FutureNotifier.result(
    FetchResultAsync<T> fetch, {
    super.data,
    super.result,
    super.expiration,
    super.onReset,
    super.onErrorReturn,
    super.autoReset,
    super.refreshOnError,
  }) : super(onFetch: _onFetchResult(fetch));

  static void Function(ResultNotifier<T>) _onFetch<T>(FetchAsync<T> fetch) {
    FutureOr<Result<T>> fetchResult(FutureNotifier<T> not) async => Data(await fetch(not));
    return (not) => (not as FutureNotifier<T>)._performFetch(fetchResult);
  }

  static void Function(ResultNotifier<T>) _onFetchResult<T>(FetchResultAsync<T> fetch) {
    return (not) => (not as FutureNotifier<T>)._performFetch(fetch);
  }

  Object? _currentFetch;

  @override
  void cancel({Result<T>? result, bool always = false}) {
    _currentFetch = null;
    super.cancel(result: result, always: always);
  }

  void _performFetch(FetchResultAsync<T> fetch) {
    FutureOr<Result<T>> performFetch() async {
      late final currentFetch = _currentFetch;
      final result = await fetch(this);
      if (currentFetch == _currentFetch) {
        return result;
      } else {
        throw CancelledException();
      }
    }

    _currentFetch = Object();
    setResultAsyncIgnore(() => performFetch());
  }
}

/// Signature for functions that fetches streaming data for a [StreamNotifier].
typedef FetchStream<T> = Stream<T> Function(StreamNotifier<T>);

/// Signature for functions that fetches streaming [Result]s for a [StreamNotifier].
///
/// Use this fetcher function with the [StreamNotifier.result] constructor, when you need to control the result type in
/// the fetch operation.
typedef FetchResultStream<T> = Stream<Result<T>> Function(StreamNotifier<T>);

/// ResultNotifier subclass that supports fetching streaming data.
class StreamNotifier<T> extends ResultNotifier<T> {
  // TODO: Needs tests
  /// Creates a StreamNotifier that uses the provided `fetch` function to fetch a Stream of data on each refresh.
  ///
  /// The fetched Stream will be subscribed to on each fetch, after unsubscribing from any previous Stream. Each data or
  /// error event will then be passed to this notifier.
  ///
  /// {@macro result_notifier.constructor}
  StreamNotifier(
    FetchStream<T> fetch, {
    super.data,
    super.result,
    super.expiration,
    super.onReset,
    super.onErrorReturn,
  }) : super(onFetch: _onFetch(fetch));

  /// Creates a StreamNotifier that uses the provided `fetch` function to fetch a Stream of [Result]s on each refresh.
  ///
  /// The fetched Stream will be subscribed to on each fetch, after unsubscribing from any previous Stream. Each data or
  /// error event will then be passed to this notifier.
  ///
  /// {@macro result_notifier.constructor}
  StreamNotifier.result(
    FetchResultStream<T> fetch, {
    super.data,
    super.result,
    super.expiration,
    super.onReset,
    super.onErrorReturn,
  }) : super(onFetch: _onFetchResult(fetch));

  static void Function(ResultNotifier<T>) _onFetch<T>(FetchStream<T> fetch) {
    Stream<Result<T>> fetchResult(StreamNotifier<T> not) => fetch(not).map((event) => Data(event));
    return (not) => (not as StreamNotifier<T>)._performFetch(fetchResult);
  }

  static void Function(ResultNotifier<T>) _onFetchResult<T>(FetchResultStream<T> fetch) {
    return (not) => (not as StreamNotifier<T>)._performFetch(fetch);
  }

  StreamSubscription? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  void cancel({Result<T>? result, bool always = false}) {
    _subscription?.cancel();
    _subscription = null;
    super.cancel(result: result, always: always);
  }

  void _performFetch(FetchResultStream<T> fetch) {
    _subscription?.cancel();
    late final StreamSubscription<Result<T>> sub; // ignore: cancel_subscriptions
    sub = fetch(this).listen(
      (data) {
        if (sub == _subscription) setResultAsyncIgnore(() => data);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (sub == _subscription) {
          setResultAsyncIgnore(() => Future<Result<T>>.error(error, stackTrace));
        }
      },
    );
    _subscription = sub;
  }
}

extension _ResultNotifierAsyncExtension<T> on ResultNotifier<T> {
  Future<void> setResultAsyncIgnore(FutureOr<Result<T>> Function() fetch) async {
    try {
      await setResultAsync(fetch);
    } catch (e) {/* Ignoring */}
  }
}
