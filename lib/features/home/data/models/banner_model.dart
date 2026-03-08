class BannerModel {
  final int id;
  final String image;
  final bool isActive;

  BannerModel({required this.id, required this.image, required this.isActive});

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      image: json['image'] ?? '',
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }
}
