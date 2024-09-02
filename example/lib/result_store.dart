import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:result_notifier/result_notifier.dart';

/// Like main.dart, this example uses the Bored API to fetch random activities, but of three different types. To
/// facilitate caching and maintaining separate results for the different types, a [ResultStore] is used. This class
/// manages the lifecycle of a variable number of [ResultNotifier]s, each associated with a specific key (activity type
/// in this case).

void main() => runApp(const ResultStoreApp());

class ResultStoreApp extends StatelessWidget {
  const ResultStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'ResultStoreApp',
      home: RepositoryProvider(),
    );
  }
}

/// Using [ResourceProvider] to provide a simple way of providing a [ResultStore] to child widgets.
class RepositoryProvider extends ResourceProvider<ResultStore<String, String>> {
  const RepositoryProvider({super.key}) : super.custom();

  @override
  ResultStore<String, String> createResource(BuildContext context) {
    /// Using ResultStore to create a simple repository that fetches and caches random activities for different types.
    return ResultStore(
      create: (String type, store) => ResultNotifier<String>.future((_) async {
        /// Fetch activities for a specific type from Bored API.
        // ignore: avoid_print
        print('Fetching for type $type');
        await Future.delayed(
            const Duration(milliseconds: 1500)); // Dramatic Pause
        final response = await http
            .get(Uri.parse('https://www.boredapi.com/api/activity?type=$type'));
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['activity'] as String;
      }, onReset: (_) {
        // ignore: avoid_print
        print('Notifier for $type was reset');
      }),
    );
  }

  @override
  Widget build(BuildContext context, ResultStore<String, String> resource) {
    /// We use a simple [ListenableBuilder] here, to rebuild the ActivityPage whenever the [ResultStore] changes.
    return ListenableBuilder(
      listenable: resource,
      builder: (context, _) => ActivityPage(activityRepository: resource),
    );
  }
}

/// Displays a random activity
class ActivityPage extends StatelessWidget {
  const ActivityPage({required this.activityRepository, super.key});

  /// Note: instead of passing the [ResultStore] to the this widget, we could have used [ResourceProvider.of]
  /// to get it. Example:
  ///
  /// ```
  /// ResourceProvider.of<ResultStore<String, String>>(context);
  /// ```
  final ResultStore<String, String> activityRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activity suggestion (${activityRepository.lastUpdate})'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ActivityTypeWidget(
              title: 'Recreational activity',
              activity: activityRepository.value('recreational'),
              refresh: () =>
                  activityRepository.refresh('recreational', force: true),
              cancel: () => activityRepository.cancel('recreational'),
            ),
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 64),
                child: Divider()),
            ActivityTypeWidget(
              title: 'Relaxing activity',
              activity: activityRepository.value('relaxation'),
              refresh: () =>
                  activityRepository.refresh('relaxation', force: true),
              cancel: () => activityRepository.cancel('relaxation'),
            ),
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 64),
                child: Divider()),
            ActivityTypeWidget(
              title: 'Social activity',
              activity: activityRepository.value('social'),
              refresh: () => activityRepository.refresh('social', force: true),
              cancel: () => activityRepository.cancel('social'),
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityTypeWidget extends StatelessWidget {
  const ActivityTypeWidget({
    required this.title,
    required this.activity,
    required this.refresh,
    required this.cancel,
    super.key,
  });

  final String title;
  final Result<String> activity;
  final VoidCallback refresh;
  final VoidCallback cancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        switch (activity) {
          (Data d) => Text(d.data),
          // Here, we first check if the error was due to cancellation before showing how to present the error. Another
          // way to check if the error was due to cancellation is see if the error is of type CancelledException.
          (Error e) => activity.isCancelled
              ? Text('${e.data} (cancelled)')
              : Text('Error: ${e.error}, last data: ${e.data}'),
          // In this example, we take the opportunity to show the existing data along with the
          // CircularProgressIndicator when loading
          (Loading l) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (l.data != null) Text(l.data),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator()),
                ),
              ],
            )
        },
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('New suggestion'),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: activity.isLoading ? cancel : null,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }
}
