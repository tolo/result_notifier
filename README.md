# Result Notifier

**Pragmatic quality-of-life enhancements to vanilla Flutter state management - simply [lagom](https://en.wikipedia.org/wiki/Lagom).**

![result_notifier.png](https://raw.githubusercontent.com/tolo/result_notifier/main/doc/assets/result_notifier.jpg)

**Result Notifier** is a simple and modest package for enhancing the state management that Flutter already provides out 
of the box. In other words, it's based on familiar and platform-native concepts, rather than introducing new 
abstractions and mental models. In fact, the package really is little more than a few additions to [ValueNotifier](https://api.flutter.dev/flutter/foundation/ValueNotifier-class.html) 
and [ChangeNotifier](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html) (ok, perhaps slightly more than a few, but nothing crazy). As the name of this package
alludes to, one of the most important additions is the concept of a **Result** type, which can represent either some
**Data**, an **Error** or a **Loading** state.

[![style: lint](https://img.shields.io/badge/style-lint-4BC0F5.svg)](https://pub.dev/packages/lint)

_**Note: v0.5.0 contains breaking changes - see [changelog](https://pub.dev/packages/result_notifier/changelog).**_


## The essence of Result Notifier

There are basically four concepts that
make **[ResultNotifier](https://pub.dev/documentation/result_notifier/latest/result_notifier/ResultNotifier-class.html)**
different from `ValueNotifier` and `ChangeNotifier`:

* It holds a **[Result](https://pub.dev/documentation/result_notifier/latest/result_notifier/Result-class.html)** value (an [algebraic data type](https://dart.dev/language/patterns#algebraic-data-types)) 
  and provides methods for accessing and mutating the value. The value (result) can be in one of three different states:
    - **[Data](https://pub.dev/documentation/result_notifier/latest/result_notifier/Data-class.html)**: The result contains some concrete data.
    - **[Error](https://pub.dev/documentation/result_notifier/latest/result_notifier/Error-class.html)**: Represents an error, along with the *previous* data, if any.
    - **[Loading](https://pub.dev/documentation/result_notifier/latest/result_notifier/Loading-class.html)**: Represents a loading/reloading state, along with the *previous* data, if any.
* It's **refreshable** - by providing a synchronous or asynchronous "fetcher" function, you can specify how the data should 
  be refreshed when needed (or stale).
* It's **cacheable** - by setting a `cacheDuration`, you can specify how long the data should be cached before it's
  considered stale.
* It's **composable** - you can easily combine the data of multiple `ResultNotifier`s (and even other `ValueListenable`s)
  using `CombineLatestNotifier` or for instance apply an effect using `EffectNotifier`. 

### Algebraic data types support in `Result`
As mentioned above, `Result` is an algebraic data type, which means you can use it in switch statements like this: 

```dart
switch (result) {
  Data(data: var d, lastUpdate: var t) => Text(d),
  Error(error: var e, stackTrace: var s, data: var d, lastUpdate: var t) => Text('Error: $e'),
  Loading(data: var d, lastUpdate: var t) => const CircularProgressIndicator(), 
}
```

...or simply like this (whatever floats your boat): 

```dart
switch (result) {
  (Data d) => Text(d.data),
  (Error e) => Text('Error: ${e.error}'),
  (_) => const CircularProgressIndicator()
}
```
<br/>

## Getting Started

1. Simply [add the dependency](https://pub.dev/packages/result_notifier/install) and start writing some notifiers!
2. Dive into the starter [example](https://pub.dev/packages/result_notifier/example) (see more [here](https://github.com/tolo/result_notifier/blob/main/example/lib)) 
   <br/>**Or** - just follow along below for a quick introduction to the basic concepts of Result Notifier. 👇


### A simple start

The simplest form of notifier only holds a value, much like a `ValueNotifier`. But with `ResultNotifier`, the value is
wrapped in a `Result` type, which can represent either some data, an error, or a loading state.

```dart
final notifier = ResultNotifier<String>(data: 'Hello...');
print(notifier.data); // Prints 'Hello...'
print(notifier.result); // Prints 'Data<String>(data: Hello..., lastUpdate: 2024-01-02 03:04:05.000006)'

notifier.toLoading(); // Convenience method to set the value to Loading, keeping the previous data.
// Example use of some of the read-only properties for getting the current state of the notifier:
notifier.isLoading;
notifier.isData;
notifier.isError;
notifier.hasData;
// If using cache `expiration`, you can also check if the data is fresh or stale:
notifier.isFresh;
notifier.isStale;

// Set the a new data value (Data) using the actual data type directly, replacing the previous value/result:
notifier.data = 'Hello Flutter!';
// Or, set the value to a new Result (in this case Data), replacing the previous value/result:
notifier.value = Data('Hello Flutter!');
// or, set the value using a Future: 
notifier.future = Future.value('Hello again Flutter!');
// await notifier.future; // Optionally, wait for the future to complete.
``` 
<br/>

### Fetching async data (e.g. from an API)

Often you'll want to do something a little more elaborate, like fetching data from an API. In this case, you can use
`FutureNotifier` (or ResultNotifier.future), which is a `ResultNotifier` that uses a "fetcher" function that returns a
Future.

```dart
final notifier = ResultNotifier<String>.future(
  (_) async {
    final response = await http.get(Uri.parse('https://www.boredapi.com/api/activity/'));
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['activity'] as String;
  },
  data: 'Test in production' // Optionally, set an initial value.
  expiration: const Duration(seconds: 42), // Optionally, set a cache expiration.
);

// Refresh the data (i.e. call the fetcher function to udpate the data of the notifier):
notifier.refresh();
``` 

Read more in the *Caching* section below. 

<br/>

## Observing (listening, watching...) changes

### ValueListenableBuilder-based observation

Since `ResultNotifier` implements `ValueListenable`, you can simply use `ValueListenableBuilder` to observe changes in
a Widget. However, this package also provides a method (`builder`) on 
[ResultBuilder](https://pub.dev/documentation/result_notifier/latest/result_notifier/ResultBuilder-class.html),
which makes this a bit more convenient.

```dart
notifier.builder((context, result, child) => switch (result) {
  Data(data: var d) => Text(d),
  Error(error: var e) => Text('Error: $e'),
  Loading() => const CircularProgressIndicator(),
}),
``` 
<br/>

### "Hooks-style" inline observation

If you're into the "hooks-style" of building widgets, you can use the `watch` (available via extension methods on 
`ResultNotifier`, `ValueNotifier`, `ChangeNotifier` etc.) method to observe changes on `Listenable`s.  While 
superficially similar to `flutter_hooks`, this implementation doesn't suffer from some of the complexities of that 
architectural style though, mainly because of a narrower scope and the fact that it relies on already existing 
`ResultNotifier` (or `Listenable`) instances.      

```dart
Watcher(builder: (context) {
  final result = notifier.watch(context);
  return Text(switch (result) {
    Data(data: var d) => d,
    Error(error: var e, data: var d) => 'Error - $d - $e',
    Loading(data: var d) => 'Loading - $d',
  });
});
```
<br/>

This type of observation is very lightweight, especially if using the stateless
**[Watcher](https://pub.dev/documentation/result_notifier/latest/result_notifier/Watcher-class.html)** or
**[WatcherWidget](https://pub.dev/documentation/result_notifier/latest/result_notifier/WatcherWidget-class.html)**
(there is also a stateful implementation). Observation is facilitated through the use of the 
**[WatcherRef](https://pub.dev/documentation/result_notifier/latest/result_notifier/WatcherRef-class.html)** interface,
which is implemented by the `BuildContext` 
(**[WatcherContext](https://pub.dev/documentation/result_notifier/latest/result_notifier/WatcherContext-class.html)**)
passed to the `builder` in `Watcher` and `build` method in `WatcherWidget` etc. Although the `watch` method is provided 
by `WatcherRef`, it's often more convenient to use the extension method on `ResultNotifier` (and `Listenable` etc.).

Although the use of `watch` is pretty straightforward, there are a few things to keep in mind: 

- The `watch` method can only be invoked within the `build` method of a `WatcherWidget`, or a Widget that mixes in 
  **[WatcherMixin](https://pub.dev/documentation/result_notifier/latest/result_notifier/WatcherMixin-mixin.html)** 
  or **[StatefulWatcherMixin](https://pub.dev/documentation/result_notifier/latest/result_notifier/StatefulWatcherMixin-mixin.html)**. 
- Disposal is handled automatically whenever you stop calling `watch` in the build method, or when the Widget is removed 
  from the tree (i.e. disposed).
- Conditional logic in the build method works with `watch`, just remember the point above - i.e. the Widget will not be 
  rebuilt for `Listenable`s that weren't watched in the last call to `build`.   

One *additional* benefit of this style of observation is that it makes it easier to watch for changes in multiple 
`Listenable`s or `ResultNotifier`s, without resorting to a lot of nested `ValueListenableBuilder`s or `ResultBuilder`s. 
For example:  

```dart
Watcher(builder: (context) {
  final result1 = notifier1.watch(context);
  final result2 = notifier2.watch(context);
  final combined = [result1, result2].combine((data) => '${data[0]} and ${data[1]}');
  return Text(switch (result) {
    (Data<String> d) => d.data,
    (Loading<String> l) => 'Loading - ${l.data}',
    (Error<String> e) => 'Error - ${e.data} - ${e.error}',
  });
});
``` 
<br/>

## Going deeper

### Caching

When using remote data, it's common to cache the data for some period of time and refresh it when it's stale. This
can be accomplished by setting the `cacheDuration` to an appropriate value. But remember that **caching is one of the
roots of all evil**, so don't enable it unless you're sure you really need it, and only when you're finished
implementing the core functionality of your app. 

```dart
final notifier = ResultNotifier<String>.future(
  (_) async { ... },
  data: 'Test in production' // Optionally, set an initial value.
  expiration: const Duration(seconds: 42), // Optionally, set a cache expiration.
);

// If using cache `expiration`, you can also check if the data is fresh or stale:
notifier.isFresh; // Returns true in this example
notifier.isStale; // Returns false in this example

// Refresh the data (i.e. call the fetcher function to udpate the data of the notifier):
notifier.refresh(); // In this example, the data will only be updated if refresh is called after 42 seconds has passed.
``` 

### Effects

You can also use effects (see `EffectNotifier`), to build more complex chains of notifiers:

```dart
final notifier = ResultNotifier<String>(data: 'Þetta er frábært!');
final effect = notifier.effect((_, input) => input.toUpperCase());
effect.onData(print);
notifier.data = 'Þetta er frábært!'; // Prints: "ÞETTA ER FRÁBÆRT!"
```
<br/>

See also the [effects](https://github.com/tolo/result_notifier/blob/main/example/lib/effects.dart) example for a more
complete demonstration of these concepts. 


### Inline effects
One advantage of using the hooks-style approach to observing changes is that you can easily do things like combining the 
results of multiple notifiers inline (without having to create a new notifier). This kind of effects is supported both 
through extension methods on `Iterable` as well on a set of `Record` definitions (see for instance
**[ResultTuple](https://pub.dev/documentation/result_notifier/latest/result_notifier/ResultTuple.html)**). 

```dart
Widget build(BuildContext context) {
  final activity = activityRepository.watch();
  final counter = experiencePoints.watch();

  /// Here we combine the data from the two notifiers, using the `combine` (or `combineData`) extension method defined
  /// in `ResultTuple` (there is also `ResultTriple` etc). 
  final resultFromRecord = (activity, counter).combine((a, b) => '$a - total experience points: $b');

  /// You can also use similar functionality exposed as extension methods on Iterable. 
  final resultFromList = [activity, counter].combine((data) => '${data[0]} - count: ${data[1]}');

  /// Or if you just want the data: 
  final resultData = (activity, counter).combineData((a, b) => '$a - count: $b');
}
``` 
<br/>

### ResultStore - a key-based store for notifiers  
To create an auto-disposable store of notifiers, each associated with a key - see [ResultStore](https://pub.dev/documentation/result_notifier/latest/result_notifier/ResultStore-class.html).
ResultStore can be useful to for instance support **pagination**, where each page is represented by a key and a unique 
notifier. 


### ResourceProvider- Providing notifiers to a subtree of widgets
A [ResourceProvider](https://pub.dev/documentation/result_notifier/latest/result_notifier/ResourceProvider-class.html)
can be used to handle the lifecycle (i.e. creation and disposal) of a notifier (or arbitrary resource), and provide it 
to a subtree of widgets. 


### Using regular `ValueNotifier`s / `ValueListenables`s
This package adds the extension method `toResultListenable` to `ValueListenable`, which transform it into a 
`ResultListenable` that can be used in for instance effects, such as `CombineLatestNotifier`.



## Examples

You can find a more complete example [here](https://pub.dev/packages/result_notifier/example), and additional examples
in the [examples directory](https://github.com/tolo/result_notifier/blob/main/example/lib) in the repository. 


### More examples

For an even more real-worldish example, check out [this fork](https://github.com/tolo/tmdb_movie_app) of Andrea
Bizzotto's TMDB Movie App, which uses Result Notifier instead of Riverpod. 


## When to use it - and when not to

Result Notifier is probably most suitable for cases when your state management needs are in the ballpark of "low to
moderate", or as we say in Sweden: [lagom](https://en.wikipedia.org/wiki/Lagom). If you need more advanced state
management, you might want to reach for something more elaborate. But then again, maybe not - as in most cases, this
very much depends on your general application architecture and modularization. And remember - excessive use of state
management may also be a sign of a flawed architecture or over-engineering.


## Things left to do...

The usual stuff, more tests and more docs 😅.
