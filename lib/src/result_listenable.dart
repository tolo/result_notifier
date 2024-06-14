import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'effect_notifiers.dart';
import 'result.dart';
import 'result_notifier.dart';

/// Extension for converting a [ValueListenable] to a [ResultListenable].
extension ValueListenableToResultListenable<T> on ValueListenable<T> {
  ResultListenable<T> toResultListenable() => _ValueListenableResultAdapter(this);
}

/// Abstract class/mixin for [ValueListenable] subclasses that holds a [Result].
///
/// The primary implementation of this class is [ResultNotifier], however this interface allows other
/// implementations to be used throughout the library.
abstract mixin class ResultListenable<T> implements ValueListenable<Result<T>> {
  // Computed/read-only properties

  /// Just an alias for [value].
  Result<T> get result => value;

  /// {@macro result.lastUpdate}
  DateTime get lastUpdate => value.lastUpdate;

  /// {@macro result.isInitial}
  bool get isInitial => value.isInitial;

  /// {@macro result.isLoading}
  bool get isLoading => value.isLoading;

  /// {@macro result.isLoadingData}
  bool get isLoadingData => value.isLoadingData;

  /// {@macro result.isReloading}
  bool get isReloading => value.isReloading;

  /// {@macro result.isData}
  bool get isData => value.isData;

  /// {@macro result.isError}
  bool get isError => value.isError;

  /// {@macro result.isCancelled}
  bool get isCancelled => value.isCancelled;

  /// {@macro result.hasData}
  bool get hasData => value.hasData;

  // Builder

  /// Convenience method for simplifying the creation of a [ValueListenableBuilder] with [ResultNotifier].
  ///
  /// If the creation and disposal lifecycle of the ResultNotifier needs to be managed by the Widget, see instead
  /// [ResourceProvider].
  ValueListenableBuilder<Result<T>> builder(
      Widget Function(BuildContext context, Result<T> result, Widget? child) builder,
      {Widget? child}) {
    return ValueListenableBuilder<Result<T>>(
      valueListenable: this,
      builder: builder,
      child: child,
    );
  }

  // Observation / listeners

  /// Registers a listener ([addListener]) that will only be invoked for [Data] results.
  ///
  /// Use the returned [VoidCallback] function to unsubscribe the listener (i.e. calls [removeListener]).
  ///
  /// See also:
  /// - [onResult] for a more general listener.
  @useResult
  VoidCallback onData(void Function(T data) listener) => onResult((result) {
        if (result case final Data<T> data) listener(data.data);
      });

  /// Registers a listener ([addListener]) that will only be invoked for [Loading] results.
  ///
  /// Use the returned [VoidCallback] function to unsubscribe the listener (i.e. calls [removeListener]).
  ///
  /// See also:
  /// - [onResult] for a more general listener.
  @useResult
  VoidCallback onLoading(void Function(T? data) listener) => onResult((result) {
        if (result case final Loading<T> loading) listener(loading.data);
      });

  /// Registers a listener ([addListener]) that will only be invoked for [Error] results.
  ///
  /// Use the returned [VoidCallback] function to unsubscribe the listener (i.e. calls [removeListener]).
  ///
  /// See also:
  /// - [onResult] for a more general listener.
  @useResult
  VoidCallback onError(void Function(Object? error, StackTrace? stackTrace, T? data) listener) => onResult((result) {
        if (result case final Error<T> error) listener(error.error, error.stackTrace, error.data);
      });

  /// Registers a listener ([addListener]) that will be invoked with the current Result ([value]).
  ///
  /// Use the returned [VoidCallback] function to unsubscribe the listener (i.e. calls [removeListener]).
  ///
  /// See also:
  /// - [onData], [onLoading], [onError] for more specific listeners.
  /// - [when] for a simple way to perform actions based on the type of the current Result, without registering a listener.
  @useResult
  VoidCallback onResult(void Function(Result<T> result) listener) {
    void listenerFunc() => listener(value);
    addListener(listenerFunc);
    return () => removeListener(listenerFunc);
  }

  // Effects

  /// Creates a new [CombineLatestNotifier] that that combines the value of this notifier with another one.
  CombineLatestNotifier<T, R> combineLatest<R>(
    ResultListenable<T> other, {
    required R Function(List<T> data) combineData,
  }) {
    return CombineLatestNotifier([this, other], combineData: combineData);
  }

  /// Creates a new synchronous [EffectNotifier] that executes the provided effect the data of this notifier changes.
  ///
  /// See [SyncEffectNotifier].
  EffectNotifier<T, R> effect<R>(
    Effect<T, R> effect, {
    R? data,
    Result<R>? result,
    Duration? expiration,
    ResultNotifierCallback<R>? onReset,
    R Function(Object? error)? onErrorReturn,
    bool autoReset = false,
    bool refreshOnError = false,
    bool ignoreLoading = false,
  }) {
    return SyncEffectNotifier(
      this,
      effect: effect,
      data: data,
      result: result,
      expiration: expiration,
      onReset: onReset,
      onErrorReturn: onErrorReturn,
      autoReset: autoReset,
      refreshOnError: refreshOnError,
      ignoreLoading: ignoreLoading,
    );
  }

  /// Creates a new [ResultNotifier] that only gets updated when the data of this notifier changes, i.e. ignoring
  /// [Loading] and [Error] states.
  ResultNotifier<T> alwaysData(T defaultData) {
    return effect(
      (_, data) => data,
      data: defaultData,
      onErrorReturn: (_) => defaultData,
      ignoreLoading: true,
    );
  }

  /// Creates a new asynchronous [EffectNotifier] that executes the provided asynchronous effect the data of this
  /// notifier changes.
  ///
  /// See [AsyncEffectNotifier].
  EffectNotifier<T, R> asyncEffect<R>(
    AsyncEffect<T, R> effect, {
    R? data,
    Result<R>? result,
    Duration? expiration,
    ResultNotifierCallback<R>? onReset,
    R Function(Object? error)? onErrorReturn,
    bool autoReset = false,
    bool refreshOnError = false,
    bool ignoreLoading = false,
  }) {
    return AsyncEffectNotifier(
      this,
      effect: effect,
      data: data,
      result: result,
      expiration: expiration,
      onReset: onReset,
      onErrorReturn: onErrorReturn,
      autoReset: autoReset,
      refreshOnError: refreshOnError,
      ignoreLoading: ignoreLoading,
    );
  }

  /// Creates a new asynchronous [EffectNotifier] that executes the provided strean effect the data of this
  /// notifier changes.
  ///
  /// See [StreamEffectNotifier].
  EffectNotifier<T, R> streamEffect<R>(
    StreamEffect<T, R> effect, {
    R? data,
    Result<R>? result,
    Duration? expiration,
    ResultNotifierCallback<R>? onReset,
    R Function(Object? error)? onErrorReturn,
    bool autoReset = false,
    bool refreshOnError = false,
    bool ignoreLoading = false,
  }) {
    return StreamEffectNotifier(
      this,
      effect: effect,
      data: data,
      result: result,
      expiration: expiration,
      onReset: onReset,
      onErrorReturn: onErrorReturn,
      autoReset: autoReset,
      refreshOnError: refreshOnError,
      ignoreLoading: ignoreLoading,
    );
  }
}

class _ValueListenableResultAdapter<T> extends ResultListenable<T> {
  _ValueListenableResultAdapter(this.source);

  final ValueListenable<T> source;

  @override
  void addListener(VoidCallback listener) {
    source.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    source.removeListener(listener);
  }

  @override
  Result<T> get value => Data.stale(source.value);
}
