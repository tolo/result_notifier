import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

import 'result.dart';
import 'result_notifier.dart';

typedef CreateResultNotifier<K, T> = ResultNotifier<T> Function(K key, ResultStore<K, T> store);
typedef ResultNotifierOnDispose<K, T> = void Function(K key, ResultNotifier<T> strore);

typedef _CacheEntry<T> = ({ResultNotifier<T> notifier, Disposer removeListener});

/// A [ChangeNotifier] that creates and caches [ResultNotifier]s for a given key, and optionally disposes them when
/// they are no longer used.
///
/// Listeners are notified ([notifyListeners]) when any of the cached [ResultNotifier]s changes value. To build a Widget
/// that responds to these changes, simply use [ListenableBuilder].
///
/// Typical use cases for this class are pagination or when the result for parameterized/keyed API calls need to be
/// cached.
class ResultStore<K, T> extends ChangeNotifier {
  // TODO: Needs tests and more documentation.
  /// Creates a [ResultStore] that creates [ResultNotifier]s using the provided [create] function.
  ResultStore({
    required this.create,
    this.onDispose,
    bool autoDispose = true,
    this.autoDisposeTimerInterval = const Duration(minutes: 1),
  }) : willAutoDispose = autoDispose;

  /// Function used to create a new [ResultNotifier] for a specific key of type K .
  final CreateResultNotifier<K, T> create;

  /// Optional function called whenever a [ResultNotifier] is disposed.
  final ResultNotifierOnDispose<K, T>? onDispose;

  /// Whether or not to automatically [ResultNotifier.dispose] ResultNotifiers when there are no listeners. If this flag
  /// is set to true, all cached [ResultNotifier]s will also be disposed whenever the ResultStore itself is disposed.
  final bool willAutoDispose;

  /// The interval used by the auto dispose timer. Defaults to one minute.
  final Duration autoDisposeTimerInterval;

  final Map<K, _CacheEntry<T>> _cache = {};

  ({K key, Result<T> result})? _currentModification;

  @visibleForTesting
  Timer? autoDisposeTimer;

  /// The current number of notifiers in the store.
  int get length => _cache.length;

  DateTime _lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime get lastUpdate => _lastUpdate;

  @override
  void dispose() {
    _cache.forEach((key, cacheEntry) => _disposeNotifier(key, cacheEntry, willAutoDispose));
    _cache.clear();
    autoDisposeTimer?.cancel();
    super.dispose();
  }

  /// Registers a listener ([addListener]) that will be invoked with the key and result of the last modified
  /// [ResultNotifier], whenever one is modified.
  @useResult
  Disposer onResult(void Function(K key, Result<T> result) callback) {
    void listener() {
      final modification = _currentModification;
      if (modification != null) {
        callback(modification.key, modification.result);
      }
    }

    addListener(listener);
    return () => removeListener(listener);
  }

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _updateAutoDisposeTimer();
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners && willAutoDispose) {
      clear();
    } else {
      _updateAutoDisposeTimer();
    }
  }

  @protected
  @visibleForTesting
  ResultNotifier<T> getNotifier(K key, {bool shouldRefresh = false, bool force = false, bool alwaysTouch = false}) {
    var notifier = _cache[key]?.notifier;
    if (notifier != null && shouldRefresh) {
      Future.microtask(() => notifier!.isActive ? notifier.refresh(force: force, alwaysTouch: alwaysTouch) : null);
    } else if (notifier == null) {
      notifier = (_cache[key] = _createNotifier(key)).notifier;
      _updateAutoDisposeTimer();
    }
    return notifier;
  }

  /// Attempts to get the current data of the [ResultNotifier] with the specified key.
  ///
  /// If no such ResultNotifier exists, a new one will be created using the [create] function.
  ///
  /// See [ResultNotifier.data].
  T data(K key) {
    return getNotifier(key).data;
  }

  /// Gets the data, if any, of the [ResultNotifier] with the specified key.
  ///
  /// If no such ResultNotifier exists, a new one will be created using the [create] function.
  ///
  /// See [ResultNotifier.dataOrNull].
  T? dataOrNull(K key) {
    return getNotifier(key).dataOrNull;
  }

  /// Gets the current [ResultNotifier.value], of the ResultNotifier with the specified key.
  ///
  /// If no such ResultNotifier exists, a new one will be created using the [create] function.
  ///
  /// To get the value without creating a new ResultNotifier, use [read] instead.
  Result<T> value(K key) {
    return getNotifier(key).value;
  }

  /// Just an alias for [value].
  Result<T> result(K key) => value(key);

  /// Attempts to find a cached [ResultNotifier] for the specified key, and return its [ResultNotifier.value].
  ///
  /// Returns null if no such [ResultNotifier] exists in cache.
  Result<T>? read(K key) {
    return _cache[key]?.notifier.value;
  }

  /// Refreshes the [ResultNotifier] with the specified key, if needed.
  ///
  /// See [ResultNotifier.refresh] for more information.
  void refresh(K key, {bool force = false, bool alwaysTouch = false}) {
    getNotifier(key, shouldRefresh: true, force: force, alwaysTouch: alwaysTouch);
  }

  /// Refreshes the [ResultNotifier] with the specified key, if needed, and awaits the result.
  ///
  /// See [ResultNotifier.refreshAwait] for more information.
  Future<T> refreshAwait(K key, {bool force = false, bool alwaysTouch = false}) {
    return getNotifier(key, shouldRefresh: true, force: force, alwaysTouch: alwaysTouch).future;
  }

  /// Cancels any ongoing fetch operation for the ResultNotifier with the specified key.
  ///
  /// See [ResultNotifier.cancel] for more information.
  Result<T>? cancel(K key, {bool always = false}) {
    _cache[key]?.notifier.cancel(always: always);
    return read(key);
  }

  /// Invalidates the ResultNotifier with the specified key.
  ///
  /// See [ResultNotifier.invalidate] for more information.
  void invalidate(K key) {
    _cache[key]?.notifier.invalidate();
  }

  /// Invalidates all cached ResultNotifiers.
  ///
  /// See [ResultNotifier.invalidate] for more information.
  void invalidateAll() {
    _cache.forEach((key, cacheEntry) => cacheEntry.notifier.invalidate());
  }

  /// Touches the ResultNotifier with the specified key.
  ///
  /// See [ResultNotifier.touch] for more information.
  void touch(K key) {
    _cache[key]?.notifier.touch();
  }

  /// Removes all cached ResultNotifiers, and disposes them if parameter `disposeNotifiers` or [willAutoDispose] is true.
  void clear({bool? disposeNotifiers}) {
    _cache.forEach((key, cacheEntry) => _disposeNotifier(key, cacheEntry, disposeNotifiers ?? willAutoDispose));
    _cache.clear();
    _updateAutoDisposeTimer();
  }

  _CacheEntry<T> _createNotifier(K key) {
    void onNotifierResult(Result<T> result) {
      _currentModification = (key: key, result: result);
      _lastUpdate = _lastUpdate.isBefore(result.lastUpdate) ? result.lastUpdate : _lastUpdate;
      try {
        notifyListeners();
      } finally {
        _currentModification = null;
      }
    }

    final notifier = create(key, this);
    // If the notifier is in the initial state, it will be refreshed by onResult/addListener below. But if not, we need
    // to touch it to trigger the lister for the first time when a new ResultNotifier is created.
    final needsTouch = !notifier.isInitial;
    final disposer = notifier.onResult(onNotifierResult);
    if (needsTouch) Future.microtask(() => notifier.isActive ? notifier.touch() : null);

    return (notifier: notifier, removeListener: disposer);
  }

  void _disposeNotifier(K key, _CacheEntry<T> cacheEntry, bool disposeNotifiers) {
    cacheEntry.removeListener();
    if (disposeNotifiers) {
      onDispose?.call(key, cacheEntry.notifier);
      cacheEntry.notifier.dispose();
    }
  }

  void _updateAutoDisposeTimer() {
    final useAutoDisposeTimer = hasListeners && _cache.isNotEmpty && willAutoDispose;
    if (useAutoDisposeTimer && autoDisposeTimer == null) {
      autoDisposeTimer = Timer.periodic(autoDisposeTimerInterval, (_) => _autoDisposeIfNeeded());
    } else if (!useAutoDisposeTimer) {
      autoDisposeTimer?.cancel();
      autoDisposeTimer = null;
    }
  }

  void _autoDisposeIfNeeded() {
    for (final e in _cache.entries.toList()) {
      final cacheEntry = e.value;
      if (cacheEntry.notifier.isStale) {
        _disposeNotifier(e.key, cacheEntry, true);
        _cache.remove(e.key);
      }
    }

    _updateAutoDisposeTimer();
  }
}
