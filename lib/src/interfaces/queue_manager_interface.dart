// coverage:ignore-file

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
