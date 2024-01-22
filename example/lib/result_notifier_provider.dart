import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:result_notifier/result_notifier.dart';

/// Here we expand upon the main.dart (Bored API) example and move the global [ResultNotifier] to a separate Widget
/// (RepositoryProvider), that manages its lifecycle (creation and disposal). This is one way of providing a reference
/// to ResultNotifiers to child widgets and limit its scope and lifetime.

void main() => runApp(const ResultNotifierBuilderApp());

class ResultNotifierBuilderApp extends StatelessWidget {
  const ResultNotifierBuilderApp({super.key});

  @override Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'ResultNotifierBuilderApp',
      home: RepositoryProvider(),
    );
  }
}

/// Using [ResultNotifierProvider] to provide a simple way of providing a repository ([ResultNotifier]) to child widgets.
class RepositoryProvider extends ResultNotifierProvider<String> {
  const RepositoryProvider({super.key});

  @override
  ResultNotifier<String> createResource(BuildContext context) {
    /// Using ResultNotifier to create a simple repository for random activities, fetched from Bored API.
    return ResultNotifier<String>.future(
      (_) async {
        // ignore: avoid_print
        print('Fetching for random activity');
        await Future.delayed(const Duration(milliseconds: 500)); // Dramatic Pause
        final response = await http.get(Uri.parse('https://www.boredapi.com/api/activity/'));
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['activity'] as String;
      },
      // Setting refreshOnError to true makes sure that a call to refresh will fetch new data when the current result is
      // Error. An alternative is to use the flag "force: true" when calling refresh.
      refreshOnError: true,
    );
  }

  /// If we didn't need the ResultNotifier, we could instead have overridden `buildResult` (or used `resultBuilder`).
  /// Called whenever the Result changes.
  @override
  Widget buildResult(BuildContext context, ResultNotifier<String> resultNotifier, Result<String> result) {
    return ActivityPage(activityRepository: resultNotifier, activity: result);
  }

  /// We could also override the [build] method instead of [buildResult] (or using [resultBuilder]), if we wanted to
  /// customize the use of it in a child widget, i.e. instead of using the ValueListenableBuilder created by
  /// [ResultNotifierProvider],
  // @override
  // Widget build(BuildContext context, ResultNotifier<String> resource) {
  //   return ActivityPage(activityRepository: resource);
  // }
}

/// Displays a random activity
class ActivityPage extends StatelessWidget {
  const ActivityPage({required this.activityRepository, required this.activity, super.key});

  /// Note: instead of passing the [ResultNotifier] to the this widget, we could have used [ResultNotifierProvider.of]
  /// to get it. Example:
  ///
  /// ```
  /// ResultNotifierProvider.of<String>(context);
  /// ```
  final ResultNotifier<String> activityRepository;
  final Result<String> activity;

  @override Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Activity suggestion (${activity.lastUpdate})'),
        ),
        body: Center(
          child: activity.when(
            error: (e, st, data) => Text('Error: $e'),
            loading: (data) => const CircularProgressIndicator(),
            data: (data) => Text(data),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          // Note, whenever pressing this button, the widget will (normally) be rebuilt twice - once for the loading
          // state, and then again when the data is available. Also, if the ResultNotifier was setup to use (cache)
          // expiration, we would have to pass `force: true` to the `refresh` method to force a new fetch.
          onPressed: () => activityRepository.refresh(),
          icon: const Icon(Icons.refresh),
          label: const Text('New activity suggestion'),
        )
    );
  }
}
