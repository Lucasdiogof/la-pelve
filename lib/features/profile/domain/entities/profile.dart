import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.name,
    required this.crefito,
    required this.phone,
    required this.email,
    this.photoPath,
  });

  final String id;
  final String name;
  final String crefito;
  final String phone;
  final String email;
  final String? photoPath;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    crefito: json['crefito'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    photoPath: json['photo_path'] as String?,
  );

  Profile copyWith({String? name, String? photoPath}) => Profile(
    id: id,
    name: name ?? this.name,
    crefito: crefito,
    phone: phone,
    email: email,
    photoPath: photoPath ?? this.photoPath,
  );

  @override
  List<Object?> get props => [id, name, crefito, phone, email, photoPath];
}
