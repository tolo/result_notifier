import 'dart:async';

import 'async_notifier.dart';
import 'result.dart';
import 'result_notifier.dart';

/// Signature for functions used by [CombineLatestNotifier] to combine data from a number of source [ResultNotifier]s
/// into a single value.
typedef Combine<S, R> = R Function(List<S> data);

// TODO: Perhaps add CombineResult
//typedef CombineResult<S, R> = Result<R> Function(List<Result<S>> data);

/// Combines the data of a number of source [ResultNotifier]s into a single data value, held by this notifier.
///
/// The resulting data is produced by the specified [combineData] function, which is called whenever one of the source
/// notifiers updates its data.
class CombineLatestNotifier<S, R> extends ResultNotifier<R> with EffectNotifier<S, R> {
  // TODO: More docs

  /// Constructs a [CombineLatestNotifier] that combines the data from the provided source [notifiers], using the
  /// specified [combineData] function.
  ///
  /// {@macro result_notifier.constructor}
  CombineLatestNotifier(
    Iterable<ResultNotifier<S>> notifiers, {
    required Combine<S, R> combineData,
    super.data,
    super.result,
    super.expiration,
    super.onReset,
    super.onErrorReturn,
    super.autoReset,
    super.refreshOnError,
    this.ignoreLoading = false,
  })  : _notifiers = notifiers,
        _combineData = combineData {
    // _combineValues(); // TODO: Should we combine immediately?
    for (final source in notifiers) {
      _dependOnSource(source);
    }
  }

  /// Constructs a [CombineLatestNotifier] that combines the data from the provided notifiers using the specified
  /// [combineData] function.
  static CombineLatestNotifier<dynamic, R> combine2<A, B, R>(
    ResultNotifier<A> notifierA,
    ResultNotifier<B> notifierB, {
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
    ResultNotifier<A> notifierA,
    ResultNotifier<B> notifierB,
    ResultNotifier<C> notifierC, {
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
    ResultNotifier<A> notifierA,
    ResultNotifier<B> notifierB,
    ResultNotifier<C> notifierC,
    ResultNotifier<D> notifierD, {
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
    ResultNotifier<A> notifierA,
    ResultNotifier<B> notifierB,
    ResultNotifier<C> notifierC,
    ResultNotifier<D> notifierD,
    ResultNotifier<E> notifierE, {
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

  /// Function that combines data from the input notifiers into a single value.
  final Combine<S, R> _combineData;

  final Iterable<ResultNotifier<S>> _notifiers;

  @override
  void fetchData() {
    final List<S> notifierData = [];
    for (final notifier in _notifiers) {
      final data = notifier.dataOrNull;
      if (data != null) {
        notifierData.add(data);
      } else {
        break;
      }
    }
    if (notifierData.length == _notifiers.length) {
      value = Data(_combineData(notifierData));
    } else if (!isLoading) {
      toLoading();
    }
  }
}

/// Result notifier that executes an "effect" whenever a source [ResultNotifier] changes value.
mixin EffectNotifier<S, R> on ResultNotifier<R> {
  final List<Disposer> _disposables = [];

  /// If true, any [Loading] state of the input notifiers will be ignored, and the previous result will be kept.
  bool get ignoreLoading;

  void _dependOnSource(ResultNotifier<S> source) {
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

  void _withSourceData(ResultNotifier<S> source, void Function(S sourceData) dataEffect) {
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
class SyncEffectNotifier<S, R> extends ResultNotifier<R> with EffectNotifier<S, R> {
  // TODO: More docs

  /// Creates a SyncEffectNotifier.
  ///
  /// {@macro result_notifier.constructor}
  SyncEffectNotifier(
    ResultNotifier<S> source, {
    required Effect<S, R> effect,
    super.data,
    super.result,
    super.expiration,
    super.onReset,
    super.onErrorReturn,
    super.autoReset,
    super.refreshOnError,
    this.ignoreLoading = false,
  }) : super(onFetch: _runEffect(source, effect)) {
    _dependOnSource(source);
  }

  /// Creates a SyncEffectNotifier.
  ///
  /// {@macro result_notifier.constructor}
  SyncEffectNotifier.result(
    ResultNotifier<S> source, {
    required ResultEffect<S, R> effect,
    super.data,
    super.result,
    super.expiration,
    super.onReset,
    super.onErrorReturn,
    super.autoReset,
    super.refreshOnError,
    this.ignoreLoading = false,
  }) : super(onFetch: _runResultEffect(source, effect)) {
    _dependOnSource(source);
  }

  static ResultNotifierCallback<R> _runEffect<S, R>(ResultNotifier<S> source, Effect<S, R> effect) {
    return (not) {
      (not as SyncEffectNotifier<S, R>)._withSourceData(source, (sourceData) {
        not.data = effect(not, sourceData);
      });
    };
  }

  static ResultNotifierCallback<R> _runResultEffect<S, R>(ResultNotifier<S> source, ResultEffect<S, R> effect) {
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
class AsyncEffectNotifier<S, R> extends FutureNotifier<R> with EffectNotifier<S, R> {
  // TODO: More docs

  /// Creates a AsyncEffectNotifier.
  ///
  /// {@macro result_notifier.constructor}
  AsyncEffectNotifier(
    ResultNotifier<S> source, {
    required AsyncEffect<S, R> effect,
    super.data,
    super.result,
    super.expiration,
    super.onReset,
    super.onErrorReturn,
    super.autoReset,
    super.refreshOnError,
    this.ignoreLoading = false,
  }) : super.customFetch(onFetch: _asyncEffect(source, effect)) {
    _dependOnSource(source);
  }

  /// Creates a AsyncEffectNotifier.
  ///
  /// {@macro result_notifier.constructor}
  AsyncEffectNotifier.result(
    ResultNotifier<S> source, {
    required AsyncResultEffect<S, R> effect,
    super.data,
    super.result,
    super.expiration,
    super.onReset,
    super.onErrorReturn,
    super.autoReset,
    super.refreshOnError,
    this.ignoreLoading = false,
  }) : super.customFetch(onFetch: _asyncResultEffect(source, effect)) {
    _dependOnSource(source);
  }

  static ResultNotifierCallback<R> _asyncEffect<S, R>(ResultNotifier<S> source, AsyncEffect<S, R> effect) {
    return (not) {
      (not as AsyncEffectNotifier<S, R>)._withSourceData(source, (sourceData) {
        not.performFetch((not) async => Data(await effect(not, sourceData)));
      });
    };
  }

  static ResultNotifierCallback<R> _asyncResultEffect<S, R>(ResultNotifier<S> source, AsyncResultEffect<S, R> effect) {
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
  /// {@macro result_notifier.constructor}
  StreamEffectNotifier(
    ResultNotifier<S> source, {
    required StreamEffect<S, R> effect,
    super.data,
    super.result,
    super.expiration,
    super.onReset,
    super.onErrorReturn,
    super.autoReset,
    super.refreshOnError,
    this.ignoreLoading = false,
  }) : super.customFetch(onFetch: _effect(source, effect)) {
    _dependOnSource(source);
  }

  /// Creates a StreamEffectNotifier.
  ///
  /// {@macro result_notifier.constructor}
  StreamEffectNotifier.result(
    ResultNotifier<S> source, {
    required ResultStreamEffect<S, R> effect,
    super.data,
    super.result,
    super.expiration,
    super.onReset,
    super.onErrorReturn,
    super.autoReset,
    super.refreshOnError,
    this.ignoreLoading = false,
  }) : super.customFetch(onFetch: _resultEffect(source, effect)) {
    _dependOnSource(source);
  }

  static ResultNotifierCallback<R> _effect<S, R>(ResultNotifier<S> source, StreamEffect<S, R> effect) {
    return (not) {
      (not as StreamEffectNotifier<S, R>)._withSourceData(source, (sourceData) {
        not.performFetch((not) => effect(not, sourceData).map((event) => Data(event)));
      });
    };
  }

  static ResultNotifierCallback<R> _resultEffect<S, R>(ResultNotifier<S> source, ResultStreamEffect<S, R> effect) {
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

  /// Returns a [Stream] of [Result]s for this notifier, as an alternative way of observing changes.
  Stream<Result<T>> get stream {
    _streamController ??= StreamController.broadcast(sync: true);
    return _streamController!.stream;
  }

  @override
  void dispose() {
    if (_streamController != null) _streamController!.close();
    super.dispose();
  }
}
