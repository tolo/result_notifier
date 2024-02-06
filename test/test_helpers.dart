import 'package:result_notifier/result_notifier.dart';

class Fetcher {
  Fetcher({this.touch = false});
  final bool touch;

  bool didFetch = false;

  void onFetch<T>(ResultNotifier<T> notifier) {
    didFetch = true;
    if (touch) notifier.touch();
  }

  void error<T>(ResultNotifier<T> notifier) {
    didFetch = true;
    throw Exception('Error');
  }
}

class AsyncFetcher {
  AsyncFetcher({required this.id, int delayMs = 10}) : delay = Duration(milliseconds: delayMs);
  final String id;
  final Duration delay;
  int fetchCount = 0;
  bool get didFetch => fetchCount > 0;

  String fetchSync(ResultNotifier<String> notifier) {
    fetchCount++;
    return id;
  }

  Future<String> fetch(ResultNotifier<String> notifier) async {
    fetchCount++;
    await Future.delayed(const Duration(milliseconds: 10));
    if (notifier.isCancelled || !notifier.isActive) throw CancelledException();
    final result = await Future.delayed(delay, () => id);
    if (notifier.isCancelled || !notifier.isActive) throw CancelledException();
    return result;
  }

  Future<Result<String>> fetchResult(ResultNotifier<String> notifier) async {
    fetchCount++;
    await Future.delayed(const Duration(milliseconds: 10));
    if (notifier.isCancelled || !notifier.isActive) throw CancelledException();
    final result = await Future.delayed(delay, () => Data(id));
    if (notifier.isCancelled || !notifier.isActive) throw CancelledException();
    return result;
  }

  Future<Result<String>> error(ResultNotifier<String> notifier) async {
    fetchCount++;
    await Future.delayed(const Duration(milliseconds: 10));
    throw Exception('Error');
  }
}

class StreamableNotifier<T> extends ResultNotifier<T> with StreamableResultNotifierMixin<T> {
  StreamableNotifier({super.data});
}
