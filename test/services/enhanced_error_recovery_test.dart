import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/services/error_recovery_service.dart';

void main() {
  group('Enhanced ErrorRecoveryService Tests', () {
    setUp(() {
      ErrorRecoveryService.clearAll();
    });

    group('Basic Recovery Operations', () {
      test('should execute successful operation without retry', () async {
        var callCount = 0;

        final result = await ErrorRecoveryService.executeWithRecovery<String>(
          'test_operation',
          () async {
            callCount++;
            return 'success';
          },
          OperationType.save,
        );

        expect(result.success, isTrue);
        expect(result.data, equals('success'));
        expect(callCount, equals(1));
        expect(
          ErrorRecoveryService.getAttemptCount('test_operation'),
          equals(0),
        );
      });

      test('should retry failed operation and eventually succeed', () async {
        var callCount = 0;

        final result = await ErrorRecoveryService.executeWithRecovery<String>(
          'retry_operation',
          () async {
            callCount++;
            if (callCount < 3) {
              throw Exception('temporary storage failure');
            }
            return 'success after retry';
          },
          OperationType.save,
          config: const RetryConfig(
            maxAttempts: 3,
            initialDelay: Duration(milliseconds: 10),
          ),
        );

        expect(result.success, isTrue);
        expect(result.data, equals('success after retry'));
        expect(callCount, equals(3));
      });

      test('should fail after max attempts and provide suggestions', () async {
        var callCount = 0;

        final result = await ErrorRecoveryService.executeWithRecovery<String>(
          'failing_operation',
          () async {
            callCount++;
            throw Exception('persistent failure');
          },
          OperationType.save,
          config: const RetryConfig(maxAttempts: 2),
        );

        expect(result.success, isFalse);
        expect(result.error, isNotNull);
        expect(result.suggestions, isNotEmpty);
        expect(callCount, equals(2));
      });

      test('should use fallback operation when main operation fails', () async {
        var mainCallCount = 0;
        var fallbackCallCount = 0;

        final result = await ErrorRecoveryService.executeWithRecovery<String>(
          'fallback_operation',
          () async {
            mainCallCount++;
            throw Exception('main operation failed');
          },
          OperationType.save,
          config: const RetryConfig(maxAttempts: 1),
          fallbackOperation: () async {
            fallbackCallCount++;
            return 'fallback success';
          },
        );

        expect(result.success, isTrue);
        expect(result.data, equals('fallback success'));
        expect(mainCallCount, equals(1));
        expect(fallbackCallCount, equals(1));
      });
    });

    group('Recovery Strategy Selection', () {
      test('should not retry validation errors', () async {
        var callCount = 0;

        final result = await ErrorRecoveryService.executeWithRecovery<String>(
          'validation_error',
          () async {
            callCount++;
            throw Exception('validation failed - invalid data');
          },
          OperationType.validation,
        );

        expect(result.success, isFalse);
        expect(result.nextStrategy, equals(RecoveryStrategy.userIntervention));
        expect(callCount, equals(1)); // No retry for validation errors
      });

      test('should not retry permission errors', () async {
        var callCount = 0;

        final result = await ErrorRecoveryService.executeWithRecovery<String>(
          'permission_error',
          () async {
            callCount++;
            throw Exception('permission denied');
          },
          OperationType.save,
        );

        expect(result.success, isFalse);
        expect(result.nextStrategy, equals(RecoveryStrategy.userIntervention));
        expect(callCount, equals(1)); // No retry for permission errors
      });

      test('should retry network errors with exponential backoff', () async {
        var callCount = 0;
        final startTime = DateTime.now();

        final result = await ErrorRecoveryService.executeWithRecovery<String>(
          'network_error',
          () async {
            callCount++;
            if (callCount < 3) {
              throw Exception('network connection failed');
            }
            return 'network recovered';
          },
          OperationType.download,
          config: const RetryConfig(
            maxAttempts: 3,
            initialDelay: Duration(milliseconds: 100),
          ),
        );

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        expect(result.success, isTrue);
        expect(callCount, equals(3));
        // Should have some delay due to exponential backoff
        expect(duration.inMilliseconds, greaterThan(200));
      });

      test('should retry storage errors with delay', () async {
        var callCount = 0;

        final result = await ErrorRecoveryService.executeWithRecovery<String>(
          'storage_error',
          () async {
            callCount++;
            if (callCount < 2) {
              throw Exception('database locked');
            }
            return 'storage recovered';
          },
          OperationType.save,
          config: const RetryConfig(
            maxAttempts: 2,
            initialDelay: Duration(milliseconds: 50),
          ),
        );

        expect(result.success, isTrue);
        expect(callCount, equals(2));
      });
    });

    group('Retry Configuration', () {
      test('should respect max attempts limit', () async {
        var callCount = 0;

        final result = await ErrorRecoveryService.executeWithRecovery<String>(
          'max_attempts_test',
          () async {
            callCount++;
            throw Exception('always fails');
          },
          OperationType.save,
          config: const RetryConfig(maxAttempts: 3),
        );

        expect(result.success, isFalse);
        expect(callCount, equals(3));
      });

      test('should apply exponential backoff correctly', () async {
        var callCount = 0;
        final delays = <Duration>[];
        DateTime? lastCallTime;

        await ErrorRecoveryService.executeWithRecovery<String>(
          'backoff_test',
          () async {
            final now = DateTime.now();
            if (lastCallTime != null) {
              delays.add(now.difference(lastCallTime!));
            }
            lastCallTime = now;

            callCount++;
            if (callCount < 3) {
              throw Exception('network connection timeout');
            }
            return 'success';
          },
          OperationType.load,
          config: const RetryConfig(
            maxAttempts: 3,
            initialDelay: Duration(milliseconds: 100),
            backoffMultiplier: 2.0,
          ),
        );

        expect(delays.length, equals(2));
        // Second delay should be longer than first due to exponential backoff
        expect(delays[1].inMilliseconds, greaterThan(delays[0].inMilliseconds));
      });

      test('should respect max delay limit', () async {
        var callCount = 0;
        final delays = <Duration>[];
        DateTime? lastCallTime;

        await ErrorRecoveryService.executeWithRecovery<String>(
          'max_delay_test',
          () async {
            final now = DateTime.now();
            if (lastCallTime != null) {
              delays.add(now.difference(lastCallTime!));
            }
            lastCallTime = now;

            callCount++;
            if (callCount < 4) {
              throw Exception('temporary failure');
            }
            return 'success';
          },
          OperationType.load,
          config: const RetryConfig(
            maxAttempts: 4,
            initialDelay: Duration(milliseconds: 100),
            maxDelay: Duration(milliseconds: 200),
            backoffMultiplier: 10.0, // Would exceed max delay without limit
          ),
        );

        expect(delays.length, equals(3));
        // All delays should be capped at max delay
        for (final delay in delays.skip(1)) {
          expect(
            delay.inMilliseconds,
            lessThanOrEqualTo(250),
          ); // Allow some tolerance
        }
      });
    });

    group('Operation Tracking', () {
      test('should track operation attempts', () async {
        expect(ErrorRecoveryService.getAttemptCount('tracked_op'), equals(0));
        expect(ErrorRecoveryService.isRetrying('tracked_op'), isFalse);

        var callCount = 0;
        await ErrorRecoveryService.executeWithRecovery<String>(
          'tracked_op',
          () async {
            callCount++;
            if (callCount < 2) {
              // Check tracking during retry
              expect(
                ErrorRecoveryService.getAttemptCount('tracked_op'),
                equals(callCount),
              );
              expect(ErrorRecoveryService.isRetrying('tracked_op'), isTrue);
              throw Exception('retry needed');
            }
            return 'success';
          },
          OperationType.save,
        );

        // After success, tracking should be cleared
        expect(ErrorRecoveryService.getAttemptCount('tracked_op'), equals(0));
        expect(ErrorRecoveryService.isRetrying('tracked_op'), isFalse);
      });

      test('should track time since last attempt', () async {
        var callCount = 0;

        await ErrorRecoveryService.executeWithRecovery<String>(
          'time_tracked_op',
          () async {
            callCount++;
            if (callCount == 1) {
              final timeSince = ErrorRecoveryService.getTimeSinceLastAttempt(
                'time_tracked_op',
              );
              expect(timeSince, isNotNull);
              expect(timeSince!.inMilliseconds, lessThan(100));
              throw Exception('retry needed');
            }
            return 'success';
          },
          OperationType.save,
          config: const RetryConfig(initialDelay: Duration(milliseconds: 50)),
        );

        // After completion, time tracking should be cleared
        expect(
          ErrorRecoveryService.getTimeSinceLastAttempt('time_tracked_op'),
          isNull,
        );
      });

      test('should allow manual operation reset', () async {
        var callCount = 0;

        // Start an operation that will fail
        final result = await ErrorRecoveryService.executeWithRecovery<String>(
          'reset_test_op',
          () async {
            callCount++;
            throw Exception('always fails');
          },
          OperationType.save,
          config: const RetryConfig(maxAttempts: 2),
        );

        expect(result.success, isFalse);
        expect(
          ErrorRecoveryService.getAttemptCount('reset_test_op'),
          equals(0),
        );

        // Reset and try again
        ErrorRecoveryService.resetOperation('reset_test_op');

        callCount = 0;
        final result2 = await ErrorRecoveryService.executeWithRecovery<String>(
          'reset_test_op',
          () async {
            callCount++;
            return 'success after reset';
          },
          OperationType.save,
        );

        expect(result2.success, isTrue);
        expect(callCount, equals(1));
      });
    });

    group('Simple Retry Utility', () {
      test('should retry simple operations', () async {
        var callCount = 0;

        final result = await ErrorRecoveryService.retry<String>(
          () async {
            callCount++;
            if (callCount < 3) {
              throw Exception('temporary failure');
            }
            return 'success';
          },
          maxAttempts: 3,
          delay: const Duration(milliseconds: 10),
        );

        expect(result, equals('success'));
        expect(callCount, equals(3));
      });

      test('should respect retry condition', () async {
        var callCount = 0;

        try {
          await ErrorRecoveryService.retry<String>(
            () async {
              callCount++;
              throw Exception('validation error');
            },
            maxAttempts: 3,
            retryIf: (error) => !error.toString().contains('validation'),
          );
          fail('Should have thrown exception');
        } catch (e) {
          expect(callCount, equals(1)); // Should not retry validation errors
          expect(e.toString(), contains('validation'));
        }
      });

      test('should fail after max attempts in simple retry', () async {
        var callCount = 0;

        try {
          await ErrorRecoveryService.retry<String>(() async {
            callCount++;
            throw Exception('persistent failure');
          }, maxAttempts: 2);
          fail('Should have thrown exception');
        } catch (e) {
          expect(callCount, equals(2));
          expect(e.toString(), contains('persistent failure'));
        }
      });
    });

    group('Error Message Generation', () {
      test(
        'should generate appropriate error messages for different error types',
        () async {
          final testCases = [
            ('network connection failed', 'network'),
            ('storage full', 'storage'),
            ('permission denied', 'permission'),
            ('validation failed', 'invalid'),
          ];

          for (final testCase in testCases) {
            final result =
                await ErrorRecoveryService.executeWithRecovery<String>(
                  'error_message_test_${testCase.$1}',
                  () async => throw Exception(testCase.$1),
                  OperationType.save,
                  config: const RetryConfig(maxAttempts: 1),
                );

            expect(result.success, isFalse);
            expect(result.error, isNotNull);
            expect(
              result.error!.toLowerCase(),
              contains(testCase.$2.toLowerCase()),
            );
          }
        },
      );

      test(
        'should provide contextual suggestions based on operation type',
        () async {
          final operationTypes = [
            OperationType.save,
            OperationType.load,
            OperationType.delete,
            OperationType.upload,
            OperationType.download,
            OperationType.validation,
          ];

          for (final opType in operationTypes) {
            final result =
                await ErrorRecoveryService.executeWithRecovery<String>(
                  'suggestion_test_$opType',
                  () async => throw Exception('generic error'),
                  opType,
                  config: const RetryConfig(maxAttempts: 1),
                );

            expect(result.success, isFalse);
            expect(result.suggestions, isNotEmpty);

            // Suggestions should be relevant to operation type
            final suggestionsText = result.suggestions.join(' ').toLowerCase();
            switch (opType) {
              case OperationType.save:
                expect(
                  suggestionsText,
                  anyOf(contains('save'), contains('storage')),
                );
                break;
              case OperationType.load:
                expect(
                  suggestionsText,
                  anyOf(contains('refresh'), contains('connection')),
                );
                break;
              case OperationType.delete:
                expect(
                  suggestionsText,
                  anyOf(contains('delete'), contains('exists')),
                );
                break;
              case OperationType.upload:
                expect(
                  suggestionsText,
                  anyOf(contains('upload'), contains('connection')),
                );
                break;
              case OperationType.download:
                expect(
                  suggestionsText,
                  anyOf(contains('download'), contains('connection')),
                );
                break;
              case OperationType.validation:
                expect(
                  suggestionsText,
                  anyOf(contains('validation'), contains('fix')),
                );
                break;
            }
          }
        },
      );
    });
  });
}
