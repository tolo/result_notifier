import 'dart:async';
import 'dart:core';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

import 'async_notifier.dart';
import 'exceptions.dart';
import 'result.dart';
import 'result_listenable.dart';
export 'result_listenable.dart';

/// Signature for callback functions used by [ResultNotifier].
typedef ResultNotifierCallback<T> = void Function(ResultNotifier<T> notifier);

/// [ValueListenable] implementation that holds a single [Result] value, supporting data, loading and error states.
///
/// ResultNotifier supports well-defined transitions between the different [Result] states, including support for
/// fine-grained observation of the different states.
///
/// ResultNotifier also supports refreshing data when stale. The staleness is determined by the [expiration] property
/// (see [isFresh] / [isStale]) along with the [Result.lastUpdate] property. This creates the underpinning for a
/// refreshable caching mechanism, where the data can be re-fetched when stale. Whenever data needs to be fetched, the
/// optional [onFetch] callback will be invoked. If not provided, the default implementation will only [touch] the
/// current value to refresh it. If customization of data fetch is needed, consider using a ResultNotifier subclass such
/// as for instance [FutureNotifier] (see [ResultNotifier.future]), or provide a implementation of `onFetch` that
/// refreshes the data in some other manner.
///
/// Data fetch will occur automatically, on demand, whenever a listener is added (see [addListener]), It can
/// additionally be triggered manually by invoking the [refresh]. A fetch will be performed whenever:
/// * Data has not yet been fetched (i.e. the notifier is in the [Initial] state).
/// * Data is stale ([isStale]).
/// * The [refresh] method is called with `force` set to true.
///
/// To cancel an ongoing data fetch operation, use [cancel]. This also invokes the [onReset] callback, if specified.
class ResultNotifier<T> extends ChangeNotifier with ResultListenable<T> {
  /// Starts with the specified `data` (represented as [Data]), `result`, or otherwise the [Initial] loading state.
  ///
  /// {@template result_notifier.constructor}
  /// If [expiration] (i.e. cache expiration) is specified, the data will be considered stale after the specified
  /// duration has elapsed since the last update, meaning [isFresh] will return false.
  ///
  /// Optionally provide callbacks for `onFetch` and `onReset`, which are called when fetch ([refresh]) or [reset]
  /// (and also cancellation and disposal) occurs.
  ///
  /// If [onErrorReturn] is specified, the specified value will be returned as data when an error occurs, meaning this
  /// ResultNotifier will never be able to enter the [Error] state.
  ///
  /// If `autoReset` ([willAutoReset]) is true, this notifier will automatically [reset] itself when all listeners are
  /// removed.
  ///
  /// If `refreshOnError` ([willRefreshOnError]) is true, the [refresh] method will fetch new data when the current
  /// state is [Error].
  /// {@endtemplate}
  ResultNotifier({
    T? data,
    Result<T>? result,
    this.expiration,
    this.onFetch,
    this.onReset,
    this.onErrorReturn,
    bool autoReset = false,
    bool refreshOnError = false,
  })  : willAutoReset = autoReset,
        willRefreshOnError = refreshOnError,
        _value = data != null ? Data(data: data) : result ?? Initial<T>();

  /// Creates a [FutureNotifier] that fetches data asynchronously, when needed.
  ///
  /// Data is fetched using the provided `fetch` function, which can either return a [Future] that completes data,
  /// or return the data directly (synchronously). Any errors will be caught and converted to [Error] states.
  ///
  /// {@macro result_notifier.constructor}
  factory ResultNotifier.future(
    FetchAsync<T> fetch, {
    T? data,
    Result<T>? result,
    Duration? expiration,
    ResultNotifierCallback<T>? onReset,
    T Function(Object? error)? onErrorReturn,
    bool autoReset = false,
    bool refreshOnError = false,
  }) {
    return FutureNotifier<T>(
      fetch,
      data: data,
      result: result,
      expiration: expiration,
      onReset: onReset,
      onErrorReturn: onErrorReturn,
      autoReset: autoReset,
      refreshOnError: refreshOnError,
    );
  }

  /// Checks if this notifier is still active, i.e. not disposed.
  bool get isActive => _active;
  bool _active = true;

  // Properties

  /// Callback invoked when data needs to be fetched.
  final ResultNotifierCallback<T>? onFetch;

  /// Callback invoked when this notifier is reset, cancelled or disposed.
  ///
  /// Use [isCancelled] to check if the the reason of the reset was cancellation, or [isActive] to check if the notifier
  /// was reset due to disposal.
  final ResultNotifierCallback<T>? onReset;

  /// Callback invoked when an error occurs, to produce fallback data.
  ///
  /// If this callback is specified, this ResultNotifier will never be able to enter the [Error] state.
  final T Function(Object? error)? onErrorReturn;

  /// Cache expiration time. If null, the cache will never expire.
  final Duration? expiration;

  /// If true, this notifier will automatically [reset] itself when all listeners are removed.
  ///
  /// Default is false.
  final bool willAutoReset;

  /// If true, the [refresh] method will fetch new data when the current state is [Error].
  ///
  /// Default is false.
  final bool willRefreshOnError;

  // Get/set data

  /// The current [Result] stored in this notifier.
  ///
  /// When the value is replaced with something that is not equal to the old
  /// value as evaluated by the equality operator ==, this class notifies its
  /// listeners.
  @override
  Result<T> get value => _value;
  Result<T> _value;
  set value(Result<T> newValue) {
    if (_value == newValue) {
      return;
    } else if (newValue.isError && onErrorReturn != null) {
      _value = value.toData(data: onErrorReturn!(newValue.error));
    } else {
      _value = newValue;
    }
    notifyListeners();
  }

  /// Attempts to get the [Result.data] of the current Result [value].
  ///
  /// If no data is available in the current Result, the [onErrorReturn] callback, if specified, will be
  /// invoked to produce fallback data. Otherwise a [NoDataException] will be thrown.
  T get data {
    if (value.hasData) {
      return value.data!;
    } else if (onErrorReturn != null) {
      return onErrorReturn!(NoDataException());
    } else {
      throw NoDataException();
    }
  }

  /// Set the [value] of this notifier as a [Data] Result, containing the specified data.
  set data(T newValue) => value = Data(data: newValue);

  /// Get the [Result.data] of the current Result [value], or null if no data is available (i.e. [hasData] is false).
  T? get dataOrNull => value.data;

  Object? get error => value.error;
  StackTrace? get stackTrace => value is Error ? (value as Error).stackTrace : null;

  /// If data or error is available, it will be returned directly (as [Future.value] / [Future.error]), otherwise a
  /// [Completer] will be used to await data or error.
  Future<T> get future {
    if (isData) {
      return Future.value(data);
    } else if (isError) {
      return Future.error((value as Error).error, (value as Error).stackTrace);
    } else {
      return _addCompleter(Completer<T>()).future;
    }
  }

  /// Sets the [value] to [Data] result, containing the data returned by the provided [Future].
  ///
  /// See also:
  /// - [setDataAsync] which is used to set the new value.
  set future(Future<T> future) {
    setDataAsync(() => future).ignore();
  }

  // Computed/read-only properties

  /// Returns `true` if no [expiration] has been set, meaning the cache will never expire.
  bool get isAlwaysFresh => expiration == null;

  /// Checks if the current data is fresh, not stale, i.e. time since last update is less than [expiration] (if set).
  bool get isFresh => isData && (expiration == null || _timeSinceLastUpdate < expiration!);

  /// Returns true if the current data isn't fresh or if the current result isn't [Data].
  bool get isStale => !isFresh;

  Duration get _timeSinceLastUpdate => DateTime.now().difference(lastUpdate);

  // Lifecycle

  /// Adds a listener to this notifier and triggers an asynchronous refreshes the data, if necessary.
  ///
  /// Data will only be refreshed by this method if it hasn't been loaded yet (i.e. [isInitial]).
  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    Future.microtask(() {
      if (_active && isInitial) refresh();
    });
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    _autoReset();
  }

  @override
  void dispose() {
    _active = false;
    onReset?.call(this);
    super.dispose();
  }

  void _autoReset() {
    if (willAutoReset && !hasListeners) reset();
  }

  // Data refresh

  /// Cancels the current data loading operation, if any.
  ///
  /// If (and only if) the current state is [Loading] (i.e. [isLoading]), the refresh operation is cancelled by setting
  /// the value to [Error.cancelled]. If specified, the [onReset] function will also be invoked.
  ///
  /// If [always] is true, cancellation will happen regardless of the current state.
  void cancel({bool always = false}) {
    if (isLoading || always) {
      value = value.toCancelled();
      onReset?.call(this);
    }
  }

  /// Refreshes this notifier with fresh [Data] if it is stale or forced.
  ///
  /// Data is updated using the [onFetch] function. This function will be called in these conditions:
  /// * Data haven't been fetched yet (i.e. the notifier is in the [Initial] state).
  /// * No [expiration] has been set (i.e. cache never expires).
  /// * Data is stale ([isStale]) and not already loading (i.e. [isLoading] is false).
  /// * The current state is [Error] (but not cancelled) and [willRefreshOnError] is true.
  /// * Fetch is forced (i.e. [force] is true).
  ///
  /// The [refresh] method is normally invoked automatically when a listener is added (see [addListener]), but it can
  /// also be invoked manually to request or force a refresh.
  ///
  /// If [alwaysTouch] if true, the result will be [touch]ed (meaning listeners will be notified) even if the data
  /// is not stale or refresh is forced.
  void refresh({bool force = false, bool alwaysTouch = false}) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    if (!force && // Skip fetch if not forced and...
        (isFresh && !isAlwaysFresh || // ...data is still fresh (and can expire) - or...
            isError &&
                !isCancelled &&
                !willRefreshOnError || // ...an error occurred, but refresh shouldn't be performed for errors - or...
            isLoading && !isInitial)) // ... already loading (but not Initial)
    {
      if (alwaysTouch) touch();
      return;
    }

    try {
      fetchData();
    } catch (error, stackTrace) {
      toError(error: error, stackTrace: stackTrace);
    }
  }

  /// Called to fetch new data.
  ///
  /// This implementation simply delegates to the configured [onFetch] callback, if set, otherwise [touch] will be
  /// called to refresh the value.
  ///
  /// Note: this method is provided for subclass customization and should not be called directly.
  @protected
  void fetchData() {
    if (onFetch != null) {
      onFetch?.call(this);
    } else {
      touch();
    }
  }

  /// Refreshes this notifier with fresh [Data] if it is stale or forced, and awaits data or error.
  ///
  /// Note: This implementation will only [touch] the result if it is stale or forced. If data is available, it will be
  /// returned directly, otherwise a [Completer] will be used to await data or error.
  ///
  /// If [alwaysTouch] if true, the result will be [touch]ed (meaning listeners will be notified) even if the data
  /// is not stale or refresh is forced.
  ///
  /// Returns a [Future] that completes with the new data or error.
  ///
  /// See also:
  /// - [future] which returns a [Future] that completes with the current data or error.
  @useResult
  Future<T> refreshAwait({bool force = false, bool alwaysTouch = false}) {
    refresh(force: force, alwaysTouch: alwaysTouch);
    return future;
  }

  Completer<T> _addCompleter(Completer<T> completer) {
    VoidCallback? disposable;
    void completerResult(Result<T> result) {
      if (result.isData || result.isError) {
        result.isData
            ? completer.complete(result.data)
            : completer.completeError((result as Error<T>).error, result.stackTrace);
        disposable?.call();
      }
    }

    disposable = onResult(completerResult);
    return completer;
  }

  // Result mutation

  /// Resets the result to [Initial], or to stale [Data] if [initialData] is specified.
  void reset([T? initialData]) {
    value = initialData != null ? Data.stale(initialData) : Initial();
    onReset?.call(this);
  }

  /// Attempts to convert the result to fresh [Data] (i.e. set the lastUpdate to `DateTime.now()`), preventing cache
  /// expiration.
  ///
  /// If the current result is not Data, the existing result is kept and returned.
  Result<T> touch() => value = value.toFresh();

  /// Marks the current [Data] (if any) as stale, i.e. it will be re-fetched on next access.
  Result<T> invalidate() => value = value.toStale();

  /// {@macro result.toData}
  Result<T> toData({T? data, T Function()? orElse, DateTime? lastUpdate}) {
    return value = value.toData(data: data, orElse: orElse, lastUpdate: lastUpdate);
  }

  /// {@macro result.toLoading}
  Result<T> toLoading({T? data, DateTime? lastUpdate}) => value = value.toLoading(data: data, lastUpdate: lastUpdate);

  /// {@macro result.toInitial}
  Result<T> toInitial({T? data, DateTime? lastUpdate}) => value = value.toInitial(data: data, lastUpdate: lastUpdate);

  /// {@macro result.toError}
  Result<T> toError({Object? error, StackTrace? stackTrace, T? data, DateTime? lastUpdate}) =>
      value = value.toError(error: error, stackTrace: stackTrace, data: data, lastUpdate: lastUpdate);

  /// {@macro result.toCancelled}
  Result<T> toCancelled({T? data, DateTime? lastUpdate}) =>
      value = value.toCancelled(data: data, lastUpdate: lastUpdate);

  // Async result mutation

  /// Sets the data of this notifier asynchronously using the data returned by the provided function, which in turn is
  /// returned by this method (in form of a Future).
  ///
  /// Remember to always handle the `Future` returned by this method. If a return value is not needed, consider using
  /// [updateDataAsync] instead.
  ///
  /// Before executing the provided function, the current state will be set to [Loading]. When the function returns, the
  /// [value] will be set to [Data] if successful, or [Error] if an error occurs (i.e. if the function throws an
  /// exception). If this notifier was cancelled during the asynchronous gap, the result of the function call will be
  /// ignored and an ([Future.error]) will be returned by this method (i.e. [CancelledException]).
  Future<T> setDataAsync(FutureOr<T> Function() fetchData) async {
    return setResultAsync(() async => Data(data: await fetchData()))
        .then((r) => r.isError ? throw (r as Error).error : r.data!);
  }

  /// Updates the data of this notifier asynchronously using the data returned by the provided function, and then
  /// returns a `Future` that can optionally be used to await the completion of the update.
  ///
  /// Before executing the provided function, the current state will be set to [Loading]. When the function returns, the
  /// [value] will be set to [Data] if successful, or [Error] if an error occurs (i.e. if the function throws an
  /// exception). If this notifier was cancelled during the asynchronous gap, the result of the function call will be
  /// ignored and an ([Future.error]) will be returned by this method (i.e. [CancelledException]).
  ///
  /// Note that the returned `Future` will never complete with an error.
  ///
  /// Instead of using the Future returned by this method, consider using [future] instead, which will await the next
  /// successful data or error result of this notifier.
  Future<void> updateDataAsync(FutureOr<T> Function() fetchData) async {
    await setResultAsync(() async => Data(data: await fetchData()));
  }

  /// Sets the [value] (result) of this notifier asynchronously using the result returned by the provided function.
  ///
  /// Before executing the provided function, the current state will be set to [Loading]. The [result] will then be set
  /// to the return value of the function call, if successful, or [Error] if an error occurs (i.e. if the function
  /// throws an exception). If this notifier was cancelled during the asynchronous gap, the result of [fetch] will be
  /// ignored and an [Error] will be returned by this method (i.e. [Error.cancelled]).
  ///
  /// Note that the Future returned by this method will always complete with a value, never an error. If an error
  /// occurs, it will be represented as an [Error] result.
  ///
  /// The return value of this method is the current [value] (result) after executing the provided function. Instead of
  /// using this, consider using [future] instead, which will await the next successful data or error result of this
  /// notifier.
  Future<Result<T>> setResultAsync(FutureOr<Result<T>> Function() fetchResult) async {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    toLoading(); // Important to always create a new Loading value, to indicate a new loading operation has started

    final previousResult = value;
    Result<T>? abortIfDisposedOrCancelled() {
      if (!_active) {
        return Error.disposed();
      } else if (previousResult != value) {
        // Result changed during asynchronous gap, likely due to cancellation - abort
        // TODO: Log warning about concurrent modification unless cancelled
        return Error.cancelled();
      }
      return null;
    }

    try {
      final fetchedResult = await fetchResult();

      final shouldAbortResult = abortIfDisposedOrCancelled();
      if (shouldAbortResult != null) return shouldAbortResult;

      value = fetchedResult;
    } catch (error, stackTrace) {
      final shouldAbortResult = abortIfDisposedOrCancelled();
      if (shouldAbortResult != null) {
        return shouldAbortResult;
      } else {
        // CancelledException and NoDataException should end up here (i.e. update the result to Error)
        toError(error: error, stackTrace: stackTrace);
      }
    }
    return result;
  }
}
