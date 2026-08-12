import 'package:flutter_test/flutter_test.dart';
import 'package:fisioterapia_pelvica/shared/utils/validators.dart';

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
    test('accepts the documented format', () {
      expect(isValidCrefito('123456-F3'), isTrue);
    });

    test('accepts lowercase and without a separator', () {
      expect(isValidCrefito('123456f3'), isTrue);
    });

    test('rejects a value without the category letter', () {
      expect(isValidCrefito('123456'), isFalse);
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
      expect(crefitoErrorText('123456-F3'), isNull);
    });

    test('returns an error for an invalid Crefito', () {
      expect(crefitoErrorText('abc'), isNotNull);
    });
  });
}
