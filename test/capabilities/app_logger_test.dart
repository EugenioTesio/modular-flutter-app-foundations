// Feature: Leveled logging shortcuts (FR-041; data-model.md LogLevel,
// Log entry.level, Log entry.message, Log entry.context).
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';

import '../support/fakes.dart';

void main() {
  group('Given a logger that records its entries', () {
    late RecordingAppLogger logger;

    setUp(() {
      logger = RecordingAppLogger();
    });

    test('When debug and info are called, '
        'Then log receives the matching level, message, and context', () {
      // When
      logger
        ..debug('loading', context: {'screen': 'home'})
        ..info('loaded', context: {'count': 3});

      // Then
      expect(logger.entries, [
        const LogEntry(LogLevel.debug, 'loading', context: {'screen': 'home'}),
        const LogEntry(LogLevel.info, 'loaded', context: {'count': 3}),
      ]);
    });

    test('When warning and error are called with an error and stack trace, '
        'Then log receives them unchanged with the matching level', () {
      // Given
      final failure = StateError('broken');
      final stackTrace = StackTrace.current;

      // When
      logger
        ..warning(
          'retrying',
          error: failure,
          stackTrace: stackTrace,
          context: {'attempt': 2},
        )
        ..error('gave up', error: failure, stackTrace: stackTrace);

      // Then
      expect(logger.entries, [
        LogEntry(
          LogLevel.warning,
          'retrying',
          error: failure,
          stackTrace: stackTrace,
          context: const {'attempt': 2},
        ),
        LogEntry(
          LogLevel.error,
          'gave up',
          error: failure,
          stackTrace: stackTrace,
        ),
      ]);
    });
  });

  group('Given the log levels', () {
    test('When they are listed, '
        'Then they are ordered from lowest to highest', () {
      // When
      final levels = LogLevel.values;

      // Then
      expect(levels, [
        LogLevel.debug,
        LogLevel.info,
        LogLevel.warning,
        LogLevel.error,
      ]);
    });
  });
}
