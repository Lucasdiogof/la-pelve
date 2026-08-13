import 'package:flutter_test/flutter_test.dart';
import 'package:fisioterapia_pelvica/features/profile/domain/entities/profile.dart';

void main() {
  group('Profile.fromJson', () {
    test('parses a fully populated map', () {
      final profile = Profile.fromJson(const {
        'id': 'u1',
        'name': 'Lucas',
        'crefito': '123456-F3',
        'phone': '11933334444',
        'email': 'lucas@example.com',
        'photo_path': 'avatars/u1.png',
      });

      expect(profile.id, 'u1');
      expect(profile.name, 'Lucas');
      expect(profile.crefito, '123456-F3');
      expect(profile.phone, '11933334444');
      expect(profile.email, 'lucas@example.com');
      expect(profile.photoPath, 'avatars/u1.png');
    });

    test('defaults missing string fields to empty and photoPath to null', () {
      final profile = Profile.fromJson(const {'id': 'u1'});

      expect(profile.name, '');
      expect(profile.crefito, '');
      expect(profile.phone, '');
      expect(profile.email, '');
      expect(profile.photoPath, isNull);
    });
  });

  group('Profile.copyWith', () {
    test('replaces name while keeping other fields', () {
      const profile = Profile(
        id: 'u1',
        name: 'Lucas',
        crefito: '123456-F3',
        phone: '11933334444',
        email: 'lucas@example.com',
      );

      final updated = profile.copyWith(name: 'Lucas Diogo');

      expect(updated.name, 'Lucas Diogo');
      expect(updated.id, profile.id);
      expect(updated.crefito, profile.crefito);
      expect(updated.phone, profile.phone);
      expect(updated.email, profile.email);
    });

    test('keeps photoPath when the argument is omitted', () {
      const profile = Profile(
        id: 'u1',
        name: 'Lucas',
        crefito: '123456-F3',
        phone: '11933334444',
        email: 'lucas@example.com',
        photoPath: 'avatars/u1.png',
      );

      final updated = profile.copyWith(name: 'Lucas Diogo');

      expect(updated.photoPath, 'avatars/u1.png');
    });
  });
}
