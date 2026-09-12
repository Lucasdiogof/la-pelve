import 'package:flutter_test/flutter_test.dart';
import 'package:la_pelve/shared/utils/validators.dart';

void main() {
  group('isValidEmail', () {
    test('accepts a well-formed email', () {
      expect(isValidEmail('lucas@example.com'), isTrue);
    });

    test('rejects an empty string', () {
      expect(isValidEmail(''), isFalse);
    });

    test('rejects a string without @', () {
      expect(isValidEmail('lucasexample.com'), isFalse);
    });

    test('rejects a string without a domain', () {
      expect(isValidEmail('lucas@'), isFalse);
    });
  });

  group('isValidPassword', () {
    test('accepts a password at the minimum length', () {
      expect(isValidPassword('a' * kMinPasswordLength), isTrue);
    });

    test('rejects a password below the minimum length', () {
      expect(isValidPassword('a' * (kMinPasswordLength - 1)), isFalse);
    });
  });

  group('ageErrorText', () {
    test('returns null for an empty value', () {
      expect(ageErrorText(''), isNull);
    });

    test('returns null for a valid age', () {
      expect(ageErrorText('30'), isNull);
    });

    test('returns an error for a non-numeric value', () {
      expect(ageErrorText('abc'), isNotNull);
    });

    test('returns an error below the minimum age', () {
      expect(ageErrorText('0'), isNotNull);
    });

    test('returns an error above the maximum age', () {
      expect(ageErrorText('121'), isNotNull);
    });

    test('accepts the boundary ages', () {
      expect(ageErrorText(kMinAge.toString()), isNull);
      expect(ageErrorText(kMaxAge.toString()), isNull);
    });
  });

  group('isValidPhone', () {
    test('accepts a 10-digit landline', () {
      expect(isValidPhone('1133334444'), isTrue);
    });

    test('accepts an 11-digit mobile', () {
      expect(isValidPhone('11933334444'), isTrue);
    });

    test('accepts formatted input with punctuation', () {
      expect(isValidPhone('(11) 93333-4444'), isTrue);
    });

    test('rejects a number with too few digits', () {
      expect(isValidPhone('123456789'), isFalse);
    });

    test('rejects a number with too many digits', () {
      expect(isValidPhone('123456789012'), isFalse);
    });
  });

  group('phoneErrorText', () {
    test('returns null for an empty value', () {
      expect(phoneErrorText(''), isNull);
    });

    test('returns null for a valid phone', () {
      expect(phoneErrorText('11933334444'), isNull);
    });

    test('returns an error for an incomplete phone', () {
      expect(phoneErrorText('1193333'), isNotNull);
    });
  });

  group('isValidCrefito', () {
    test('accepts a plain number within range', () {
      expect(isValidCrefito('123456'), isTrue);
    });

    test('accepts formatted input by counting digits only', () {
      expect(isValidCrefito('11/338376-F'), isTrue);
    });

    test('accepts the shortest allowed length', () {
      expect(isValidCrefito('1234'), isTrue);
    });

    test('accepts the longest allowed length', () {
      expect(isValidCrefito('1234567890'), isTrue);
    });

    test('rejects a value shorter than the minimum', () {
      expect(isValidCrefito('123'), isFalse);
    });

    test('rejects a value longer than the maximum', () {
      expect(isValidCrefito('12345678901'), isFalse);
    });

    test('rejects an empty value', () {
      expect(isValidCrefito(''), isFalse);
    });
  });

  group('crefitoErrorText', () {
    test('returns null for an empty value', () {
      expect(crefitoErrorText(''), isNull);
    });

    test('returns null for a valid Crefito', () {
      expect(crefitoErrorText('123456'), isNull);
    });

    test('returns an error for an invalid Crefito', () {
      expect(crefitoErrorText('12'), isNotNull);
    });
  });
}
