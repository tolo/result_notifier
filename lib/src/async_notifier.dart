import 'dart:async';

import 'package:flutter/cupertino.dart';

import 'result.dart';
import 'result_notifier.dart';

/// Signature for functions that fetches data asynchronously for an [FutureNotifier].
typedef FetchAsync<T> = FutureOr<T> Function(ResultNotifier<T> notifier);

/// Signature for functions that fetches data asynchronously for an [FutureNotifier], and returns a [Result].
///
/// Use this fetcher function with the [FutureNotifier.result] constructor, when you need to control the result type in
/// the fetch operation.
typedef FetchResultAsync<T> = FutureOr<Result<T>> Function(ResultNotifier<T> notifier);

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

  /// Creates a FutureNotifier that implements customized fetching behavior, possibly by using [performFetch].
  ///
  /// Note: this constructor is primarily provided for subclasses.
  ///
  /// {@macro result_notifier.constructor}
  FutureNotifier.customFetch({
    super.data,
    super.result,
    super.expiration,
    super.onFetch,
    super.onReset,
    super.onErrorReturn,
    super.autoReset,
    super.refreshOnError,
  });

  static void Function(ResultNotifier<T>) _onFetch<T>(FetchAsync<T> fetch) {
    FutureOr<Result<T>> fetchResult(ResultNotifier<T> not) async => Data(await fetch(not));
    return (not) => (not as FutureNotifier<T>).performFetch(fetchResult);
  }

  static void Function(ResultNotifier<T>) _onFetchResult<T>(FetchResultAsync<T> fetch) {
    return (not) => (not as FutureNotifier<T>).performFetch(fetch);
  }

  /// Fetches data asynchronously using the provided `fetcher` function.
  ///
  /// This method is used when setting up [onFetch] for FutureNotifier, and is invoked by [refresh]. It should normally
  /// not be invoked directly.
  @protected
  void performFetch(FetchResultAsync<T> fetch) {
    setResultAsync(() => fetch(this)).ignore();
  }
}

/// Signature for functions that fetches streaming data for a [StreamNotifier].
typedef FetchStream<T> = Stream<T> Function(StreamNotifier<T> notifier);

/// Signature for functions that fetches streaming [Result]s for a [StreamNotifier].
///
/// Use this fetcher function with the [StreamNotifier.result] constructor, when you need to control the result type in
/// the fetch operation.
typedef FetchResultStream<T> = Stream<Result<T>> Function(StreamNotifier<T> notifier);

/// ResultNotifier subclass that supports fetching streaming data.
///
/// Whenever a refresh is needed (see [refresh]), the fetch function will be invoked to fetch a new Stream of data. The
/// notifier will then subscribe to that Stream and update its value whenever new data or errors are emitted.
class StreamNotifier<T> extends ResultNotifier<T> {
  // TODO: Better docs.

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

  /// Creates a StreamNotifier that implements customized fetching behavior, possibly by using [performFetch].
  ///
  /// Note: this constructor is primarily provided for subclasses.
  ///
  /// {@macro result_notifier.constructor}
  StreamNotifier.customFetch({
    super.data,
    super.result,
    super.expiration,
    super.onFetch,
    super.onReset,
    super.onErrorReturn,
    super.autoReset,
    super.refreshOnError,
  });

  static void Function(ResultNotifier<T>) _onFetch<T>(FetchStream<T> fetch) {
    Stream<Result<T>> fetchResult(StreamNotifier<T> not) => fetch(not).map((event) => Data(event));
    return (not) => (not as StreamNotifier<T>).performFetch(fetchResult);
  }

  static void Function(ResultNotifier<T>) _onFetchResult<T>(FetchResultStream<T> fetch) {
    return (not) => (not as StreamNotifier<T>).performFetch(fetch);
  }

  StreamSubscription? _subscription;

  @override
  void dispose() {
    final subscription = _subscription;
    _subscription = null;
    subscription?.cancel();
    super.dispose();
  }

  @override
  void cancel({bool always = false}) {
    final subscription = _subscription;
    _subscription = null;
    subscription?.cancel();
    super.cancel(always: (subscription != null) || always);
  }

  /// Fetches data asynchronously by subscribing to the Stream returned by the `fetch` function. If any existing stream
  /// subscription is active, it will be cancelled before subscribing to the new stream. Each data or error event will
  /// then be passed to this notifier. Before subsribing to the new stream, the notifier will be set to [Loading].
  ///
  /// This method is used when setting up [onFetch] for StreamNotifier, and is invoked by [refresh]. It should normally
  /// not be invoked directly.
  @protected
  void performFetch(FetchResultStream<T> fetch) {
    _subscription?.cancel();
    toLoading();

    late final StreamSubscription<Result<T>> sub; // ignore: cancel_subscriptions
    sub = fetch(this).listen(
      (streamResult) {
        if (sub == _subscription && isActive) {
          value = streamResult;
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (sub == _subscription && isActive) {
          toError(error: error, stackTrace: stackTrace);
        }
      },
    );
    _subscription = sub;
  }
}
