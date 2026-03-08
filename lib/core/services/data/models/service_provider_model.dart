import 'package:servino_client/core/services/data/models/review_model.dart';
import 'package:servino_client/core/api/end_point.dart';

class ServiceProviderModel {
  final String id;
  final String name;
  final String categoryId;
  final String subCategory; // Translation Key
  final double rating;
  final int reviewCount;
  final String location; // Translation Key
  final String imageUrl;
  final double priceStart;
  final String currency;
  final bool isAvailable; // Restored field
  final String about; // Translation Key
  final bool isVerified;
  final int yearsOfExperience;
  final bool isOnline;
  final bool isFavorited;
  final String? lastSeen;
  final int age;
  final List<ReviewModel> reviews;

  const ServiceProviderModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.subCategory,
    required this.rating,
    required this.reviewCount,
    required this.location,
    required this.imageUrl,
    required this.priceStart,
    this.currency = 'SAR',
    required this.isAvailable,
    required this.about,
    required this.isVerified,
    required this.yearsOfExperience,
    required this.isOnline,
    this.isFavorited = false,
    this.lastSeen,
    required this.age,
    this.reviews = const [],
  });

  factory ServiceProviderModel.fromJson(Map<String, dynamic> json) {
    return ServiceProviderModel(
      id: (json['provider_id'] ?? json['providerId'] ?? json['id']).toString(),
      name: json['name'] ?? json['provider_name'] ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      subCategory:
          json['service_name_ar'] ??
          json['service_name_en'] ??
          json['category_name_ar'] ??
          json['category_name_en'] ??
          json['category_name'] ??
          json['categoryName'] ??
          json['service_name'] ??
          '',
      rating:
          double.tryParse(
            (json['rating'] ?? json['provider_rating'] ?? '5.0').toString(),
          ) ??
          5.0,
      reviewCount:
          int.tryParse(
            (json['reviewCount'] ??
                    json['reviews_count'] ??
                    json['review_count'] ??
                    json['provider_review_count'] ??
                    '0')
                .toString(),
          ) ??
          0,
      location: json['location'] ?? '',
      imageUrl:
          (json['imageUrl'] ??
                  json['provider_image'] ??
                  json['image_url'] ??
                  '')
              .toString()
              .startsWith('http')
          ? (json['imageUrl'] ??
                json['provider_image'] ??
                json['image_url'] ??
                '')
          : '${EndPoint.imageBaseUrl}${json['imageUrl'] ?? json['provider_image'] ?? json['image_url'] ?? ''}',
      priceStart:
          double.tryParse(
            (json['priceStart'] ??
                    json['price_start'] ??
                    json['price'] ??
                    '0.0')
                .toString(),
          ) ??
          0.0,
      currency: json['currency'] ?? 'SAR',
      isAvailable:
          json['isAvailable'] == true ||
          json['isAvailable'] == 1 ||
          json['isAvailable'] == '1',
      about: json['about'] ?? '',
      isVerified:
          json['isVerified'] == true ||
          json['isVerified'] == 1 ||
          json['isVerified'] == '1',
      yearsOfExperience:
          int.tryParse(json['yearsOfExperience']?.toString() ?? '0') ?? 0,
      isOnline:
          json['isOnline'] == true ||
          json['isOnline'] == 1 ||
          json['isOnline'] == '1',
      isFavorited:
          json['isFavorited'] == true ||
          json['isFavorited'] == 1 ||
          json['isFavorited'] == '1',
      lastSeen: json['lastSeen'],
      age: int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      reviews: [],
    );
  }

  static List<ServiceProviderModel> getByCategoryId(String categoryId) {
    // Legacy support, returning empty or fetching from elsewhere
    return [];
  }
}
