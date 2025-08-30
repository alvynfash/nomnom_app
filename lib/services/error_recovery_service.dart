import 'dart:async';
import 'dart:developer' as developer;

/// Types of operations that can be retried
enum OperationType { save, load, delete, upload, download, validation }

/// Recovery strategy for different types of errors
enum RecoveryStrategy {
  retry,
  retryWithDelay,
  retryWithExponentialBackoff,
  fallback,
  userIntervention,
  abort,
}

/// Result of an error recovery attempt
class RecoveryResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final List<String> suggestions;
  final RecoveryStrategy? nextStrategy;

  RecoveryResult({
    required this.success,
    this.data,
    this.error,
    this.suggestions = const [],
    this.nextStrategy,
  });

  RecoveryResult.success(T this.data)
    : success = true,
      error = null,
      suggestions = const [],
      nextStrategy = null;

  RecoveryResult.failure(
    this.error, {
    List<String>? suggestions,
    this.nextStrategy,
  }) : success = false,
       data = null,
       suggestions = suggestions ?? [];
}

/// Configuration for retry operations
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final bool exponentialBackoff;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.exponentialBackoff = true,
  });

  static const RetryConfig quick = RetryConfig(
    maxAttempts: 2,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 5),
  );

  static const RetryConfig standard = RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 15),
  );

  static const RetryConfig persistent = RetryConfig(
    maxAttempts: 5,
    initialDelay: Duration(seconds: 2),
    maxDelay: Duration(seconds: 60),
  );
}

/// Service for handling error recovery and retry logic
class ErrorRecoveryService {
  static final Map<String, int> _operationAttempts = {};
  static final Map<String, DateTime> _lastAttemptTime = {};

  /// Execute an operation with automatic retry and recovery
  static Future<RecoveryResult<T>> executeWithRecovery<T>(
    String operationId,
    Future<T> Function() operation,
    OperationType operationType, {
    RetryConfig config = RetryConfig.standard,
    Future<T> Function()? fallbackOperation,
    bool enableLogging = true,
  }) async {
    final attempts = _operationAttempts[operationId] ?? 0;
    _operationAttempts[operationId] = attempts + 1;
    _lastAttemptTime[operationId] = DateTime.now();

    if (enableLogging) {
      developer.log(
        'Executing operation: $operationId (attempt ${attempts + 1}/${config.maxAttempts})',
        name: 'ErrorRecoveryService',
      );
    }

    try {
      final result = await operation();

      // Success - reset attempt counter
      _operationAttempts.remove(operationId);
      _lastAttemptTime.remove(operationId);

      if (enableLogging) {
        developer.log(
          'Operation succeeded: $operationId',
          name: 'ErrorRecoveryService',
        );
      }

      return RecoveryResult.success(result);
    } catch (error) {
      if (enableLogging) {
        developer.log(
          'Operation failed: $operationId - $error',
          name: 'ErrorRecoveryService',
          level: 900, // Warning level
        );
      }

      final currentAttempts = _operationAttempts[operationId] ?? 1;

      // Determine recovery strategy
      final strategy = _determineRecoveryStrategy(
        error,
        operationType,
        currentAttempts,
        config,
      );

      switch (strategy) {
        case RecoveryStrategy.retry:
        case RecoveryStrategy.retryWithDelay:
        case RecoveryStrategy.retryWithExponentialBackoff:
          if (currentAttempts < config.maxAttempts) {
            // Calculate delay
            Duration delay = Duration.zero;
            if (strategy == RecoveryStrategy.retryWithDelay ||
                strategy == RecoveryStrategy.retryWithExponentialBackoff) {
              delay = _calculateDelay(currentAttempts, config);
            }

            if (delay > Duration.zero) {
              if (enableLogging) {
                developer.log(
                  'Retrying operation $operationId after ${delay.inMilliseconds}ms',
                  name: 'ErrorRecoveryService',
                );
              }
              await Future.delayed(delay);
            }

            // Recursive retry
            return executeWithRecovery(
              operationId,
              operation,
              operationType,
              config: config,
              fallbackOperation: fallbackOperation,
              enableLogging: enableLogging,
            );
          } else {
            // Max attempts reached, try fallback
            if (fallbackOperation != null) {
              try {
                final fallbackResult = await fallbackOperation();
                _operationAttempts.remove(operationId);
                _lastAttemptTime.remove(operationId);

                if (enableLogging) {
                  developer.log(
                    'Fallback operation succeeded: $operationId',
                    name: 'ErrorRecoveryService',
                  );
                }

                return RecoveryResult.success(fallbackResult);
              } catch (fallbackError) {
                if (enableLogging) {
                  developer.log(
                    'Fallback operation failed: $operationId - $fallbackError',
                    name: 'ErrorRecoveryService',
                    level: 1000, // Error level
                  );
                }
              }
            }

            // All attempts failed
            _operationAttempts.remove(operationId);
            _lastAttemptTime.remove(operationId);

            return RecoveryResult.failure(
              _getErrorMessage(error),
              suggestions: _getRecoverySuggestions(error, operationType),
              nextStrategy: RecoveryStrategy.userIntervention,
            );
          }

        case RecoveryStrategy.fallback:
          if (fallbackOperation != null) {
            try {
              final fallbackResult = await fallbackOperation();
              _operationAttempts.remove(operationId);
              _lastAttemptTime.remove(operationId);
              return RecoveryResult.success(fallbackResult);
            } catch (fallbackError) {
              return RecoveryResult.failure(
                _getErrorMessage(fallbackError),
                suggestions: _getRecoverySuggestions(
                  fallbackError,
                  operationType,
                ),
                nextStrategy: RecoveryStrategy.userIntervention,
              );
            }
          }
          // Fall through to user intervention if no fallback
          continue userIntervention;

        userIntervention:
        case RecoveryStrategy.userIntervention:
          _operationAttempts.remove(operationId);
          _lastAttemptTime.remove(operationId);

          return RecoveryResult.failure(
            _getErrorMessage(error),
            suggestions: _getRecoverySuggestions(error, operationType),
            nextStrategy: RecoveryStrategy.userIntervention,
          );

        case RecoveryStrategy.abort:
          _operationAttempts.remove(operationId);
          _lastAttemptTime.remove(operationId);

          return RecoveryResult.failure(
            _getErrorMessage(error),
            suggestions: ['Operation aborted due to critical error'],
          );
      }
    }
  }

  /// Determine the best recovery strategy for an error
  static RecoveryStrategy _determineRecoveryStrategy(
    dynamic error,
    OperationType operationType,
    int currentAttempts,
    RetryConfig config,
  ) {
    final errorString = error.toString().toLowerCase();

    // Critical errors that should not be retried
    if (errorString.contains('permission denied') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      return RecoveryStrategy.userIntervention;
    }

    // Validation errors should not be retried
    if (errorString.contains('validation') ||
        errorString.contains('invalid') ||
        errorString.contains('format')) {
      return RecoveryStrategy.userIntervention;
    }

    // Network errors - retry with exponential backoff
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('unreachable')) {
      return currentAttempts < config.maxAttempts
          ? RecoveryStrategy.retryWithExponentialBackoff
          : RecoveryStrategy.userIntervention;
    }

    // Storage errors - retry with delay
    if (errorString.contains('storage') ||
        errorString.contains('database') ||
        errorString.contains('file') ||
        errorString.contains('disk')) {
      return currentAttempts < config.maxAttempts
          ? RecoveryStrategy.retryWithDelay
          : RecoveryStrategy.fallback;
    }

    // Temporary errors - simple retry
    if (errorString.contains('busy') ||
        errorString.contains('locked') ||
        errorString.contains('temporary')) {
      return currentAttempts < config.maxAttempts
          ? RecoveryStrategy.retry
          : RecoveryStrategy.retryWithDelay;
    }

    // Default strategy based on operation type
    switch (operationType) {
      case OperationType.save:
      case OperationType.upload:
        return currentAttempts < config.maxAttempts
            ? RecoveryStrategy.retryWithDelay
            : RecoveryStrategy.fallback;

      case OperationType.load:
      case OperationType.download:
        return currentAttempts < config.maxAttempts
            ? RecoveryStrategy.retryWithExponentialBackoff
            : RecoveryStrategy.fallback;

      case OperationType.delete:
        return currentAttempts < config.maxAttempts
            ? RecoveryStrategy.retry
            : RecoveryStrategy.userIntervention;

      case OperationType.validation:
        return RecoveryStrategy.userIntervention;
    }
  }

  /// Calculate delay for retry attempts
  static Duration _calculateDelay(int attemptNumber, RetryConfig config) {
    if (!config.exponentialBackoff) {
      return config.initialDelay;
    }

    final delayMs =
        config.initialDelay.inMilliseconds *
        (config.backoffMultiplier * (attemptNumber - 1));

    final delay = Duration(milliseconds: delayMs.round());

    return delay > config.maxDelay ? config.maxDelay : delay;
  }

  /// Get user-friendly error message
  static String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network connection error. Please check your internet connection.';
    } else if (errorString.contains('timeout')) {
      return 'Operation timed out. Please try again.';
    } else if (errorString.contains('storage') ||
        errorString.contains('database')) {
      return 'Storage error. Please check available space and try again.';
    } else if (errorString.contains('permission')) {
      return 'Permission denied. Please check app permissions.';
    } else if (errorString.contains('validation') ||
        errorString.contains('invalid')) {
      return 'Invalid data. Please check your input and try again.';
    } else if (errorString.contains('not found')) {
      return 'Requested item not found.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Get recovery suggestions for different error types
  static List<String> _getRecoverySuggestions(
    dynamic error,
    OperationType operationType,
  ) {
    final suggestions = <String>[];
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      suggestions.addAll([
        'Check your internet connection',
        'Try switching to a different network',
        'Wait a moment and try again',
      ]);
    } else if (errorString.contains('storage') ||
        errorString.contains('database')) {
      suggestions.addAll([
        'Check available storage space',
        'Close other apps to free up memory',
        'Restart the app if the problem persists',
      ]);
    } else if (errorString.contains('permission')) {
      suggestions.addAll([
        'Check app permissions in device settings',
        'Grant necessary permissions and try again',
      ]);
    } else if (errorString.contains('validation') ||
        errorString.contains('invalid')) {
      suggestions.addAll([
        'Check the highlighted fields for errors',
        'Ensure all required information is provided',
        'Verify that the data format is correct',
      ]);
    } else {
      // Generic suggestions based on operation type
      switch (operationType) {
        case OperationType.save:
          suggestions.addAll([
            'Try saving again',
            'Check that all required fields are filled',
            'Ensure you have sufficient storage space',
          ]);
          break;
        case OperationType.load:
          suggestions.addAll([
            'Try refreshing the data',
            'Check your internet connection',
            'Restart the app if the problem persists',
          ]);
          break;
        case OperationType.delete:
          suggestions.addAll([
            'Try the delete operation again',
            'Ensure the item still exists',
            'Check if the item is being used elsewhere',
          ]);
          break;
        case OperationType.upload:
          suggestions.addAll([
            'Check your internet connection',
            'Ensure the file is not too large',
            'Try uploading again',
          ]);
          break;
        case OperationType.download:
          suggestions.addAll([
            'Check your internet connection',
            'Ensure you have sufficient storage space',
            'Try downloading again',
          ]);
          break;
        case OperationType.validation:
          suggestions.addAll([
            'Fix the validation errors',
            'Check the highlighted fields',
            'Ensure all required information is provided',
          ]);
          break;
      }
    }

    return suggestions;
  }

  /// Reset attempt counters for an operation
  static void resetOperation(String operationId) {
    _operationAttempts.remove(operationId);
    _lastAttemptTime.remove(operationId);
  }

  /// Get current attempt count for an operation
  static int getAttemptCount(String operationId) {
    return _operationAttempts[operationId] ?? 0;
  }

  /// Check if an operation is currently being retried
  static bool isRetrying(String operationId) {
    return _operationAttempts.containsKey(operationId);
  }

  /// Get time since last attempt for an operation
  static Duration? getTimeSinceLastAttempt(String operationId) {
    final lastAttempt = _lastAttemptTime[operationId];
    return lastAttempt != null ? DateTime.now().difference(lastAttempt) : null;
  }

  /// Clear all operation tracking data
  static void clearAll() {
    _operationAttempts.clear();
    _lastAttemptTime.clear();
  }

  /// Execute a simple retry operation
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 1),
    bool Function(dynamic error)? retryIf,
  }) async {
    int attempts = 0;

    while (attempts < maxAttempts) {
      attempts++;

      try {
        return await operation();
      } catch (error) {
        if (attempts >= maxAttempts || (retryIf != null && !retryIf(error))) {
          rethrow;
        }

        if (attempts < maxAttempts && delay > Duration.zero) {
          await Future.delayed(delay);
        }
      }
    }

    throw StateError('Retry loop completed without success or failure');
  }
}
