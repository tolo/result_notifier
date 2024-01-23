import 'package:flutter/material.dart';

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
/// [ResultNotifierProvider].
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

/// Widget builder function for [ResultNotifierProvider].
typedef OnResultNotifierBuilder<T> = Widget Function(BuildContext context, ResultNotifier<T>, Result<T> result);

/// Stateful convenience Widget that simplifies the creation, disposal and use of a [ResultNotifier], through the use
/// of a [ValueListenableBuilder].
///
/// The [ValueListenableBuilder] class is used to listen for changes in the ResultNotifier, and build a Widget using
/// the [buildResult] method. The default implementation of this method called the provided [resultBuilder], if any,
/// otherwise a [UnimplementedError] is thrown.
///
/// Another option is to instead override the [build] method, which can be useful if the use of [ResultNotifier] needs
/// to be further customized.
class ResultNotifierProvider<T> extends ResourceProvider<ResultNotifier<T>> {
  const ResultNotifierProvider({super.key, super.create, this.resultBuilder});

  /// An optional builder function, used by [buildResult] to build the the child Widget of this ResultNotifierProvider.
  final OnResultNotifierBuilder<T>? resultBuilder;

  @override
  void disposeResource(BuildContext context, ResultNotifier<T> resource) {
    resource.dispose();
  }

  /// Builds this Widget with the specified [Result].
  ///
  /// This method is called by the [ValueListenableBuilder] created by the [build] method.
  Widget buildResult(BuildContext context, ResultNotifier<T> resultNotifier, Result<T> result) {
    if (resultBuilder != null) {
      return resultBuilder!(context, resultNotifier, result);
    } else {
      throw UnimplementedError('Provide a resultBuilder of override this method in a subclass.');
    }
  }

  @override
  Widget build(BuildContext context, ResultNotifier<T> resource) {
    return ValueListenableBuilder(
      valueListenable: resource,
      builder: (context, result, _) => buildResult(context, resource, result),
    );
  }

  /// Finds the nearest ancestor [ResultNotifier] with result type T in the Widget tree.
  static ResultNotifier<T> of<T>(BuildContext context) => ResourceProvider.of<ResultNotifier<T>>(context);
}

/// Signature for functions that creates a resource.
typedef CreateResource<T> = T Function(BuildContext context);

/// Signature for functions that disposes a resource.
typedef DisposeResource<T> = void Function(BuildContext context, T);

/// Signature for functions that builds a Widget using a resource.
typedef ResourceWidgetBuilder<T> = Widget Function(BuildContext context, T);

/// Stateful convenience Widget that manages the lifecycle (creation and disposal) of a resource and making it available
/// when building this Widget, as well as to all descendant Widgets (see [of]).
///
/// ResourceProvider can be used in two ways - either by subclassing and overriding the [createResource],
/// [disposeResource] and [build] methods, or by providing the `create`, `dispose` and `builder` parameters in the
/// constructor.
class ResourceProvider<T> extends StatefulWidget {
  /// Creates a ResourceProvider with optional callbacks for creating and disposing the resource as well as building a
  /// Widget using the resource.
  const ResourceProvider({
    super.key,
    CreateResource<T>? create,
    DisposeResource<T>? dispose,
    ResourceWidgetBuilder? builder,
  })  : _create = create,
        _dispose = dispose,
        _builder = builder,
        super();

  final CreateResource<T>? _create;
  final DisposeResource<T>? _dispose;
  final ResourceWidgetBuilder? _builder;

  T createResource(BuildContext context) {
    if (_create != null) {
      return _create(context);
    } else {
      throw UnimplementedError('Provide a create function or override this method in a subclass.');
    }
  }

  void disposeResource(BuildContext context, T resource) {
    if (_dispose != null) {
      _dispose(context, resource);
    } else {
      throw UnimplementedError('Provide a dispose function or override this method in a subclass.');
    }
  }

  Widget build(BuildContext context, T resource) {
    if (_builder != null) {
      return _builder(context, resource);
    } else {
      throw UnimplementedError('Provide a builder function or override this method in a subclass.');
    }
  }

  @override
  State<StatefulWidget> createState() => ResourceProviderState();

  /// Finds the nearest ancestor resource of type T in the Widget tree.
  static T of<T>(BuildContext context) => _ResourceInheritedWidget.of<T>(context).resource;
}

/// The state of a [ResourceProvider].
class ResourceProviderState<T> extends State<ResourceProvider<T>> {
  late final T resource = widget.createResource(context);

  @override
  void dispose() {
    widget.disposeResource(context, resource);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ResourceInheritedWidget(resource: resource, child: widget.build(context, resource));
  }
}

class _ResourceInheritedWidget<T> extends InheritedWidget {
  const _ResourceInheritedWidget({super.key, required this.resource, required super.child});

  final T resource;

  @override
  bool updateShouldNotify(_ResourceInheritedWidget<T> oldWidget) => oldWidget.resource != resource;

  static _ResourceInheritedWidget<T> of<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ResourceInheritedWidget<T>>()!;
  }
}
