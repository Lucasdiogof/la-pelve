import 'package:flutter_test/flutter_test.dart';
import 'package:fisioterapia_pelvica/features/profile/domain/entities/profile.dart';

void main() {
  group('Profile.fromJson', () {
    test('parses a fully populated map', () {
      final profile = Profile.fromJson(const {
        'id': 'u1',
        'nome': 'Lucas',
        'crefito': '123456-F3',
        'telefone': '11933334444',
        'email': 'lucas@example.com',
        'foto_path': 'avatars/u1.png',
      });

      expect(profile.id, 'u1');
      expect(profile.nome, 'Lucas');
      expect(profile.crefito, '123456-F3');
      expect(profile.telefone, '11933334444');
      expect(profile.email, 'lucas@example.com');
      expect(profile.fotoPath, 'avatars/u1.png');
    });

    test('defaults missing string fields to empty and fotoPath to null', () {
      final profile = Profile.fromJson(const {'id': 'u1'});

      expect(profile.nome, '');
      expect(profile.crefito, '');
      expect(profile.telefone, '');
      expect(profile.email, '');
      expect(profile.fotoPath, isNull);
    });
  });

  group('Profile.copyWith', () {
    test('replaces nome while keeping other fields', () {
      const profile = Profile(
        id: 'u1',
        nome: 'Lucas',
        crefito: '123456-F3',
        telefone: '11933334444',
        email: 'lucas@example.com',
      );

      final updated = profile.copyWith(nome: 'Lucas Diogo');

      expect(updated.nome, 'Lucas Diogo');
      expect(updated.id, profile.id);
      expect(updated.crefito, profile.crefito);
      expect(updated.telefone, profile.telefone);
      expect(updated.email, profile.email);
    });

    test('keeps fotoPath when the argument is omitted', () {
      const profile = Profile(
        id: 'u1',
        nome: 'Lucas',
        crefito: '123456-F3',
        telefone: '11933334444',
        email: 'lucas@example.com',
        fotoPath: 'avatars/u1.png',
      );

      final updated = profile.copyWith(nome: 'Lucas Diogo');

      expect(updated.fotoPath, 'avatars/u1.png');
    });
  });
}
