import 'dart:async';

/// Interface that defines the contract for an asynchronous operation queue manager.
///
/// Implementations must ensure that enqueued operations
/// are executed sequentially, one at a time,
/// respecting the order they were added.
///
/// This is useful to avoid race conditions, ensuring that
/// dependent operations do not run concurrently.
///
/// Example usage:
/// ```dart
/// await queueManager.enqueue(() async {
///   // asynchronous code that must run in sequence
/// });
/// ```
abstract interface class IQueueManager {
  /// Enqueues an asynchronous operation that will be executed sequentially.
  ///
  /// The operation is a function that returns a [Future] of type [T].
  /// The queue guarantees that no other operation will start
  /// before the current one completes.
  ///
  /// Returns a [Future] that completes with the operation's result,
  /// or completes with an error if the operation throws an exception.
  Future<T> enqueue<T>(Future<T> Function() operation);
}

/// Singleton class that manages a queue of asynchronous operations,
/// ensuring that they execute sequentially in the order they were enqueued.
///
/// This prevents concurrency issues where multiple async operations might
/// otherwise run simultaneously and interfere with each other.
///
/// Usage:
/// ```dart
/// await QueueManager.instance.enqueue(() async {
///   // your async operation here
/// });
/// ```
final class QueueManager implements IQueueManager {
  // Private constructor for singleton pattern
  QueueManager._internal();

  // The single instance of QueueManager
  static final QueueManager _instance = QueueManager._internal();

  /// Gets the singleton instance of [QueueManager].
  static QueueManager get instance => _instance;

  // Internal list to hold queued async operations
  final List<Future<void> Function()> _operationQueue = [];

  // Flag to indicate if the queue is currently processing
  bool _isProcessing = false;

  /// Enqueues an asynchronous operation to be executed sequentially.
  ///
  /// The provided [operation] is a function returning a [Future] of type [T].
  /// This method ensures that the operation will only run after all previously
  /// enqueued operations have completed.
  ///
  /// Returns a [Future] that completes with the result of [operation].
  /// If [operation] throws an error, the returned future will complete with that error.
  @override
  Future<T> enqueue<T>(Future<T> Function() operation) {
    final completer = Completer<T>();

    // Wrap the operation so it can be managed internally
    _operationQueue.add(() async {
      try {
        final result = await operation();
        completer.complete(result);
      } catch (e, s) {
        completer.completeError(e, s);
      }
    });

    // Start processing the queue if not already running
    _processQueue();

    return completer.future;
  }

  // Internal method to process the queue sequentially
  void _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    while (_operationQueue.isNotEmpty) {
      final operation = _operationQueue.removeAt(0);
      try {
        await operation();
      } catch (_) {
        // Errors already handled in enqueue
      }
    }

    _isProcessing = false;
  }
}
