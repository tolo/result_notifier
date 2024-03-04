import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:result_notifier/result_notifier.dart';

/// Here we expand upon the main.dart (Bored API) example and move the global [ResultNotifier] to a separate Widget
/// (RepositoryProvider), that manages its lifecycle (creation and disposal). This is one way of providing a reference
/// to ResultNotifiers to child widgets and limit its scope and lifetime.

void main() => runApp(const ResultNotifierBuilderApp());

ResultNotifier<String> createActivityRepository(BuildContext context) {
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
    // If cache expiration is needed, simply provide a Duration in the `expiration` parameter.:
    // expiration: const Duration(seconds: 30),
  );
}

class ResultNotifierBuilderApp extends StatelessWidget {
  const ResultNotifierBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResultNotifierBuilderApp',
      home: ResourceProvider(
        create: createActivityRepository,
        builder: (context, activityRepository) => ActivityPage(activityRepository: activityRepository),
      ),
    );
  }
}

/// Displays a random activity
class ActivityPage extends WatcherWidget {
  const ActivityPage({required this.activityRepository, super.key});

  /// Note: instead of passing the [ResultNotifier] to the this widget, we could have used [ResourceProvider.of] or
  /// [ResourceProviderContext.notifier] to get it. Example:
  ///
  /// ```
  /// context.notifier<String>();
  /// ```
  final ResultNotifier<String> activityRepository;

  @override
  Widget build(WatcherContext context) {
    final activity = activityRepository.watch(context);

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
      ),
    );
  }
}
