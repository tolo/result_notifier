import 'package:flutter/foundation.dart';
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

  // Observation / listeners

  /// Registers a listener ([addListener]) that will only be invoked for [Data] results.
  ///
  /// The returned [Disposer] muse be used to remove the listener.
  @useResult
  Disposer onData(void Function(T data) callback) => onResult((result) => result.whenOr(data: callback));

  /// Registers a listener ([addListener]) that will only be invoked for [Loading] results.
  ///
  /// The returned [Disposer] muse be used to remove the listener.
  @useResult
  Disposer onLoading(void Function(T? data) callback) => onResult((result) => result.whenOr(loading: callback));

  /// Registers a listener ([addListener]) that will only be invoked for [Error] results.
  ///
  /// The returned [Disposer] muse be used to remove the listener.
  @useResult
  Disposer onError(void Function(Object? error, StackTrace? stackTrace, T? data) callback) =>
      onResult((result) => result.whenOr(error: callback));

  /// Registers a listener ([addListener]) that will be invoked with the current Result ([value]).
  ///
  /// The returned [Disposer] muse be used to remove the listener.
  @useResult
  Disposer onResult(void Function(Result<T> result) callback) {
    void listener() => callback(value);
    addListener(listener);
    return () => removeListener(listener);
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
