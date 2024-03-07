import 'package:flutter/widgets.dart';

import 'result.dart';
import 'result_notifier.dart';

/// Widget builder for [Data] results.
typedef OnDataBuilder<T> = Widget Function(BuildContext context, T data);

/// Widget builder for [Loading] results.
typedef OnLoadingBuilder<T> = Widget Function(BuildContext context, T? data);

/// Widget builder for [Error] results.
typedef OnErrorBuilder<T> = Widget Function(BuildContext context, Object? error, StackTrace? stackTrace, T? data);

/// Catch-all Widget builder for all [Result]s.
typedef OnResultBuilder<T> = Widget Function(BuildContext context, Result<T> result);

/// Convenience class for simplifying use of [ValueListenableBuilder] with [ResultNotifier].
///
/// ResultBuilder facilitates building an appropriate Widget representing the latest [Result] from a ResultNotifier.
///
/// If the creation and disposal lifecycle of the ResultNotifier needs to be managed by the Widget, see instead
/// [ResourceProvider].
class ResultBuilder<T> extends ValueListenableBuilder<Result<T>> {
  /// Creates a ResultBuilder that builds a Widget using the specified builder callbacks corresponding to the different
  /// Result states.
  ///
  /// ResultBuilder listens to the specified [resultNotifier] and builds the Widget using the specified Widget builder
  /// callbacks.
  ResultBuilder(
    ResultNotifier<T> resultNotifier, {
    required OnDataBuilder<T> onData,
    required OnLoadingBuilder<T> onLoading,
    required OnErrorBuilder<T> onError,
    super.key,
  }) : super(
          valueListenable: resultNotifier,
          builder: _builder(onData: onData, onLoading: onLoading, onError: onError),
        );

  /// Creates a ResultBuilder that builds a Widget using a "catch-all" `onResult` callback, and optional callbacks for
  /// the different Result states.
  ///
  /// ResultBuilder listens to the specified [resultNotifier] and builds the Widget using the specified Widget builder
  /// callbacks.
  ResultBuilder.result(
    ResultNotifier<T> resultNotifier, {
    required OnResultBuilder<T> onResult,
    OnDataBuilder<T>? onData,
    OnLoadingBuilder<T>? onLoading,
    OnErrorBuilder<T>? onError,
    super.key,
  })  : assert(!(onData != null && onLoading != null && onError != null), 'All builders cannot be specified at once'),
        super(
          valueListenable: resultNotifier,
          builder: _builder(onData: onData, onLoading: onLoading, onError: onError, onResult: onResult),
        );

  /// Creates a ResultBuilder that builds a Widget when data is available, with a `orElse` fallback when it is not.
  ///
  /// ResultBuilder listens to the specified [resultNotifier] and builds the Widget using the specified Widget builder
  /// callbacks.
  ResultBuilder.data(
    ResultNotifier<T> resultNotifier, {
    required OnDataBuilder<T> hasData,
    required OnResultBuilder<T> orElse,
    super.key,
  }) : super(
          valueListenable: resultNotifier,
          builder: (context, result, _) => result.whenData(
            hasData: (data) => hasData(context, data),
            orElse: (result) => orElse(context, result),
          ),
        );

  static ValueWidgetBuilder<Result<T>> _builder<T>({
    OnDataBuilder<T>? onData,
    OnLoadingBuilder<T>? onLoading,
    OnErrorBuilder<T>? onError,
    OnResultBuilder<T>? onResult,
  }) {
    return (context, result, _) {
      final widget = result.when(
        data: (v) => onData?.call(context, v) ?? onResult?.call(context, result),
        error: (e, st, v) => onError?.call(context, e, st, v) ?? onResult?.call(context, result),
        loading: (v) => onLoading?.call(context, v) ?? onResult?.call(context, result),
      );
      assert(widget != null, 'No widget build for $result');
      return widget ?? const SizedBox.shrink();
    };
  }
}
