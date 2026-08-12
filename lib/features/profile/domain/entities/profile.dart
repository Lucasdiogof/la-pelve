import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.nome,
    required this.crefito,
    required this.telefone,
    required this.email,
    this.fotoPath,
  });

  final String id;
  final String nome;
  final String crefito;
  final String telefone;
  final String email;
  final String? fotoPath;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    nome: json['nome'] as String? ?? '',
    crefito: json['crefito'] as String? ?? '',
    telefone: json['telefone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    fotoPath: json['foto_path'] as String?,
  );

  Profile copyWith({String? nome, String? fotoPath}) => Profile(
    id: id,
    nome: nome ?? this.nome,
    crefito: crefito,
    telefone: telefone,
    email: email,
    fotoPath: fotoPath ?? this.fotoPath,
  );

  @override
  List<Object?> get props => [id, nome, crefito, telefone, email, fotoPath];
}
