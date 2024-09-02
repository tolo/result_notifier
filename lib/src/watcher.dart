import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'result.dart';
import 'result_notifier.dart';

// WatcherRef

/// A reference object that enables support for watching [Listenable]s within a Widget.
///
/// A WatcherRef is always associated with a particular [WatcherWidget] (or [WatcherMixin] / [StatefulWatcherMixin]),
/// and is only valid within the `build` method of that Widget.
///
/// See also:
/// - [WatcherContext], a [BuildContext] subclass that implements `WatcherRef`.
abstract class WatcherRef {
  /// {@template watch_ref.watch}
  /// Watches the given [listenable] (i.e. [Listenable.addListener]) and rebuilds the widget whenever it notifies its
  /// listeners.
  ///
  /// **NOTE**: This method must only be called from within the `build` method of a [WatcherWidget], or a Widget that
  /// mixes in [WatcherMixin] / [StatefulWatcherMixin].
  /// {@endtemplate}
  void watch(Listenable listenable);
}

/// A [BuildContext] that implements [WatcherRef].
abstract class WatcherContext extends BuildContext implements WatcherRef {}

// Listenable extensions

/// [ResultNotifier] extension that adds observability (i.e. [watch] method).
extension ResultNotifierWatcher<T> on ResultNotifier<T> {
  /// {@macro listenable_watcher.watch}
  ///
  /// Returns the current result ([value]) of this [ResultNotifier].
  Result<T> watch(WatcherRef ref) {
    ref.watch(this);
    return value;
  }
}

/// [ValueListenable] extension that adds observability (i.e. [watch] method).
extension ValueListenableWatcher<T> on ValueListenable<T> {
  /// {@macro listenable_watcher.watch}
  ///
  /// Returns the current [value] of this `ValueListenable`.
  T watch(WatcherRef ref) {
    ref.watch(this);
    return value;
  }
}

/// [Listenable] extension that adds observability (i.e. [watch] method).
extension ListenableWatcher on Listenable {
  /// {@template listenable_watcher.watch}
  /// Starts watching this object for changes (i.e. [Listenable.addListener]) and rebuilds the widget associated with
  /// the provided [WatcherRef] whenever listeners are notified.
  ///
  /// **NOTE**: This method must only be called from within the `build` method of a [WatcherWidget], or a Widget that
  /// mixes in [WatcherMixin] / [StatefulWatcherMixin].
  /// {@endtemplate}
  void watch(WatcherRef ref) => ref.watch(this);

  VoidCallback _subscribe(VoidCallback listener) {
    addListener(listener);
    return () => removeListener(listener);
  }
}

// StatelessWidgets and mixins

/// Mixin to add observability of [Listenable]s to a [StatelessWidget].
///
/// **NOTE**: This mixin creates a custom [StatelessElement] (i.e. overrides [createElement]) - make sure to only use it
/// with a `StatelessWidget`s that doesn't also customize the `Element` implementation.
///
/// See also:
/// - [StatefulWatcherMixin]
/// - [WatcherWidget]
/// - [Watcher]
mixin WatcherMixin on StatelessWidget {
  @override
  StatelessElement createElement() => _ListenableWatcherStatelessElement(this);

  /// {@template watcher.ref}
  /// Object that provides support for watching [Listenable]s within a Widget.
  ///
  /// **NOTE**: The returned [WatcherRef] is only valid within the `build` of this Widget.
  ///
  /// See also:
  /// - [WatcherRef.watch]
  /// {@endtemplate}
  WatcherRef get ref => _ListenableWatcherElement._currentElement!;
}

/// Stateless widget that adds observability of [Listenable]s, through the [WatcherContext] (a [BuildContext] subclass)
/// provided to the [build] method.
///
/// See also:
/// - [Watcher]
/// - [WatcherMixin]
/// - [StatefulWatcherMixin]
abstract class WatcherWidget extends StatelessWidget with WatcherMixin {
  const WatcherWidget({super.key});

  @override
  Widget build(covariant WatcherContext context);
}

/// Stateless widget that supports watching `Listenable`s within a provided [builder] function.
///
/// Examole:
/// ```
/// Watcher(builder: (context) {
///   final result = notifier.watch(context);
///   return Text(switch (result) {
///     Data(data: var d) => d,
///     Error(error: var e, data: var d) => 'Error ($e) - $d',
///     Loading(data: var d) => d != null ? 'Loading - $d' : 'Loading...',
///   });
/// })
/// ```
///
/// See also:
/// - [WatcherWidget]
/// - [WatcherMixin]
/// - [StatefulWatcherMixin]
class Watcher extends WatcherWidget {
  const Watcher({required this.builder, super.key});

  /// A widget builder in which it's possible to watch `Listenable`s, using the `watch` extension method.
  final Widget Function(WatcherContext context) builder;

  @override
  Widget build(WatcherContext context) {
    return builder(context);
  }
}

// StatefulWidgets and mixins

/// Mixin to add observability of [Listenable]s to a [StatefulWidget].
///
/// **NOTE**: This mixin creates a custom [StatefulElement] (i.e. overrides [createElement]) - make sure to only use it
/// with a `StatefulWidget`s that doesn't also customize the `Element` implementation.
///
/// See also:
/// - [WatcherMixin]
/// - [WatcherWidget]
/// - [Watcher]
mixin StatefulWatcherMixin on StatefulWidget {
  @override
  StatefulElement createElement() => _ListenableWatcherStatefulElement(this);

  /// {@macro watcher.ref}
  WatcherRef get ref => _ListenableWatcherElement._currentElement!;
}

/// Stateful widget that adds observability of [Listenable]s, through the [WatcherContext] (a [BuildContext] subclass)
/// provided to the `build` method of the associated [WatcherState].
///
/// See also:
/// - [WatcherState]
/// - [StatefulWatcherMixin]
abstract class StatefulWatcherWidget extends StatefulWidget with StatefulWatcherMixin {
  const StatefulWatcherWidget({super.key});

  @override
  WatcherState createState() => createState(); // ignore: no_logic_in_create_state
}

/// The [State] of a [StatefulWatcherWidget], that adds observability of [Listenable]s, through the [WatcherContext]
/// (a [BuildContext] subclass) provided to the [build] method.
abstract class WatcherState<T extends StatefulWatcherMixin> extends State<T> {
  @override
  Widget build(covariant WatcherContext context);
}

// Element implementations

class _ListenableWatcherStatelessElement extends StatelessElement with _ListenableWatcherElement {
  _ListenableWatcherStatelessElement(super.widget);
}

class _ListenableWatcherStatefulElement extends StatefulElement with _ListenableWatcherElement {
  _ListenableWatcherStatefulElement(super.widget);
}

mixin _ListenableWatcherElement on ComponentElement implements WatcherContext {
  static _ListenableWatcherElement? _currentElement;

  final _listenablesInUse = HashSet<Listenable>.identity();
  final _subscriptions = HashMap<Listenable, VoidCallback>.identity();

  void _disposeUnused() {
    _subscriptions.removeWhere((listenable, disposer) {
      if (!_listenablesInUse.contains(listenable)) {
        disposer();
        return true;
      }
      return false;
    });
  }

  @override
  void watch(Listenable listenable) {
    assert(_currentElement == this, '''
    The `watch` method can only be called from the build method of a widget that mix-in `WatcherMixin` or `StatefulWatcherMixin`.
    ''');

    VoidCallback subscribe() {
      return listenable._subscribe(() {
        if (_subscriptions[listenable] != null) {
          markNeedsBuild();
        }
      });
    }

    _subscriptions[listenable] ??= subscribe();
    _listenablesInUse.add(listenable);
  }

  void unwatch(Listenable listenable) {
    _listenablesInUse.remove(listenable);
    final disposer = _subscriptions.remove(listenable);
    disposer?.call();
  }

  @override
  void unmount() {
    for (final disposer in _subscriptions.values) {
      disposer();
    }
    _subscriptions.clear();
    super.unmount();
  }

  // Widget _buildWithScope(Widget Function() buildFunc) {
  @override
  Widget build() {
    _listenablesInUse.clear();
    _currentElement = this;
    Widget result;
    try {
      result = super.build();
    } finally {
      _currentElement = null;
      _disposeUnused();
    }
    return result;
  }
}
