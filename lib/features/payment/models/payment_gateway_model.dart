import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:servino_client/core/api/end_point.dart';

class PaymentGatewayModel {
  final int id;
  final String keyword;
  final String nameEn;
  final String nameAr;
  final String descEn;
  final String descAr;
  final String? transferNumber;
  final String? instructionsEn;
  final String? instructionsAr;
  final String imgUrl;
  final bool isManual;
  final String location;

  PaymentGatewayModel({
    required this.id,
    required this.keyword,
    required this.nameEn,
    required this.nameAr,
    required this.descEn,
    required this.descAr,
    this.transferNumber,
    this.instructionsEn,
    this.instructionsAr,
    required this.imgUrl,
    required this.isManual,
    required this.location,
  });

  factory PaymentGatewayModel.fromJson(Map<String, dynamic> json) {
    return PaymentGatewayModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      keyword: json['keyword'] ?? '',
      nameEn: json['name_en'] ?? '',
      nameAr: json['name_ar'] ?? '',
      descEn: json['description_en'] ?? '',
      descAr: json['description_ar'] ?? '',
      transferNumber: json['transfer_number'],
      instructionsEn: json['instructions_en'],
      instructionsAr: json['instructions_ar'],
      imgUrl: json['image_url'] ?? 'default.png',
      isManual: (json['is_manual'] == 1 || json['is_manual'] == true),
      location: json['location'] ?? 'global',
    );
  }

  String getName(BuildContext context) {
    return context.locale.languageCode == 'ar' ? nameAr : nameEn;
  }

  String getDescription(BuildContext context) {
    return context.locale.languageCode == 'ar' ? descAr : descEn;
  }

  String getInstructions(BuildContext context) {
    return (context.locale.languageCode == 'ar'
            ? instructionsAr
            : instructionsEn) ??
        '';
  }

  String getFullImageUrl() {
    return '${EndPoint.imageBaseUrl}$imgUrl';
  }

  Color getColor() {
    // Fallback colors based on keyword if needed for UI placeholders
    switch (keyword.toLowerCase()) {
      case 'vodafone':
        return Colors.red;
      case 'instapay':
        return Colors.purple;
      case 'binance':
        return Colors.orange;
      case 'visa':
        return Colors.blue;
      case 'google':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
