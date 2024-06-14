import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:result_notifier/result_notifier.dart';

/// Simple example demonstrating the use of a [ResultNotifier] and [ResultBuilder]. Displays a random activity, using
/// the Bored API (https://www.boredapi.com/).

void main() => runApp(const SimpleResultNotifierExampleApp());

/// Using ResultNotifier to create a simple repository for random activities, fetched from Bored API.
final activityRepository = ResultNotifier<String>.future(
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

class SimpleResultNotifierExampleApp extends StatelessWidget {
  const SimpleResultNotifierExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'SimpleResultNotifierExampleApp',
      home: ActivityPage(),
    );
  }
}

/// Displays a random activity
class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Activity suggestion'),
        ),
        body: Center(
          child: activityRepository.builder((context, result, child) => switch (result) {
                (Data d) => Text(d.data),
                (Error e) => Text('Error: ${e.error}'),
                (_) => const CircularProgressIndicator()
              }),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => activityRepository.refresh(), // Note: if the ResultNotifier was setup to use (cache)
          // expiration, we would have to pass `force: true` to the `refresh` method to force a new fetch.
          icon: const Icon(Icons.refresh),
          label: const Text('New activity suggestion'),
        ));
  }
}
