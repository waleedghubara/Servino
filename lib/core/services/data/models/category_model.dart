import 'package:servino_client/core/api/end_point.dart';

class CategoryModel {
  final int id;
  final String nameEn;
  final String nameAr;
  final String image;
  final List<CategoryService> services;

  const CategoryModel({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.image,
    required this.services,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      nameEn: json['name_en'],
      nameAr: json['name_ar'],
      image: json['image'] != null
          ? (json['image'].toString().startsWith('http')
                ? json['image']
                : '${EndPoint.imageBaseUrl}${json['image']}')
          : '',
      services: json['services'] != null
          ? (json['services'] as List)
                .map((e) => CategoryService.fromJson(e))
                .toList()
          : [],
    );
  }

  // Helper to get name based on locale
  String get name => nameEn;

  // Shim for legacy subCategories usage
  List<String> get subCategories => services.map((s) => s.nameEn).toList();

  // Temporary shim for other pages using dummy data
  static List<CategoryModel> categories = [
    CategoryModel(
      id: 1,
      nameEn: 'General',
      nameAr: 'عام',
      image: '',
      services: [],
    ),
  ];
}

class CategoryService {
  final int id;
  final String nameEn;
  final String nameAr;

  const CategoryService({
    required this.id,
    required this.nameEn,
    required this.nameAr,
  });

  factory CategoryService.fromJson(Map<String, dynamic> json) {
    return CategoryService(
      id: int.tryParse(json['id'].toString()) ?? 0,
      nameEn: json['name_en'],
      nameAr: json['name_ar'],
    );
  }

  // Temporary shim for other pages using dummy data
}
