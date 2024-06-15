## 0.5.0

* BREAKING: Removed methods `when`, `whenOr` and `whenData` from `Result` - replace with pattern matching (i.e. 
  `switch`) on `Result`.
* BREAKING: Removed `ResultBuilder` - replace with `ValueListenableBuilder`, method `builder` (on `ResultNotifier` or 
  `ResultListenable`) or the `watch` method (on `ResultNotifier` or `ValueListenable`).
* BREAKING: `future` getter in `ResultNotifier` will now only return a value on `isData` instead of `hasData`.
* Added `future` setter in `ResultNotifier`.
* Removed Disposer typedef and replaced with VoidCallback. 

## 0.4.1+1

* Added relevant topics to `pubspec.yaml`.

## 0.4.1

* Added `updateDataAsync` to `ResultNotifier`, to update the data of a `ResultNotifier` asynchronously without having
  to handle potential exceptions (i.e. the returned Future can be safely ignored, or awaited without try/catch).

## 0.4.0

* Removed `ResultNotifierProvider`.
* Updated `ResourceProvider` to use `WatcherContext` instead of `BuildContext` (in builder and build), to make watching
  easier.

## 0.3.0+1

* Just documentation updates.

## 0.3.0

* Added "watch" functionality, i.e. the possibility to observe a `ResultNotifier` (or any `Listenable`) in a Widget
  without using a `ResultBuilder` or `ValueListenableBuilder` (a bit similar to how `flutter_hooks` works).
* Added extension methods on `Iterable<Result>` and `Iterable<ResultNotifier>` for combining multiple `Result`s into a
  single `Result`, or just combining the data (similar to `CombineLatestNotifier`).
* Added convenience Records extensions for `Result` and `ResultNotifier`, enabling typed use of `combine` and
  `combineData` methods (see `ResultTuple`, `ResultListenableTuple`, etc).
* Added extension methods on `Iterable<Result>` and `Iterable<ResultNotifier>` for getting combined statuses (
  e.g. `isLoading`, `isAllLoading` etc).
* Introduced the abstract type `ResultListenable` and moved some functionality from `ResultNotifier` there.
* Added support for transforming a regular `ValueNotifier`/`ValueListenable` to a `ResultListenable` using
  `ValueListenable.toResultListenable()`.
* Deprecated `ResultNotifierProvider` - use `ResourceProvider` (along with `watch` or `ResultBuilder`) instead.
* Made some arguments required in `ResourceProvider` default constructor and added a second constructor
  (`ResourceProvider.custom`) for subclasses.
* Made `dispose` method in `ResourceProvider` optional, and added default implementation that calls `dispose()` on the
  resource.

## 0.2.1

* Fixed issue with `Result.toData` (and thus `ResultNotifier.toData`) not using the `data` parameter correctly.

## 0.2.0

* Updated `setResultAsync` to always return a `Result`, even if an error occurs.
* Method `cancel` in `ResultNotifier` no longer accepts a `Result` as a parameter.
* Updated API of CombineLatestNotifier (changed constructor and added static factory methods) and removed @expermimental
  annotation.
* Renamed ChainedNotifier to EffectNotifier and removed @expermimental annotation.
* Added effect methods to `ResultNotifier`.

## 0.1.1

* Added lint package and fixed analysis warnings.

## 0.1.0

* Initial release, with basic ResultNotifier functionality.
