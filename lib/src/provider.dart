import 'package:flutter/widgets.dart';

import 'result_notifier.dart';
import 'watcher.dart';

/// Signature for functions that creates a resource.
typedef CreateResource<T> = T Function(BuildContext context);

/// Signature for functions that disposes a resource.
typedef DisposeResource<T> = void Function(BuildContext context, T resource);

/// Signature for functions that builds a Widget using a resource.
typedef ResourceWidgetBuilder<T> = Widget Function(WatcherContext context, T resource);

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
class ResourceProvider<T> extends StatefulWatcherWidget {
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
  Widget build(WatcherContext context, T resource) {
    if (_builder != null) {
      return _builder(context, resource);
    } else {
      throw UnimplementedError('Provide a builder function or override this method in a subclass.');
    }
  }

  @override
  WatcherState createState() => ResourceProviderState();

  /// Finds the nearest ancestor resource of type T in the Widget tree.
  static T of<T>(BuildContext context) => _ResourceInheritedWidget.of<T>(context).resource;
}

/// The state of a [ResourceProvider].
class ResourceProviderState<T> extends WatcherState<ResourceProvider<T>> {
  late final T resource = widget.createResource(context);

  @override
  void dispose() {
    widget.disposeResource(context, resource);
    super.dispose();
  }

  @override
  Widget build(WatcherContext context) {
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
