// Feature: The common outcome type (FR-028; data-model.md "Result<T, F>").
import 'package:flutter_test/flutter_test.dart';
import 'package:foundations/foundations.dart';

/// Matches every variant without a default branch, so adding a variant to
/// `Result` breaks compilation here.
String describe(Result<int, String> result) => switch (result) {
  Ok(:final value) => 'ok:$value',
  Err(:final failure) => 'err:$failure',
};

void main() {
  group('Given a successful result', () {
    const Result<int, String> result = Ok(42);

    test('When it is matched exhaustively, '
        'Then the Ok branch receives the value', () {
      // When
      final description = describe(result);

      // Then
      expect(description, 'ok:42');
    });
  });

  group('Given a failed result', () {
    const Result<int, String> result = Err('timeout');

    test('When it is matched exhaustively, '
        'Then the Err branch receives the failure', () {
      // When
      final description = describe(result);

      // Then
      expect(description, 'err:timeout');
    });
  });

  group('Given two results built separately with the same content', () {
    // ignore: prefer_const_constructors
    final ok = Ok<int, String>(42);
    // ignore: prefer_const_constructors
    final sameOk = Ok<int, String>(42);
    // ignore: prefer_const_constructors
    final err = Err<int, String>('timeout');
    // ignore: prefer_const_constructors
    final sameErr = Err<int, String>('timeout');

    test('When they are compared, '
        'Then they are equal when their contents are equal', () {
      // When
      final okEqual = ok == sameOk;
      final errEqual = err == sameErr;

      // Then
      expect(okEqual, isTrue);
      expect(ok.hashCode, sameOk.hashCode);
      expect(errEqual, isTrue);
      expect(err.hashCode, sameErr.hashCode);
    });
  });

  group('Given an Ok and an Err holding the same object', () {
    const Result<String, String> ok = Ok('x');
    const Result<String, String> err = Err('x');

    test('When they are compared, Then they are not equal', () {
      // When
      final equal = ok == err;

      // Then
      expect(equal, isFalse);
    });
  });
}
