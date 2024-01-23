# Result Notifier
**Pragmatic and magic-free state management for Flutter - simply [lagom](https://en.wikipedia.org/wiki/Lagom).** 

Result Notifier is a simple and modest package for state management, based on familiar and platform-native concepts, 
rather than introducing new abstractions and mental models. In fact, the package really is little more than a few 
additions to [ValueNotifier](https://api.flutter.dev/flutter/foundation/ValueNotifier-class.html) and 
[ChangeNotifier](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html). As the name of this package 
alludes to, one of the most important additions is the concept of a **Result** type, which can represent either some 
**Data**, an **Error** or a **Loading** state.

[![style: lint](https://img.shields.io/badge/style-lint-4BC0F5.svg)](https://pub.dev/packages/lint)

## Features

* Familiar and platform-native concepts, based on `ValueNotifier`, `ChangeNotifier`, `ValueListenableBuilder` etc.
* Built around a **[Result](https://pub.dev/documentation/result_notifier/latest/result_notifier/Result-class.html)** 
  type that represents some type of data. The result can be in one of three different states:  
    - **Data**: The result contains some concrete data.
    - **Error**: Represents an error, along with the previous data, if any.
    - **Loading**: Represents a loading/reloading state, along with the previous data, if any. 
* The core class [ResultNotifier](https://pub.dev/documentation/result_notifier/latest/result_notifier/ResultNotifier-class.html) - 
  a `ValueNotifier` that holds a `Result` value and provides methods for accessing and mutating the value. 
* Support for updating the data asynchronously (e.g. via an API call) using [FutureNotifier](https://pub.dev/documentation/result_notifier/latest/result_notifier/FutureNotifier-class.html).
* Support for cache expiration and refreshing of data when stale.
* An easy way to build the UI based on the current state of the result, using [ResultBuilder](https://pub.dev/documentation/result_notifier/latest/result_notifier/ResultBuilder-class.html).  
* An auto-disposable store of notifiers, each associated with a key (see [ResultStore](https://pub.dev/documentation/result_notifier/latest/result_notifier/ResultStore-class.html) 
  Makes it easy to support pagination or build a support a parameterised.
* A [ResultNotifierProvider](https://pub.dev/documentation/result_notifier/latest/result_notifier/ResultNotifierProvider-class.html) 
  that can be used to handle the lifecycle of a notifier (i.e. creation and disposal), and provide it to a subtree of 
  widgets. 
    - There is also [ResourceProvider](https://pub.dev/documentation/result_notifier/latest/result_notifier/ResourceProvider-class.html), 
      which can manage the lifecycle and access to arbitrary resources.  

## Getting Started

Simply [add the dependency](https://pub.dev/packages/result_notifier/install) and start writing some code:  

```dart
final notifier = ResultNotifier<String>.future(
  (_) async {
    final response = await http.get(Uri.parse('https://www.boredapi.com/api/activity/'));
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['activity'] as String;
  },
);
``` 

You can find a more complete example [here](https://pub.dev/packages/result_notifier/example), and additional examples 
in the [examples directory](https://github.com/tolo/result_notifier/blob/main/example/lib) in the repository.  

For an even more real-worldish example, check out [this fork](https://github.com/tolo/tmdb_movie_app) of Andrea 
Bizzotto's TMDB Movie App, which uses Result Notifier instead of Riverpod.

## Or... rolling your own 🤷‍️
Instead of adding a dependency this package, consider building it yourself. It's really not that hard, especially since 
you can use the source code of this package as a starting point, and just throw out the parts you don't need/like.

## When to use it - and when not to

Result Notifier is probably most suitable for cases when your state management needs are in the ballpark of "low to 
moderate", or as we say in Sweden: [lagom](https://en.wikipedia.org/wiki/Lagom). If you need more advanced state 
management, you might want to reach for something more elaborate. But then again, maybe not - as in most cases, this 
very much depends on your general application architecture and modularization. And remember - excessive use of state 
management may also be a sign of a flawed architecture or over-engineering.  

## Things left to do...

The usual stuff, more tests and more docs 😅.
