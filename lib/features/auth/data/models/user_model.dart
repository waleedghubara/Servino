import 'package:servino_client/core/api/end_point.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? image;
  final String? dob;
  final String? gender;
  final String? token;
  final String? role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.image,
    this.dob,
    this.gender,
    this.token,
    this.role,
  });

  String? get fullImage {
    if (image == null || image!.isEmpty) return null;
    if (image!.startsWith('http')) return image;
    return '${EndPoint.imageBaseUrl}$image';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.tryParse(json[ApiKey.id].toString()) ?? 0,
      name: json[ApiKey.name],
      email: json[ApiKey.email],
      phone: json[ApiKey.phone],
      image: json['image'] ?? json['imageUrl'] ?? json['provider_image'],
      dob: json['dob'],
      gender: json['gender'],
      token: json[ApiKey.token],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.id: id,
      ApiKey.name: name,
      ApiKey.email: email,
      ApiKey.phone: phone,
      'image': image,
      'dob': dob,
      'gender': gender,
      ApiKey.token: token,
      'role': role,
    };
  }
}
