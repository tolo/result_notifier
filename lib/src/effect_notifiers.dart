import 'dart:async';

import 'async_notifier.dart';
import 'extensions.dart';
import 'result.dart';
import 'result_notifier.dart';

/// Signature for functions used by [CombineLatestNotifier] to combine data from a number of source [ResultNotifier]s
/// into a single value.
typedef Combine<S, R> = R Function(List<S> data);

/// Signature for functions used by [CombineLatestNotifier] to combine [Result]s from a number of source [ResultNotifier]s
/// into a single value.
typedef CombineResult<S, R> = Result<R> Function(Iterable<Result<S>> data);

/// Combines the data of a number of source [ResultNotifier]s into a single data value, held by this notifier.
///
/// The resulting data is produced by the specified [combineData] function, which is called whenever one of the source
/// notifiers updates its data.
///
/// See also:
/// - [ResultIterableEffects] which provides similar functionality for [Iterable]s of [Result]s.
/// - [ResultListenableIterableEffects] which provides similar functionality for [Iterable]s of [ResultListenable]s.
/// - [ResultTuple] which provides similar functionality for tuples of [Result]s.
/// - [ResultListenableTuple] which provides similar functionality for tuples of [ResultListenable]s.
class CombineLatestNotifier<S, R> extends ResultNotifier<R> with EffectNotifier<S, R> {
  // TODO: More docs

  /// Constructs a [CombineLatestNotifier] that combines the data from the provided source `notifiers`, using the
  /// specified `combineData` function.
  ///
  /// If the source notifiers did not all contain data, the result of this notifier will be set to reflect this - see
  /// [ResultIterableEffects.combine] for more information.
  ///
  /// If [immediate] is true, the effect will be executed immediately after the notifier is created.
  /// If [ignoreLoading] is true, any [Loading] state of the input notifiers will be ignored, and the previous result
  /// will be kept.
  ///
  /// {@macro result_notifier.constructor}
  CombineLatestNotifier(
    Iterable<ResultListenable<S>> notifiers, {
    required Combine<S, R> combineData,
    super.data,
    super.result,
    super.expiration,
    super.onReset,
    super.onErrorReturn,
    super.autoReset,
    super.refreshOnError,
    bool immediate = false,
    this.ignoreLoading = false,
  }) : super(onFetch: _effect(notifiers, combineData)) {
    if (immediate) refresh(force: true);
    for (final source in notifiers) {
      _dependOnSource(source);
    }
  }

  /// Constructs a [CombineLatestNotifier] that combines the results from the provided source `notifiers`, using the
  /// specified `combineResult` function.
  ///
  /// If [immediate] is true, the effect will be executed immediately after the notifier is created.
  /// If [ignoreLoading] is true, any [Loading] state of the input notifiers will be ignored, and the previous result
  /// will be kept.
  ///
  /// {@macro result_notifier.constructor}
  CombineLatestNotifier.result(
    Iterable<ResultListenable<S>> notifiers, {
    required CombineResult<S, R> combineResult,
    super.data,
    super.result,
    super.expiration,
    super.onReset,
    super.onErrorReturn,
    super.autoReset,
    super.refreshOnError,
    bool immediate = false,
    this.ignoreLoading = false,
  }) : super(onFetch: _resultEffect(notifiers, combineResult)) {
    if (immediate) refresh(force: true);
    for (final source in notifiers) {
      _dependOnSource(source);
    }
  }

  static ResultNotifierCallback<R> _effect<S, R>(Iterable<ResultListenable<S>> sources, Combine<S, R> combineData) {
    return (not) {
      not.value = sources.combine(combineData);
    };
  }

  static ResultNotifierCallback<R> _resultEffect<S, R>(
      Iterable<ResultListenable<S>> sources, CombineResult<S, R> combineResult) {
    return (not) {
      not.value = combineResult(sources.map((not) => not.value));
    };
  }

  /// Constructs a [CombineLatestNotifier] that combines the data from the provided notifiers using the specified
  /// [combineData] function.
  ///
  /// See [CombineLatestNotifier.new].
  static CombineLatestNotifier<dynamic, R> combine2<A, B, R>(
    ResultListenable<A> notifierA,
    ResultListenable<B> notifierB, {
    required R Function(A a, B b) combineData,
    R? data,
    Result<R>? result,
    Duration? expiration,
    ResultNotifierCallback<R>? onReset,
    R Function(Object? error)? onErrorReturn,
    bool autoReset = false,
    bool refreshOnError = false,
    bool ignoreLoading = false,
  }) {
    return CombineLatestNotifier<dynamic, R>(
      [notifierA, notifierB],
      combineData: (data) => combineData(data[0] as A, data[1] as B),
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

  /// Constructs a [CombineLatestNotifier] that combines the data from the provided notifiers using the specified
  /// [combineData] function.
  static CombineLatestNotifier<dynamic, R> combine3<A, B, C, R>(
    ResultListenable<A> notifierA,
    ResultListenable<B> notifierB,
    ResultListenable<C> notifierC, {
    required R Function(A a, B b, C c) combineData,
    R? data,
    Result<R>? result,
    Duration? expiration,
    ResultNotifierCallback<R>? onReset,
    R Function(Object? error)? onErrorReturn,
    bool autoReset = false,
    bool refreshOnError = false,
    bool ignoreLoading = false,
  }) {
    return CombineLatestNotifier<dynamic, R>(
      [notifierA, notifierB, notifierC],
      combineData: (data) => combineData(data[0] as A, data[1] as B, data[2] as C),
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

  /// Constructs a [CombineLatestNotifier] that combines the data from the provided notifiers using the specified
  /// [combineData] function.
  static CombineLatestNotifier<dynamic, R> combine4<A, B, C, D, R>(
    ResultListenable<A> notifierA,
    ResultListenable<B> notifierB,
    ResultListenable<C> notifierC,
    ResultListenable<D> notifierD, {
    required R Function(A a, B b, C c, D d) combineData,
    R? data,
    Result<R>? result,
    Duration? expiration,
    ResultNotifierCallback<R>? onReset,
    R Function(Object? error)? onErrorReturn,
    bool autoReset = false,
    bool refreshOnError = false,
    bool ignoreLoading = false,
  }) {
    return CombineLatestNotifier<dynamic, R>(
      [notifierA, notifierB, notifierC, notifierD],
      combineData: (data) => combineData(data[0] as A, data[1] as B, data[2] as C, data[3] as D),
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

  /// Constructs a [CombineLatestNotifier] that combines the data from the specified [notifiers] using the specified
  /// [combineData] function.
  static CombineLatestNotifier<dynamic, R> combine5<A, B, C, D, E, R>(
    ResultListenable<A> notifierA,
    ResultListenable<B> notifierB,
    ResultListenable<C> notifierC,
    ResultListenable<D> notifierD,
    ResultListenable<E> notifierE, {
    required R Function(A a, B b, C c, D d, E e) combineData,
    R? data,
    Result<R>? result,
    Duration? expiration,
    ResultNotifierCallback<R>? onReset,
    R Function(Object? error)? onErrorReturn,
    bool autoReset = false,
    bool refreshOnError = false,
    bool ignoreLoading = false,
  }) {
    return CombineLatestNotifier<dynamic, R>(
      [notifierA, notifierB, notifierC, notifierD, notifierE],
      combineData: (data) => combineData(data[0] as A, data[1] as B, data[2] as C, data[3] as D, data[4] as E),
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

  /// If true, any [Loading] state of the input notifiers will be ignored, and the previous result will be kept.
  @override
  final bool ignoreLoading;
}

/// Result notifier that executes an "effect" whenever a source [ResultNotifier] changes value.
///
/// The effect is implemented by the fetch function provided when creating this notifier, or by overriding the
/// [fetchData] method in a subclass.
///
/// See for instance [SyncEffectNotifier] and [AsyncEffectNotifier] for concrete implementations.
mixin EffectNotifier<S, R> on ResultNotifier<R> {
  final List<Disposer> _disposables = [];

  /// If true, any [Loading] state of the input notifiers will be ignored, and the previous result will be kept.
  bool get ignoreLoading;

  void _dependOnSource(ResultListenable<S> source) {
    _disposables.add(source.onResult(_onSourceResult));
  }

  @override
  void dispose() {
    for (final disposable in _disposables) {
      disposable();
    }
    super.dispose();
  }

  @override
  set value(Result<R> newValue) {
    if (newValue.isLoading && ignoreLoading) {
      // Ignore loading state
    } else {
      super.value = newValue;
    }
  }

  void _onSourceResult(Result result) {
    result.when(
      data: (_) => refresh(force: true), // i.e. run the effect whenever source presents new data
      loading: (_) => toLoading(),
      error: (error, stackTrace, data) => toError(error: error, stackTrace: stackTrace),
    );
  }

  void _withSourceData(ResultListenable<S> source, void Function(S sourceData) dataEffect) {
    source.value.whenOr(
      data: dataEffect,
    );
  }
}

/// Signature for functions used by [SyncEffectNotifier] to execute an action that returns data, using the data of a
/// source [ResultNotifier] as input.
typedef Effect<S, R> = R Function(SyncEffectNotifier<S, R> notifier, S input);

/// Signature for functions used by [SyncEffectNotifier] to execute an action that returns a [Result], using the data of
/// a source [ResultNotifier] as input.
typedef ResultEffect<S, R> = Result<R> Function(SyncEffectNotifier<S, R> notifier, S input);

/// Result notifier that executes an "effect" whenever a source [ResultNotifier] changes value.
///
/// The provided [effect] function is executed synchronously, whenever the source notifier produces new data. The data
/// of the source notifier will be passed as input to the effect function.
///
/// See also [AsyncEffectNotifier].
class SyncEffectNotifier<S, R> extends ResultNotifier<R> with EffectNotifier<S, R> {
  // TODO: More docs

  /// Creates a SyncEffectNotifier.
  ///
  /// If [immediate] is true, the effect will be executed immediately after the notifier is created.
  /// If [ignoreLoading] is true, any [Loading] state of the input notifiers will be ignored, and the previous result
  /// will be kept.
  ///
  /// {@macro result_notifier.constructor}
  SyncEffectNotifier(
    ResultListenable<S> source, {
    required Effect<S, R> effect,
    super.data,
    super.result,
    super.expiration,
    super.onReset,
    super.onErrorReturn,
    super.autoReset,
    super.refreshOnError,
    bool immediate = false,
    this.ignoreLoading = false,
  }) : super(onFetch: _runEffect(source, effect)) {
    if (immediate) refresh(force: true);
    _dependOnSource(source);
  }

  /// Creates a SyncEffectNotifier.
  ///
  /// If [immediate] is true, the effect will be executed immediately after the notifier is created.
  /// If [ignoreLoading] is true, any [Loading] state of the input notifiers will be ignored, and the previous result
  /// will be kept.
  ///
  /// {@macro result_notifier.constructor}
  SyncEffectNotifier.result(
    ResultListenable<S> source, {
    required ResultEffect<S, R> effect,
    super.data,
    super.result,
    super.expiration,
    super.onReset,
    super.onErrorReturn,
    super.autoReset,
    super.refreshOnError,
    bool immediate = false,
    this.ignoreLoading = false,
  }) : super(onFetch: _runResultEffect(source, effect)) {
    if (immediate) refresh(force: true);
    _dependOnSource(source);
  }

  static ResultNotifierCallback<R> _runEffect<S, R>(ResultListenable<S> source, Effect<S, R> effect) {
    return (not) {
      (not as SyncEffectNotifier<S, R>)._withSourceData(source, (sourceData) {
        not.data = effect(not, sourceData);
      });
    };
  }

  static ResultNotifierCallback<R> _runResultEffect<S, R>(ResultListenable<S> source, ResultEffect<S, R> effect) {
    return (not) {
      (not as SyncEffectNotifier<S, R>)._withSourceData(source, (sourceData) {
        not.value = effect(not, sourceData);
      });
    };
  }

  @override
  final bool ignoreLoading;
}

/// Signature for functions used by [AsyncEffectNotifier] to execute an action that returns data Future, using the data
/// of a source [ResultNotifier] as input.
typedef AsyncEffect<S, R> = Future<R> Function(ResultNotifier<R> notifier, S input);

/// Signature for functions used by [AsyncEffectNotifier] to execute an action that returns a [Result] Future, using the
/// data of a source [ResultNotifier] as input.
typedef AsyncResultEffect<S, R> = Future<Result<R>> Function(ResultNotifier<R> notifier, S input);

/// Result notifier that executes an "effect" asynchronously whenever a source [ResultNotifier] changes value.
///
/// The provided [effect] function is executed asynchronously whenever the source notifier produces new data. The data
/// of the source notifier will be passed as input to the effect function.
///
/// See also [SyncEffectNotifier].
class AsyncEffectNotifier<S, R> extends FutureNotifier<R> with EffectNotifier<S, R> {
  // TODO: More docs

  /// Creates a AsyncEffectNotifier.
  ///
  /// If [immediate] is true, the effect will be executed immediately after the notifier is created.
  /// If [ignoreLoading] is true, any [Loading] state of the input notifiers will be ignored, and the previous result
  /// will be kept.
  ///
  /// {@macro result_notifier.constructor}
  AsyncEffectNotifier(
    ResultListenable<S> source, {
    required AsyncEffect<S, R> effect,
    super.data,
    super.result,
    super.expiration,
    super.onReset,
    super.onErrorReturn,
    super.autoReset,
    super.refreshOnError,
    bool immediate = false,
    this.ignoreLoading = false,
  }) : super.customFetch(onFetch: _asyncEffect(source, effect)) {
    if (immediate) refresh(force: true);
    _dependOnSource(source);
  }

  /// Creates a AsyncEffectNotifier.
  ///
  /// If [immediate] is true, the effect will be executed immediately after the notifier is created.
  /// If [ignoreLoading] is true, any [Loading] state of the input notifiers will be ignored, and the previous result
  /// will be kept.
  ///
  /// {@macro result_notifier.constructor}
  AsyncEffectNotifier.result(
    ResultListenable<S> source, {
    required AsyncResultEffect<S, R> effect,
    super.data,
    super.result,
    super.expiration,
    super.onReset,
    super.onErrorReturn,
    super.autoReset,
    super.refreshOnError,
    bool immediate = false,
    this.ignoreLoading = false,
  }) : super.customFetch(onFetch: _asyncResultEffect(source, effect)) {
    if (immediate) refresh(force: true);
    _dependOnSource(source);
  }

  static ResultNotifierCallback<R> _asyncEffect<S, R>(ResultListenable<S> source, AsyncEffect<S, R> effect) {
    return (not) {
      (not as AsyncEffectNotifier<S, R>)._withSourceData(source, (sourceData) {
        not.performFetch((not) async => Data(await effect(not, sourceData)));
      });
    };
  }

  static ResultNotifierCallback<R> _asyncResultEffect<S, R>(
      ResultListenable<S> source, AsyncResultEffect<S, R> effect) {
    return (not) {
      (not as AsyncEffectNotifier<S, R>)._withSourceData(source, (sourceData) {
        not.performFetch((not) => effect(not, sourceData));
      });
    };
  }

  @override
  final bool ignoreLoading;
}

/// Signature for functions used by [StreamEffectNotifier] to execute an action that returns data Stream, using the data
/// of a source [ResultNotifier] as input.
typedef StreamEffect<S, R> = Stream<R> Function(ResultNotifier<R> notifier, S input);

/// Signature for functions used by [StreamEffectNotifier] to execute an action that returns a [Result] Stream, using
/// the data of a source [ResultNotifier] as input.
typedef ResultStreamEffect<S, R> = Stream<Result<R>> Function(ResultNotifier<R> notifier, S input);

/// Result notifier that executes an "effect" that returns a Stream, whenever a source [ResultNotifier] changes value.
///
/// The provided [effect] function is executed whenever the source notifier produces new data. The data of the source
/// notifier will be passed as input to the effect function, returning a new Stream or data. The notifier will then
/// subscribe to that Stream and update its value whenever new data or errors are emitted.
class StreamEffectNotifier<S, R> extends StreamNotifier<R> with EffectNotifier<S, R> {
  // TODO: More docs

  /// Creates a StreamEffectNotifier.
  ///
  /// If [immediate] is true, the effect will be executed immediately after the notifier is created.
  /// If [ignoreLoading] is true, any [Loading] state of the input notifiers will be ignored, and the previous result
  /// will be kept.
  ///
  /// {@macro result_notifier.constructor}
  StreamEffectNotifier(
    ResultListenable<S> source, {
    required StreamEffect<S, R> effect,
    super.data,
    super.result,
    super.expiration,
    super.onReset,
    super.onErrorReturn,
    super.autoReset,
    super.refreshOnError,
    bool immediate = false,
    this.ignoreLoading = false,
  }) : super.customFetch(onFetch: _effect(source, effect)) {
    if (immediate) refresh(force: true);
    _dependOnSource(source);
  }

  /// Creates a StreamEffectNotifier.
  ///
  /// If [immediate] is true, the effect will be executed immediately after the notifier is created.
  /// If [ignoreLoading] is true, any [Loading] state of the input notifiers will be ignored, and the previous result
  /// will be kept.
  ///
  /// {@macro result_notifier.constructor}
  StreamEffectNotifier.result(
    ResultListenable<S> source, {
    required ResultStreamEffect<S, R> effect,
    super.data,
    super.result,
    super.expiration,
    super.onReset,
    super.onErrorReturn,
    super.autoReset,
    super.refreshOnError,
    bool immediate = false,
    this.ignoreLoading = false,
  }) : super.customFetch(onFetch: _resultEffect(source, effect)) {
    if (immediate) refresh(force: true);
    _dependOnSource(source);
  }

  static ResultNotifierCallback<R> _effect<S, R>(ResultListenable<S> source, StreamEffect<S, R> effect) {
    return (not) {
      (not as StreamEffectNotifier<S, R>)._withSourceData(source, (sourceData) {
        not.performFetch((not) => effect(not, sourceData).map((event) => Data(event)));
      });
    };
  }

  static ResultNotifierCallback<R> _resultEffect<S, R>(ResultListenable<S> source, ResultStreamEffect<S, R> effect) {
    return (not) {
      (not as StreamEffectNotifier<S, R>)._withSourceData(source, (sourceData) {
        not.performFetch((not) => effect(not, sourceData));
      });
    };
  }

  @override
  final bool ignoreLoading;
}

/// Mixin to support listening via a [Stream].
mixin StreamableResultNotifierMixin<T> on ResultNotifier<T> {
  // TODO: Needs more docs

  StreamController<Result<T>>? _streamController;

  @override
  set value(Result<T> newValue) {
    final modified = value != newValue;
    super.value = newValue;
    if (_streamController != null && modified) _streamController!.add(newValue);
  }

  /// Returns a [Stream] of [Result]s using this notifier as a source.
  Stream<Result<T>> get stream {
    _streamController ??= StreamController.broadcast(sync: true);
    return _streamController!.stream;
  }

  /// Returns a [Stream] of [Result]s, starting with the current [value].
  Stream<Result<T>> get valueStream async* {
    yield value;
    await for (final result in stream) {
      yield result;
    }
  }

  /// Returns a [Stream] of data, i.e. a stream event is generated whenever [Data] is set.
  ///
  /// Similar to [valueStream], this stream will start with the current data, if any.
  Stream<T> get dataStream {
    return valueStream.where((e) => e.isData).map((e) => e.data!);
  }

  @override
  void dispose() {
    if (_streamController != null) _streamController!.close();
    super.dispose();
  }
}
