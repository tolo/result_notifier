import 'package:flutter/material.dart';

import 'result.dart';
import 'result_notifier.dart';
import 'watcher.dart';

/// Signature for functions that creates a resource.
typedef CreateResource<T> = T Function(BuildContext context);

/// Signature for functions that disposes a resource.
typedef DisposeResource<T> = void Function(BuildContext context, T resource);

/// Signature for functions that builds a Widget using a resource.
typedef ResourceWidgetBuilder<T> = Widget Function(BuildContext context, T resource);

/// Convenience extensions on BuildContext that adds lookup of a resource provided by a [ResourceProvider].
extension ResourceProviderContext on BuildContext {
  /// Finds the nearest ancestor resource of type T in the Widget tree.
  T resource<T>() => ResourceProvider.of(this);

  /// Finds the nearest ancestor resource of type T in the Widget tree.
  ResultNotifier<T> notifier<T>() => ResourceProvider.of(this);
}

/// Stateful convenience Widget that manages the lifecycle (creation and disposal) of a resource and makes it available
/// when building this Widget, as well as to all descendant Widgets (see [of]).
///
/// ResourceProvider can be used in two ways - either by subclassing and overriding the [createResource],
/// [disposeResource] and [build] methods, or by providing the `create`, `dispose` and `builder` parameters in the
/// constructor.
class ResourceProvider<T> extends StatefulWidget with StatefulWatcherMixin {
  /// Creates a ResourceProvider with callbacks for creating and disposing (optional) the resource as well as building a
  /// Widget using the resource.
  ///
  /// If `dispose` is not provided (and [disposeResource] is not overridden), the resource is expected to implement a
  /// `void dispose()` method.
  const ResourceProvider({
    super.key,
    required CreateResource<T> create,
    required ResourceWidgetBuilder<T> builder,
    DisposeResource<T>? dispose,
  })  : _create = create,
        _dispose = dispose,
        _builder = builder,
        super();

  /// Constructor for subclasses that provide implementations for [createResource], [disposeResource] (optional) and
  /// [build].
  @protected
  const ResourceProvider.custom({
    super.key,
    CreateResource<T>? create,
    ResourceWidgetBuilder<T>? builder,
    DisposeResource<T>? dispose,
  })  : _create = create,
        _dispose = dispose,
        _builder = builder,
        super();

  final CreateResource<T>? _create;
  final DisposeResource<T>? _dispose;
  final ResourceWidgetBuilder<T>? _builder;

  /// Creates the resource.
  T createResource(BuildContext context) {
    if (_create != null) {
      return _create(context);
    } else {
      throw UnimplementedError('Provide a create function or override this method in a subclass.');
    }
  }

  /// Disposes the resource.
  ///
  /// If a `dispose` function was not provided when creating this ResourceProvider, the resource is expected to
  /// implement a `void dispose()` method.
  void disposeResource(BuildContext context, T resource) {
    if (_dispose != null) {
      _dispose(context, resource);
    } else if (resource is ChangeNotifier) {
      resource.dispose();
    } else {
      (resource as dynamic).dispose(); // ignore: avoid_dynamic_calls
      throw UnimplementedError('Provide a dispose function or override this method in a subclass.');
    }
  }

  /// Builds this Widget with the specified resource.
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

/// Widget builder function for [ResultNotifierProvider].
@Deprecated('as of 0.3.0')
typedef OnResultNotifierBuilder<T> = Widget Function(BuildContext context, ResultNotifier<T>, Result<T> result);

/// Convenience subclass of [ResourceProvider] that simplifies the creation, disposal and use of a [ResultNotifier],
/// through the use of a [ValueListenableBuilder].
///
/// The [ValueListenableBuilder] class is used to listen for changes in the ResultNotifier, and build a Widget using
/// the [buildResult] method. The default implementation of this method called the provided [resultBuilder], if any,
/// otherwise a [UnimplementedError] is thrown.
///
/// Another option is to instead override the [build] method, which can be useful if the use of [ResultNotifier] needs
/// to be further customized.
@Deprecated('as of 0.3.0, use ResourceProvider instead')
class ResultNotifierProvider<T> extends ResourceProvider<ResultNotifier<T>> {
  @Deprecated('as of 0.3.0, use ResourceProvider.notifier instead')
  const ResultNotifierProvider({super.key, required CreateResource<ResultNotifier<T>> create, this.resultBuilder})
      : super.custom(create: create);

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
