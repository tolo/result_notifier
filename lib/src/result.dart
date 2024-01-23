import 'package:flutter/foundation.dart';

import 'exceptions.dart';

/// Result type base class
@immutable
sealed class Result<T> {
  Result._({DateTime? lastUpdate}) : lastUpdate = lastUpdate ?? DateTime.now();

  /// The last data, if any.
  T? get data;

  /// The last time the result was updated.
  final DateTime lastUpdate;

  /// The last error, if any.
  Object? get error => null;

  /// Checks if the result contains data, regardless of the result type. Note that this is different from [isData].
  bool get hasData => data != null;

  /// Checks if the the result is the [Initial] loading state.
  bool get isInitial => this is Initial<T>;

  /// Checks if the the result is [Loading]. Note that the initial state ([Initial]) is also interpreted as a loading state.
  bool get isLoading => this is Loading<T>;

  /// Checks if the data is currently being loaded, i.e. the current state is [Loading] but not [Initial].
  bool get isLoadingData => isLoading && !isInitial;

  /// Checks if data is currently being reloaded, i.e. the current state is [Loading] and [hasData].
  bool get isReloading => isLoadingData && hasData;

  /// Checks if the result is [Data]. Note that this is different from if this notifier currently contains data
  /// (i.e. [hasData]).
  bool get isData => this is Data<T>;

  /// Checks if the current state is [Error].
  bool get isError => this is Error<T>;

  /// Checks if the current state is [Error] and the error is a [CancelledException].
  bool get isCancelled => false;

  Result<T> copyWith({T? data, DateTime? lastUpdate});

  /// Creates a stale copy of this result, meaning [lastUpdate] will be set to zero ms from "epoch".
  Result<T> toStale() => copyWith(lastUpdate: _staleDateTime);

  /// Creates a fresh copy of this result, meaning [lastUpdate] will be set to `DateTime.now()`.
  Result<T> toFresh() => copyWith(lastUpdate: DateTime.now());

  /// {@template result.toData}
  /// Attempts to convert the result to [Data].
  ///
  /// The provided [data] will be used, if specified, otherwise the existing data will be used if possible. If no data
  /// is present, the [orElse] callback will be used, if provided, to produce fallback data. In case of a failure to
  /// produce data, the value will be set to [Error.noData].
  /// {@endtemplate}
  Result<T> toData({T? data, T Function()? orElse, DateTime? lastUpdate}) {
    if (hasData || orElse != null) {
      return Data(
        data ?? this.data ?? orElse!.call(),
        lastUpdate: lastUpdate ?? DateTime.now(),
      );
    } else {
      return Error.noData(lastUpdate: lastUpdate);
    }
  }

  /// {@template result.toLoading}
  /// Attempts to convert the result to [Loading].
  /// {@endtemplate}
  Result<T> toLoading({T? data, DateTime? lastUpdate}) {
    return Loading(
      data: data ?? this.data,
      lastUpdate: lastUpdate ?? DateTime.now(),
    );
  }

  /// {@template result.toInitial}
  /// Attempts to convert the result to the [Initial] loading state.
  /// {@endtemplate}
  Result<T> toInitial({T? data, DateTime? lastUpdate}) {
    return Initial(
      data: data ?? this.data,
      lastUpdate: lastUpdate ?? DateTime.now(),
    );
  }

  /// {@template result.toError}
  /// Attempts to convert the result to [Error].
  /// {@endtemplate}
  Result<T> toError({Object? error, StackTrace? stackTrace, T? data, DateTime? lastUpdate}) {
    return Error(
      error: error ?? ResultNotifierException(message: 'Unknown'),
      stackTrace: stackTrace,
      data: data ?? this.data,
      lastUpdate: lastUpdate ?? DateTime.now(),
    );
  }

  /// {@template result.toError}
  /// Attempts to convert the result to cancellation [Error].
  /// {@endtemplate}
  Result<T> toCancelled({T? data, DateTime? lastUpdate}) {
    return Error.cancelled(
      data: data ?? this.data,
      lastUpdate: lastUpdate ?? DateTime.now(),
    );
  }

  /// Performs an action depending on the type of the current [Result], using the provided callbacks.
  ///
  /// The action can return a new representation of the result.
  X when<X>({
    required X Function(T?) loading,
    required X Function(T) data,
    required X Function(Object, StackTrace?, T?) error,
    X Function(T?)? cancelled,
  }) {
    return switch (this) {
      Data(data: final d) => data(d),
      Error(error: final e, stackTrace: final st, data: final d) =>
        (cancelled != null && isCancelled) ? cancelled(d) : error(e, st, d),
      Loading(data: final d) => loading(d),
    };
  }

  /// Performs an action depending on the type of the current [Result], using the optional provided callbacks.
  ///
  /// The action can return a new representation of the result, or simply null.
  X? whenOr<X>({
    X? Function(T?)? loading,
    X? Function(T)? data,
    X? Function(Object, StackTrace?, T?)? error,
    X Function(T?)? cancelled,
  }) {
    return switch (this) {
      Data(data: final v) => data?.call(v),
      Error(error: final e, stackTrace: final st, data: final d) =>
        (cancelled != null && isCancelled) ? cancelled(d) : error?.call(e, st, d),
      Loading(data: final v) => loading?.call(v),
    };
  }

  /// Performs an action based on the presence of [data], regardless off the type of the Result
  ///
  /// The `hasData` callback will be called if data is present (i.e. [hasData]), if not, the `orElse` callback will be
  /// used.
  X whenData<X>({
    required X Function(T) hasData,
    required X Function(Result<T>) orElse,
  }) {
    return data != null ? hasData(data as T) : orElse(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Result &&
            runtimeType == other.runtimeType &&
            (identical(data, other.data) || data == other.data) &&
            (identical(error, other.error) || error == other.error) &&
            (identical(lastUpdate, other.lastUpdate) || lastUpdate == other.lastUpdate));
  }

  @override
  int get hashCode => Object.hash(runtimeType, data, error, lastUpdate);
}

/// Initial loading/empty state. Inherits from [Loading] and is handled as such in most cases.
final class Initial<T> extends Loading<T> {
  Initial({super.data, super.lastUpdate});

  @override
  Result<T> copyWith({T? data, DateTime? lastUpdate}) =>
      Initial(data: data ?? this.data, lastUpdate: lastUpdate ?? this.lastUpdate);

  @override
  String toString() => 'Initial<$T>(data: $data, lastUpdate: $lastUpdate)';
}

/// Loading
final class Loading<T> extends Result<T> {
  Loading({this.data, super.lastUpdate}) : super._();

  @override
  final T? data;

  @override
  Result<T> copyWith({T? data, DateTime? lastUpdate}) =>
      Loading(data: data ?? this.data, lastUpdate: lastUpdate ?? this.lastUpdate);

  @override
  String toString() => 'Loading<$T>(data: $data, lastUpdate: $lastUpdate)';
}

/// Data
final class Data<T> extends Result<T> {
  Data(this.data, {super.lastUpdate}) : super._();
  Data.stale(this.data) : super._(lastUpdate: _staleDateTime);

  @override
  bool get hasData => true;

  /// The current data.
  @override
  final T data;

  @override
  Result<T> copyWith({T? data, DateTime? lastUpdate}) =>
      Data(data ?? this.data, lastUpdate: lastUpdate ?? this.lastUpdate);

  @override
  String toString() => 'Data<$T>(data: $data, lastUpdate: $lastUpdate)';
}

/// Error
final class Error<T> extends Result<T> {
  Error({required this.error, this.stackTrace, this.data, super.lastUpdate})
      : isCancelled = false,
        super._();
  Error.noData({T? data, DateTime? lastUpdate})
      : this._(error: NoDataException(), isCancelled: false, data: data, lastUpdate: lastUpdate);
  Error.cancelled({T? data, DateTime? lastUpdate})
      : this._(error: CancelledException(), isCancelled: true, data: data, lastUpdate: lastUpdate);
  Error._({required this.error, required this.isCancelled, this.stackTrace, this.data, super.lastUpdate}) : super._();

  @override
  final Object error;
  final StackTrace? stackTrace;
  @override
  final T? data;
  @override
  final bool isCancelled;

  @override
  Result<T> copyWith({T? data, DateTime? lastUpdate}) => Error._(
        error: error,
        stackTrace: stackTrace,
        data: data ?? this.data,
        lastUpdate: lastUpdate ?? this.lastUpdate,
        isCancelled: isCancelled,
      );

  @override
  bool operator ==(Object other) {
    return super == other && other is Error && stackTrace == other.stackTrace && isCancelled == other.isCancelled;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, stackTrace, isCancelled);

  @override
  String toString() => 'Error<$T>(error: $error, stackTrack: $stackTrace, data: $data, lastUpdate: $lastUpdate)';
}

final DateTime _staleDateTime = DateTime.fromMillisecondsSinceEpoch(0);
