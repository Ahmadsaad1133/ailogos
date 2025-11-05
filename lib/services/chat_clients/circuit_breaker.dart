import 'dart:async';

/// Minimal circuit breaker to prevent hammering a failing provider.
class CircuitBreaker {
  CircuitBreaker({
    this.failureThreshold = 3,
    this.openInterval = const Duration(seconds: 30),
  });

  final int failureThreshold;
  final Duration openInterval;

  int _failureCount = 0;
  DateTime? _openedAt;

  bool get isOpen {
    if (_openedAt == null) {
      return false;
    }
    final elapsed = DateTime.now().difference(_openedAt!);
    if (elapsed >= openInterval) {
      _openedAt = null;
      _failureCount = 0;
      return false;
    }
    return true;
  }

  void recordSuccess() {
    _failureCount = 0;
    _openedAt = null;
  }

  void recordFailure() {
    _failureCount += 1;
    if (_failureCount >= failureThreshold) {
      _openedAt = DateTime.now();
    }
  }

  Future<void> waitBeforeRetry(int attempt, {Duration baseDelay = const Duration(milliseconds: 500)}) async {
    final multiplier = 1 << attempt; // exponential backoff (2^attempt)
    final delay = Duration(milliseconds: baseDelay.inMilliseconds * multiplier);
    await Future<void>.delayed(delay);
  }
}