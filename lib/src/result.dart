import 'package:flutter/foundation.dart';

import 'exceptions.dart';

/// Result is the base class of an enumerable set of subtypes that represent the different states involved in fetching
/// data for a [ResultNotifier].
///
/// A result can be in one of the following states:
/// - **[Loading]**: Represents a loading/reloading state, along with the *previous* data, if any.
/// - **[Data]**: The result contains some concrete data.
/// - **[Error]**: Represents an error, along with the *previous* data, if any.
///
/// There is also a special [Initial] state, which is used as a default state when no other state has been set. This
/// state inherits from [Loading] and is handled as such in most cases.
///
/// `Result` provides a number of methods for checking (properties of) the current state as well as converting between
/// the different states. It also provides a number of methods for performing actions based on the current state, for
/// instance [when]. Example:
///
/// ```
/// result.when(
///   loading: (data) => const CircularProgressIndicator(),
///   error: (error, stackTrace, data) => Text('Error: $error'),
///   data: (data) => Text(data),
/// ),
/// ```
@immutable
sealed class Result<T> {
  Result._({DateTime? lastUpdate}) : lastUpdate = lastUpdate ?? DateTime.now();

  /// The last data, if any.
  T? get data;

  /// {@template result.lastUpdate}
  /// The last time the result was updated.
  /// {@endtemplate}
  final DateTime lastUpdate;

  /// The last error, if any.
  Object? get error => null;

  /// {@template result.hasData}
  /// Checks if the result contains data, regardless of the result type. Note that this is different from [isData].
  /// {@endtemplate}
  bool get hasData => data != null;

  /// {@template result.isInitial}
  /// Checks if the the result is the [Initial] loading state.
  /// {@endtemplate}
  bool get isInitial => this is Initial<T>;

  /// {@template result.isLoading}
  /// Checks if the the result is [Loading]. Note that the initial state ([Initial]) is also interpreted as a loading state.
  /// {@endtemplate}
  bool get isLoading => this is Loading<T>;

  /// {@template result.isLoadingData}
  /// Checks if the data is currently being loaded, i.e. the current state is [Loading] but not [Initial].
  /// {@endtemplate}
  bool get isLoadingData => isLoading && !isInitial;

  /// {@template result.isReloading}
  /// Checks if data is currently being reloaded, i.e. the current state is [Loading] and [hasData].
  /// {@endtemplate}
  bool get isReloading => isLoadingData && hasData;

  /// {@template result.isData}
  /// Checks if the result is [Data]. Note that this is different from if this notifier currently contains data
  /// (i.e. [hasData]).
  /// {@endtemplate}
  bool get isData => this is Data<T>;

  /// {@template result.isError}
  /// Checks if the current state is [Error].
  /// {@endtemplate}
  bool get isError => this is Error<T>;

  /// {@template result.isCancelled}
  /// Checks if the current state is [Error] and the error is a [CancelledException].
  /// {@endtemplate}
  bool get isCancelled => false;

  /// Creates a copy of this result with the provided values.
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
    if (hasData || data != null || orElse != null) {
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

  /// {@template result.toCancelled}
  /// Attempts to convert the result to cancellation [Error].
  /// {@endtemplate}
  Result<T> toCancelled({T? data, DateTime? lastUpdate}) {
    return Error.cancelled(
      data: data ?? this.data,
      lastUpdate: lastUpdate ?? DateTime.now(),
    );
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

/// Represents a loading/reloading state, along with the previous data, if any.
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

/// Represents a result containing actual data.
final class Data<T> extends Result<T> {
  /// Creates a Data, with a last update time set to the current time (i.e. fresh).
  Data(this.data, {super.lastUpdate}) : super._();

  /// Creates a Data, with a last update time set to a value indicating stale data (i.e. needing refresh).
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

/// Represents an error, along with the previous data, if any.
final class Error<T> extends Result<T> {
  /// Created a Error.
  Error({required this.error, this.stackTrace, this.data, super.lastUpdate}) : super._();

  /// Creates a Error indicating there was no data ([NoDataException]).
  Error.noData({this.data, super.lastUpdate})
      : error = NoDataException(),
        stackTrace = null,
        super._();

  /// Creates a Error indicating a cancelled operation ([CancelledException]).
  Error.cancelled({this.data, super.lastUpdate})
      : error = CancelledException(),
        stackTrace = null,
        super._();

  /// Creates a Error indicating a disposed notifier ([DisposedException]).
  Error.disposed({this.data, super.lastUpdate})
      : error = DisposedException(),
        stackTrace = null,
        super._();

  @override
  final Object error;
  final StackTrace? stackTrace;
  @override
  final T? data;

  @override
  bool get isCancelled => error is CancelledException;

  bool get isDisposed => error is DisposedException;

  bool get isNoData => error is NoDataException;

  @override
  Result<T> copyWith({T? data, DateTime? lastUpdate}) => Error(
        error: error,
        stackTrace: stackTrace,
        data: data ?? this.data,
        lastUpdate: lastUpdate ?? this.lastUpdate,
      );

  @override
  bool operator ==(Object other) {
    return super == other && other is Error && error == other.error && stackTrace == other.stackTrace;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, error, stackTrace, isCancelled);

  @override
  String toString() => 'Error<$T>(error: $error, stackTrack: $stackTrace, data: $data, lastUpdate: $lastUpdate)';
}

final DateTime _staleDateTime = DateTime.fromMillisecondsSinceEpoch(0);
