import 'result.dart';
import 'result_notifier.dart';

/// Extension on Iterables containing [Result]s.
///
/// Provides convenience methods for working with collections of [Result]s, such as checking the states of the results.
extension ResultIterable<S> on Iterable<Result<S>> {
  /// Returns true if all [isLoading].
  bool isAllLoading() => every((r) => r.isLoading);

  /// Returns true if any [isLoading].
  bool isLoading() => any((r) => r.isLoading);

  /// Returns true if all [isError].
  bool isAllError() => every((r) => r.isError);

  /// Returns true if any [isError].
  bool isError() => any((r) => r.isError);

  /// Returns true if all [isData].
  bool isAllData() => every((r) => r.isData);

  /// Returns true if any [isData].
  bool isData() => any((r) => r.isData);

  /// Returns true if all [hasData].
  bool hasAllData() => every((r) => r.hasData);

  /// Returns true if any [hasData].
  bool hasData() => any((r) => r.hasData);
}

/// Extension on Iterables containing [ResultNotifier]s.
///
/// Provides convenience methods for working with collections of [ResultNotifier]s, such as checking the states of the
/// notifiers.
extension ResultNotifierIterable<S> on Iterable<ResultListenable<S>> {
  /// Returns true if all [isLoading].
  bool isAllLoading() => every((r) => r.isLoading);

  /// Returns true if any [isLoading].
  bool isLoading() => any((r) => r.isLoading);

  /// Returns true if all [isError].
  bool isAllError() => every((r) => r.isError);

  /// Returns true if any [isError].
  bool isError() => any((r) => r.isError);

  /// Returns true if all [isData].
  bool isAllData() => every((r) => r.isData);

  /// Returns true if any [isData].
  bool isData() => any((r) => r.isData);

  /// Returns true if all [hasData].
  bool hasAllData() => every((r) => r.hasData);

  /// Returns true if any [hasData].
  bool hasData() => any((r) => r.hasData);
}

/// Effect extension on Iterables containing [Result]s.
///
/// Provides convenience methods for applying effects to collections of [Result]s, such as combining data
/// (see [combineData]) and [Result]s (see [combine]).
extension ResultIterableEffects<S> on Iterable<Result<S>> {
  /// {@template result_iterable_effects.combine}
  /// Combines the data of all [Result]s into a single [Result], using the provided combine function.
  ///
  /// If all of the results `hasData`, the returned [Result] will contain the combined data.
  ///
  /// If all of the [Result]s are [Data], the return value will also be `Data`. If any of the [Result]s are [Error],
  /// the return value will be an `Error` that contains the error object of the first encountered error. [Loading] will
  /// be returned if at least one result was `Loading`, and there was no `Error`.
  /// {@endtemplate}
  Result<R> combine<R>(R Function(List<S> data) combine) {
    final List<S> notifierData = [];
    bool loading = false;
    Error<S>? firstError;
    for (final result in this) {
      final data = result.data;
      loading |= result.isLoading;
      firstError ??= result is Error<S> ? result : null;
      if (data != null) {
        notifierData.add(data);
      }
    }

    final R? data = notifierData.length == length ? combine(notifierData) : null;

    if (firstError != null) {
      return Error(error: firstError.error, stackTrace: firstError.stackTrace, data: data);
    } else if (loading || data == null) {
      return Loading(data: data);
    } else {
      return Data(data);
    }
  }

  /// {@template result_iterable_effects.combineData}
  /// Combines the data of all [Result]s into a single value, using the provided combine function.
  ///
  /// The method returns the combined data if all of the results `hasData`, otherwise it returns `null`.
  /// {@endtemplate}
  R? combineData<R>(R Function(List<S> data) combine) {
    final List<S> notifierData = [];
    for (final result in this) {
      final data = result.data;
      if (data != null) {
        notifierData.add(data);
      } else {
        break;
      }
    }
    if (notifierData.length == length) {
      return combine(notifierData);
    }
    return null;
  }
}

/// Effect extension on Iterables containing [ResultNotifier]s (or [ResultListenable]s).
///
/// Provides convenience methods for applying effects to collections of [ResultListenable]s, such as combining data
/// (see [combineData]) and [Result]s (see [combine]).
extension ResultListenableIterableEffects<S> on Iterable<ResultListenable<S>> {
  /// {@macro result_iterable_effects.combine}
  Result<R> combine<R>(R Function(List<S> data) combine) {
    return map((e) => e.result).combine(combine);
  }

  /// {@template result_notifier_iterable_effects.combineData}
  /// Combines the data of all [ResultListenable]s into a single value, using the provided combine function.
  ///
  /// The method returns the combined data if all of the notifiers `hasData`, otherwise it returns `null`.
  /// {@endtemplate}
  R? combineData<R>(R Function(List<S> data) combine) {
    return map((e) => e.result).combineData(combine);
  }
}

// Result records

/// Convenience record to enable easy access to typed extensions methods on [Result] (via [ResultTupleMethods]).
///
/// See also:
/// - [ResultListenableTuple]
/// - [ResultTriple]
/// - [ResultQuadruple]
/// - [ResultQuintuple]
typedef ResultTuple<A, B> = (Result<A>, Result<B>);

/// Record extension providing convenience extension methods.
extension ResultTupleMethods<A, B> on ResultTuple<A, B> {
  /// {@macro result_iterable_effects.combine}
  Result<R> combine<R>(R Function(A a, B b) combine) {
    return [$1, $2].combine((data) => combine(data[0] as A, data[1] as B));
  }

  /// {@macro result_iterable_effects.combineData}
  R? combineData<R>(R Function(A a, B b) combine) {
    return [$1, $2].combineData((data) => combine(data[0] as A, data[1] as B));
  }
}

/// Convenience record to enable easy access to typed extensions methods on [Result] (via [ResultTripleMethods]).
typedef ResultTriple<A, B, C> = (Result<A>, Result<B>, Result<C>);

/// Record extension providing convenience extension methods.
extension ResultTripleMethods<A, B, C> on ResultTriple<A, B, C> {
  /// {@macro result_iterable_effects.combine}
  Result<R> combine<R>(R Function(A a, B b, C c) combine) {
    return [$1, $2, $3].combine((data) => combine(data[0] as A, data[1] as B, data[2] as C));
  }

  /// {@macro result_iterable_effects.combineData}
  R? combineData<R>(R Function(A a, B b, C c) combine) {
    return [$1, $2, $3].combineData((data) => combine(data[0] as A, data[1] as B, data[2] as C));
  }
}

/// Convenience record to enable easy access to typed extensions methods on [Result] (via [ResultQuadrupleMethods]).
typedef ResultQuadruple<A, B, C, D> = (Result<A>, Result<B>, Result<C>, Result<D>);

/// Record extension providing convenience extension methods.
extension ResultQuadrupleMethods<A, B, C, D> on ResultQuadruple<A, B, C, D> {
  /// {@macro result_iterable_effects.combine}
  Result<R> combine<R>(R Function(A a, B b, C c, D d) combine) {
    return [$1, $2, $3, $4].combine((data) => combine(data[0] as A, data[1] as B, data[2] as C, data[3] as D));
  }

  /// {@macro result_iterable_effects.combineData}
  R? combineData<R>(R Function(A a, B b, C c, D d) combine) {
    return [$1, $2, $3, $4].combineData((data) => combine(data[0] as A, data[1] as B, data[2] as C, data[3] as D));
  }
}

/// Convenience record to enable easy access to typed extensions methods on [Result] (via [ResultQuintupleMethods]).
typedef ResultQuintuple<A, B, C, D, E> = (Result<A>, Result<B>, Result<C>, Result<D>, Result<E>);

/// Record extension providing convenience extension methods.
extension ResultQuintupleMethods<A, B, C, D, E> on ResultQuintuple<A, B, C, D, E> {
  /// {@macro result_iterable_effects.combine}
  Result<R> combine<R>(R Function(A a, B b, C c, D d, E e) combine) {
    return [$1, $2, $3, $4, $5]
        .combine((data) => combine(data[0] as A, data[1] as B, data[2] as C, data[3] as D, data[4] as E));
  }

  /// {@macro result_iterable_effects.combineData}
  R? combineData<R>(R Function(A a, B b, C c, D d, E e) combine) {
    return [$1, $2, $3, $4, $5]
        .combineData((data) => combine(data[0] as A, data[1] as B, data[2] as C, data[3] as D, data[4] as E));
  }
}

// ResultNotifier records

/// Convenience record to enable easy access to typed extensions methods on [ResultNotifier] (or [ResultListenable])
/// (via [ResultListenableTupleMethods]).
///
/// See also:
/// - [ResultTuple]
/// - [ResultListenableTriple]
/// - [ResultListenableQuadruple]
/// - [ResultListenableQuintuple]
typedef ResultListenableTuple<A, B> = (ResultListenable<A>, ResultListenable<B>);

/// Record extension providing convenience extension methods.
extension ResultListenableTupleMethods<A, B> on ResultListenableTuple<A, B> {
  /// {@macro result_iterable_effects.combine}
  Result<R> combine<R>(R Function(A a, B b) combine) {
    return [$1, $2].combine((data) => combine(data[0] as A, data[1] as B));
  }

  /// {@macro result_notifier_iterable_effects.combineData}
  R? combineData<R>(R Function(A a, B b) combine) {
    return [$1, $2].combineData((data) => combine(data[0] as A, data[1] as B));
  }
}

/// Convenience record to enable easy access to typed extensions methods on [ResultNotifier] (or [ResultListenable])
/// (via [ResultListenableTripleMethods]).
typedef ResultListenableTriple<A, B, C> = (ResultListenable<A>, ResultListenable<B>, ResultListenable<C>);

/// Record extension providing convenience extension methods.
extension ResultListenableTripleMethods<A, B, C> on ResultListenableTriple<A, B, C> {
  /// {@macro result_iterable_effects.combine}
  Result<R> combine<R>(R Function(A a, B b, C c) combine) {
    return [$1, $2, $3].combine((data) => combine(data[0] as A, data[1] as B, data[2] as C));
  }

  /// {@macro result_notifier_iterable_effects.combineData}
  R? combineData<R>(R Function(A a, B b, C c) combine) {
    return [$1, $2, $3].combineData((data) => combine(data[0] as A, data[1] as B, data[2] as C));
  }
}

/// Convenience record to enable easy access to typed extensions methods on [ResultNotifier] (or [ResultListenable])
/// (via [ResultListenableQuadrupleMethods]).
typedef ResultListenableQuadruple<A, B, C, D> = (
  ResultListenable<A>,
  ResultListenable<B>,
  ResultListenable<C>,
  ResultListenable<D>
);

/// Record extension providing convenience extension methods.
extension ResultListenableQuadrupleMethods<A, B, C, D> on ResultListenableQuadruple<A, B, C, D> {
  /// {@macro result_iterable_effects.combine}
  Result<R> combine<R>(R Function(A a, B b, C c, D d) combine) {
    return [$1, $2, $3, $4].combine((data) => combine(data[0] as A, data[1] as B, data[2] as C, data[3] as D));
  }

  /// {@macro result_notifier_iterable_effects.combineData}
  R? combineData<R>(R Function(A a, B b, C c, D d) combine) {
    return [$1, $2, $3, $4].combineData((data) => combine(data[0] as A, data[1] as B, data[2] as C, data[3] as D));
  }
}

/// Convenience record to enable easy access to typed extensions methods on [ResultNotifier] (or [ResultListenable])
/// (via [ResultListenableQuintupleMethods]).
typedef ResultListenableQuintuple<A, B, C, D, E> = (
  ResultListenable<A>,
  ResultListenable<B>,
  ResultListenable<C>,
  ResultListenable<D>,
  ResultListenable<E>
);

/// Record extension providing convenience extension methods.
extension ResultListenableQuintupleMethods<A, B, C, D, E> on ResultListenableQuintuple<A, B, C, D, E> {
  /// {@macro result_iterable_effects.combine}
  Result<R> combine<R>(R Function(A a, B b, C c, D d, E e) combine) {
    return [$1, $2, $3, $4, $5]
        .combine((data) => combine(data[0] as A, data[1] as B, data[2] as C, data[3] as D, data[4] as E));
  }

  /// {@macro result_notifier_iterable_effects.combineData}
  R? combineData<R>(R Function(A a, B b, C c, D d, E e) combine) {
    return [$1, $2, $3, $4, $5]
        .combineData((data) => combine(data[0] as A, data[1] as B, data[2] as C, data[3] as D, data[4] as E));
  }
}
