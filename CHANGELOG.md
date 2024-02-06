## 0.1.0

* Initial release, with basic ResultNotifier functionality.

## 0.1.1

* Added lint package and fixed analysis warnings.

## 0.2.0

* Updated `setResultAsync` to always return a `Result`, even if an error occurs.
* Method `cancel` in `ResultNotifier` no longer accepts a `Result` as a parameter.
* Updated API of CombineLatestNotifier (changed constructor and added static factory methods) and removed @expermimental annotation.
* Renamed ChainedNotifier to EffectNotifier and removed @expermimental annotation.
* Added effect methods to `ResultNotifier`.
 