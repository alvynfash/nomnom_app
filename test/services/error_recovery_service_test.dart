import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/services/error_recovery_service.dart';

void main() {
  group('ErrorRecoveryService', () {
    setUp(() {
      // Clear all operation tracking before each test
      ErrorRecoveryService.clearAll();
    });

    group('Basic Retry Logic', () {
      testWidgets('executes operation successfully on first attempt', (
        tester,
      ) async {
        int callCount = 0;

        final result = await ErrorRecoveryService.executeWithRecovery(
          'test-operation',
          () async {
            callCount++;
            return 'success';
          },
          OperationType.save,
        );

        expect(result.success, isTrue);
        expect(result.data, equals('success'));
        expect(callCount, equals(1));
      });

      testWidgets('retries operation on failure', (tester) async {
        int callCount = 0;

        final result = await ErrorRecoveryService.executeWithRecovery(
          'test-operation',
          () async {
            callCount++;
            if (callCount < 3) {
              throw Exception('Temporary error');
            }
            return 'success';
          },
          OperationType.save,
          config: RetryConfig.quick,
        );

        expect(result.success, isTrue);
        expect(result.data, equals('success'));
        expect(callCount, equals(3));
      });

      testWidgets('fails after max attempts', (tester) async {
        int callCount = 0;

        final result = await ErrorRecoveryService.executeWithRecovery(
          'test-operation',
          () async {
            callCount++;
            throw Exception('Persistent error');
          },
          OperationType.save,
          config: const RetryConfig(maxAttempts: 2),
        );

        expect(result.success, isFalse);
        expect(result.error, isNotNull);
        expect(callCount, equals(2));
      });
    });

    group('Fallback Operations', () {
      testWidgets('uses fallback operation when main operation fails', (
        tester,
      ) async {
        int mainCallCount = 0;
        int fallbackCallCount = 0;

        final result = await ErrorRecoveryService.executeWithRecovery(
          'test-operation',
          () async {
            mainCallCount++;
            throw Exception('Main operation failed');
          },
          OperationType.load,
          config: const RetryConfig(maxAttempts: 1),
          fallbackOperation: () async {
            fallbackCallCount++;
            return 'fallback-success';
          },
        );

        expect(result.success, isTrue);
        expect(result.data, equals('fallback-success'));
        expect(mainCallCount, equals(1));
        expect(fallbackCallCount, equals(1));
      });

      testWidgets('fails when both main and fallback operations fail', (
        tester,
      ) async {
        final result = await ErrorRecoveryService.executeWithRecovery(
          'test-operation',
          () async {
            throw Exception('Main operation failed');
          },
          OperationType.load,
          config: const RetryConfig(maxAttempts: 1),
          fallbackOperation: () async {
            throw Exception('Fallback operation failed');
          },
        );

        expect(result.success, isFalse);
        expect(result.error, isNotNull);
      });
    });

    group('Recovery Strategies', () {
      testWidgets('uses user intervention for validation errors', (
        tester,
      ) async {
        final result = await ErrorRecoveryService.executeWithRecovery(
          'test-operation',
          () async {
            throw Exception('Validation error: invalid input');
          },
          OperationType.validation,
          config: const RetryConfig(maxAttempts: 3),
        );

        expect(result.success, isFalse);
        expect(result.nextStrategy, equals(RecoveryStrategy.userIntervention));
      });

      testWidgets('retries network errors with exponential backoff', (
        tester,
      ) async {
        int callCount = 0;

        final result = await ErrorRecoveryService.executeWithRecovery(
          'test-operation',
          () async {
            callCount++;
            if (callCount < 2) {
              throw Exception('Network connection failed');
            }
            return 'success';
          },
          OperationType.download,
          config: RetryConfig.quick,
        );

        expect(result.success, isTrue);
        expect(callCount, equals(2));
      });

      testWidgets('does not retry permission errors', (tester) async {
        int callCount = 0;

        final result = await ErrorRecoveryService.executeWithRecovery(
          'test-operation',
          () async {
            callCount++;
            throw Exception('Permission denied');
          },
          OperationType.save,
          config: const RetryConfig(maxAttempts: 3),
        );

        expect(result.success, isFalse);
        expect(callCount, equals(1)); // Should not retry
        expect(result.nextStrategy, equals(RecoveryStrategy.userIntervention));
      });
    });

    group('Operation Tracking', () {
      testWidgets('tracks operation attempts', (tester) async {
        expect(ErrorRecoveryService.getAttemptCount('test-op'), equals(0));
        expect(ErrorRecoveryService.isRetrying('test-op'), isFalse);

        await ErrorRecoveryService.executeWithRecovery(
          'test-op',
          () async {
            throw Exception('Error');
          },
          OperationType.save,
          config: const RetryConfig(maxAttempts: 1),
        );

        expect(
          ErrorRecoveryService.getAttemptCount('test-op'),
          equals(0),
        ); // Reset after completion
        expect(ErrorRecoveryService.isRetrying('test-op'), isFalse);
      });

      testWidgets('resets operation tracking on success', (tester) async {
        await ErrorRecoveryService.executeWithRecovery(
          'test-op',
          () async => 'success',
          OperationType.save,
        );

        expect(ErrorRecoveryService.getAttemptCount('test-op'), equals(0));
        expect(ErrorRecoveryService.isRetrying('test-op'), isFalse);
      });

      testWidgets('can manually reset operation', (tester) async {
        // Start an operation that will fail
        try {
          await ErrorRecoveryService.executeWithRecovery(
            'test-op',
            () async {
              throw Exception('Error');
            },
            OperationType.save,
            config: const RetryConfig(maxAttempts: 1),
          );
        } catch (e) {
          // Expected to fail
        }

        ErrorRecoveryService.resetOperation('test-op');

        expect(ErrorRecoveryService.getAttemptCount('test-op'), equals(0));
        expect(ErrorRecoveryService.isRetrying('test-op'), isFalse);
      });
    });

    group('Simple Retry Function', () {
      testWidgets('retries operation with simple retry function', (
        tester,
      ) async {
        int callCount = 0;

        final result = await ErrorRecoveryService.retry(
          () async {
            callCount++;
            if (callCount < 3) {
              throw Exception('Temporary error');
            }
            return 'success';
          },
          maxAttempts: 3,
          delay: Duration.zero,
        );

        expect(result, equals('success'));
        expect(callCount, equals(3));
      });

      testWidgets('respects retryIf condition', (tester) async {
        int callCount = 0;

        expect(
          () async => await ErrorRecoveryService.retry(
            () async {
              callCount++;
              throw Exception('Network error');
            },
            maxAttempts: 3,
            delay: Duration.zero,
            retryIf: (error) => error.toString().contains('temporary'),
          ),
          throwsException,
        );
        expect(callCount, equals(1)); // Should not retry
      });

      testWidgets('retries based on retryIf condition', (tester) async {
        int callCount = 0;

        final result = await ErrorRecoveryService.retry(
          () async {
            callCount++;
            if (callCount < 3) {
              throw Exception('Temporary error');
            }
            return 'success';
          },
          maxAttempts: 3,
          delay: Duration.zero,
          retryIf: (error) => error.toString().contains('Temporary'),
        );

        expect(result, equals('success'));
        expect(callCount, equals(3));
      });
    });

    group('Error Message Generation', () {
      testWidgets('generates appropriate error messages', (tester) async {
        final result = await ErrorRecoveryService.executeWithRecovery(
          'test-operation',
          () async {
            throw Exception('Network connection failed');
          },
          OperationType.download,
          config: const RetryConfig(maxAttempts: 1),
        );

        expect(result.success, isFalse);
        expect(result.error, contains('Network connection error'));
        expect(result.suggestions, isNotEmpty);
        expect(result.suggestions, contains('Check your internet connection'));
      });

      testWidgets('provides operation-specific suggestions', (tester) async {
        final result = await ErrorRecoveryService.executeWithRecovery(
          'test-operation',
          () async {
            throw Exception('Unknown error');
          },
          OperationType.save,
          config: const RetryConfig(maxAttempts: 1),
        );

        expect(result.success, isFalse);
        expect(result.suggestions, contains('Try saving again'));
        expect(
          result.suggestions,
          contains('Check that all required fields are filled'),
        );
      });
    });

    group('Retry Configurations', () {
      testWidgets('uses quick retry configuration', (tester) async {
        int callCount = 0;
        final stopwatch = Stopwatch()..start();

        await ErrorRecoveryService.executeWithRecovery(
          'test-operation',
          () async {
            callCount++;
            if (callCount < 2) {
              throw Exception('Temporary error');
            }
            return 'success';
          },
          OperationType.save,
          config: RetryConfig.quick,
        );

        stopwatch.stop();

        expect(callCount, equals(2));
        // Quick config should have minimal delay
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      testWidgets('uses standard retry configuration', (tester) async {
        int callCount = 0;

        final result = await ErrorRecoveryService.executeWithRecovery(
          'test-operation',
          () async {
            callCount++;
            throw Exception('Persistent error');
          },
          OperationType.save,
          config: RetryConfig.standard,
        );

        expect(result.success, isFalse);
        expect(callCount, equals(3)); // Standard config has 3 max attempts
      });

      testWidgets('uses persistent retry configuration', (tester) async {
        int callCount = 0;

        final result = await ErrorRecoveryService.executeWithRecovery(
          'test-operation',
          () async {
            callCount++;
            throw Exception('Persistent error');
          },
          OperationType.save,
          config: RetryConfig.persistent,
        );

        expect(result.success, isFalse);
        expect(callCount, equals(5)); // Persistent config has 5 max attempts
      });
    });

    group('RecoveryResult', () {
      testWidgets('creates success result correctly', (tester) async {
        final result = RecoveryResult.success('test-data');

        expect(result.success, isTrue);
        expect(result.data, equals('test-data'));
        expect(result.error, isNull);
        expect(result.suggestions, isEmpty);
        expect(result.nextStrategy, isNull);
      });

      testWidgets('creates failure result correctly', (tester) async {
        final result = RecoveryResult.failure(
          'Test error',
          suggestions: ['Suggestion 1', 'Suggestion 2'],
          nextStrategy: RecoveryStrategy.retry,
        );

        expect(result.success, isFalse);
        expect(result.data, isNull);
        expect(result.error, equals('Test error'));
        expect(result.suggestions.length, equals(2));
        expect(result.nextStrategy, equals(RecoveryStrategy.retry));
      });
    });

    group('Edge Cases', () {
      testWidgets('handles null operation result', (tester) async {
        final result = await ErrorRecoveryService.executeWithRecovery<String?>(
          'test-operation',
          () async => null,
          OperationType.load,
        );

        expect(result.success, isTrue);
        expect(result.data, isNull);
      });

      testWidgets('handles operation that throws non-Exception', (
        tester,
      ) async {
        final result = await ErrorRecoveryService.executeWithRecovery(
          'test-operation',
          () async {
            throw 'String error';
          },
          OperationType.save,
          config: const RetryConfig(maxAttempts: 1),
        );

        expect(result.success, isFalse);
        expect(result.error, isNotNull);
      });

      testWidgets('clears all tracking data', (tester) async {
        // Start multiple operations
        try {
          await ErrorRecoveryService.executeWithRecovery(
            'op1',
            () async => throw Exception('Error'),
            OperationType.save,
            config: const RetryConfig(maxAttempts: 1),
          );
        } catch (e) {
          // Expected to fail
        }

        try {
          await ErrorRecoveryService.executeWithRecovery(
            'op2',
            () async => throw Exception('Error'),
            OperationType.load,
            config: const RetryConfig(maxAttempts: 1),
          );
        } catch (e) {
          // Expected to fail
        }

        ErrorRecoveryService.clearAll();

        expect(ErrorRecoveryService.getAttemptCount('op1'), equals(0));
        expect(ErrorRecoveryService.getAttemptCount('op2'), equals(0));
        expect(ErrorRecoveryService.isRetrying('op1'), isFalse);
        expect(ErrorRecoveryService.isRetrying('op2'), isFalse);
      });
    });
  });
}
