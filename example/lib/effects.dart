import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:result_notifier/result_notifier.dart';

/// Simple example demonstrating the use of [EffectNotifier]s, such as [CombineLatestNotifier] and
/// [AsyncEffectNotifier], to build more complex chains of processing.

void main() => runApp(const ChainsAndEffectsExampleApp());

class ChainsAndEffectsExampleApp extends StatelessWidget {
  const ChainsAndEffectsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'SimpleResultNotifierExampleApp',
      home: ActivityPage(),
    );
  }
}

/// Displays a random activity
class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<StatefulWidget> createState() => ActivityState();
}

class ActivityState extends State<ActivityPage> {
  final ResultNotifier<String> name1 = ResultNotifier(data: '');
  final ResultNotifier<String> name2 = ResultNotifier(data: '');

  late final ResultNotifier<String> result;

  String? currentName;

  @override
  void initState() {
    ResultNotifier<String> activity = name1.asyncEffect(_fetchActivityEffect);
    result = activity.combineLatest(name2, combineData: (sources) => '${sources[0]} with ${sources[1]}');
    super.initState();
  }

  Future<String> _fetchActivityEffect(ResultNotifier<String> notifier, String input) async {
    // ignore: avoid_print
    currentName = input;
    await Future.delayed(const Duration(milliseconds: 500)); // Dramatic Pause
    if (currentName != input) {
      print('Name changed - aborting activity fetch');
    }
    print('Fetching for random activity for "$input"');
    final response = await http.get(Uri.parse('https://www.boredapi.com/api/activity/'));
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return '$input wants to ${json['activity'] as String}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity suggestion'),
      ),
      body: Center(
        child: SizedBox(
          width: size.width > 500 ? 500 : size.width,
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(hintText: 'Name 1'),
                onChanged: (value) => name1.data = value,
              ),
              TextField(
                decoration: const InputDecoration(hintText: 'Name 2'),
                onChanged: (value) => name2.data = value,
              ),
              const SizedBox(height: 20),
              Text('Result: ', style: Theme.of(context).textTheme.headlineMedium),
              result.builder((context, result, child) => switch (result) {
                    Data(data: var d) => Text(d, style: Theme.of(context).textTheme.bodyLarge),
                    Error(error: var e) => Text('Error: $e'),
                    Loading() => const CircularProgressIndicator(),
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
