import 'dart:async';

import 'package:meta/meta.dart';

import 'async_notifier.dart';
import 'result.dart';
import 'result_notifier.dart';

/// Signature for functions used by [CombineLatestNotifier] to combine two values into a single value.
typedef CombineValues<T, A, B> = T Function(A, B);

/// Combines two [ResultNotifier]s into a single [ResultNotifier]. The resulting data is produced by the specified
/// [CombineValues] function.
@experimental
class CombineLatestNotifier<T, A, B> extends ResultNotifier<T> {
  // TODO: Needs tests
  CombineLatestNotifier({
    required ResultNotifier<A> firstNotifier,
    required ResultNotifier<B> secondNotifier,
    required this.combineValues,
    super.data,
    super.result,
    super.expiration,
    super.onErrorReturn,
  }) {
    _disposables.add(firstNotifier.onResult(_onA));
    _disposables.add(secondNotifier.onResult(_onB));
  }

  final CombineValues<T, A, B> combineValues;

  final List<Disposer> _disposables = [];

  @override
  void dispose() {
    for (var disposable in _disposables) {
      disposable();
    }
    super.dispose();
  }

  A? _lastA;
  void _onA(Result<A> result) {
    _onResult(result, (a) {
      _lastA = a;
      _combineValues();
      return a;
    });
  }

  B? _lastB;
  void _onB(Result<B> result) {
    _onResult(result, (b) {
      _lastB = b;
      _combineValues();
      return b;
    });
  }

  void _onResult<X>(Result<X> result, X Function(X) onData) {
    result.when(
      data: onData,
      loading: (_) => toLoading(),
      error: (error, stackTrace, data) => toError(error: error, stackTrace: stackTrace),
    );
  }

  void _combineValues() {
    if (_lastA != null && _lastB != null) {
      value = Data(combineValues(_lastA as A, _lastB as B));
    }
  }
}

/// Signature for functions used by [ChainedNotifier] to fetch data asynchronously for an [FutureNotifier], using the
/// input from another [ResultNotifier].
typedef ChainedDataFetcher<T, X> = FutureOr<T> Function(ChainedNotifier<T, X>, X);

/// Result notifier that user another [ResultNotifier] as the input for this notifier. The resulting data is produced
/// whenever the other notifier produces new data, at which point the specified fetcher function is called to fetch the
/// chained value, using the data from the other notifier as input.
@experimental
class ChainedNotifier<T, X> extends FutureNotifier<T> {
  // TODO: Needs tests
  /// Creates a ChainedNotifier that fetches new data using the specified fetcher.
  ///
  /// Starts with the specified [Result], or the [Loading.initial] loading state if not specified.
  ChainedNotifier({
    required ResultNotifier<X> otherNotifier,
    required ChainedDataFetcher<T, X> fetch,
    super.data,
    super.result,
    super.expiration,
    super.onReset,
    super.onErrorReturn,
  }) : super.result(_combineFetcher(otherNotifier, fetch)) {
    _otherDisposer = otherNotifier.onResult(_refreshCombineResult);
  }

  static FetchResultAsync<T> _combineFetcher<T, X>(ResultNotifier<X> other, ChainedDataFetcher<T, X> fetcher) {
    return (not) => (not as ChainedNotifier<T, X>)._fetch(other, fetcher);
  }

  late final Disposer _otherDisposer;

  FutureOr<Result<T>> _fetch(ResultNotifier<X> other, ChainedDataFetcher<T, X> fetcher) {
    return other.value.when(
      data: (d) async => Data(await fetcher(this, d)),
      loading: (d) => value.toLoading(),
      error: (e, st, d) => value.toError(error: e, stackTrace: st),
    );
  }

  void _refreshCombineResult(Result<X> result) {
    result.when(
      data: (_) => refresh(force: true),
      loading: (_) => toLoading(),
      error: (error, stackTrace, data) => toError(error: error, stackTrace: stackTrace),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _otherDisposer();
  }
}

/// Mixin to support listening via a [Stream].
@experimental
mixin StreamableResultNotifierMixin<T> on ResultNotifier<T> {
  // TODO: Needs tests

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
