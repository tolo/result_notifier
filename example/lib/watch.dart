import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:result_notifier/result_notifier.dart';

/// Slightly altered version of the main.dart (Bored API) example that showcases the use of the `watch` method, as an
/// alternate pattern of observing changes in a [ResultNotifier].
///
/// This application combines the use of two ResultNotifiers, one that displays a random activity, using the Bored
/// API (https://www.boredapi.com/), and another that is used as a simple counter.

void main() => runApp(const WatcherResultNotifierExampleApp());

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

final experiencePoints = ResultNotifier(data: 0);

class WatcherResultNotifierExampleApp extends StatelessWidget {
  const WatcherResultNotifierExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WatcherResultNotifierExampleApp',

      /// Here we use ResourceProvider to provide a local ResultNotifier for the ActivityPage.
      home: ResourceProvider(
        create: (_) => ResultNotifier(data: true),
        builder: (context, iDidItEnabled) => ActivityPage(iDidItEnabled: iDidItEnabled),
      ),
    );
  }
}

/// Displays a random activity and a counter
class ActivityPage extends WatcherWidget {
  const ActivityPage({required this.iDidItEnabled, super.key});

  final ResultNotifier<bool> iDidItEnabled;

  @override
  Widget build(WatcherContext context) {
    final activity = activityRepository.watch(context);
    final counter = experiencePoints.watch(context);
    final iDidItButtonEnabled = iDidItEnabled.watch(context).data == true && !activity.isLoading;

    /// Here we combine the data from the two notifiers, using the `combine` (or `combineData`) extension method defined
    /// in `ResultTuple` (there is also `ResultTriple` etc).
    final result = (activity, counter).combine((a, b) => '$a - total experience points: $b');

    /// You can also use similar functionality exposed as extension methods on Iterable:
    // final result = [activity, counter].combine((data) => '${data[0]} - count: ${data[1]}');

    /// Or if you just want the data:
    // final resultData = (activity, counter).combineData((a, b) => '$a - count: $b');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity suggestion'),
      ),
      body: Center(
        child: Column(children: [
          SizedBox(height: 16),
          switch (result) {
            (Data d) => Text(d.data),
            (Error e) => Text('Error: ${e.error}'),
            (_) => const CircularProgressIndicator()
          },
          SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            FilledButton.icon(
              icon: const Icon(Icons.check_box),
              label: const Text('I did it!'),
              onPressed: iDidItButtonEnabled
                  ? () {
                      experiencePoints.data++;
                      iDidItEnabled.data = false;
                    }
                  : null,
            ),
            SizedBox(width: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('New activity suggestion'),
              onPressed: () {
                activityRepository.refresh();
                iDidItEnabled.data = true;
              },
            ),
          ]),
        ]),
      ),
    );
  }
}
