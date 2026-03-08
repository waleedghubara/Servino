import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:servino_client/core/services/data/models/category_model.dart';
import 'package:servino_client/core/services/data/models/review_model.dart';
import 'package:servino_client/core/services/data/models/service_provider_model.dart';
import 'package:servino_client/features/home/data/models/banner_model.dart';
import 'package:servino_client/features/home/data/repositories/home_repository.dart';

class HomeProvider extends ChangeNotifier {
  final HomeRepository homeRepository;

  HomeProvider({required this.homeRepository});

  List<CategoryModel> categories = [];
  List<BannerModel> banners = [];
  List<ServiceProviderModel> providers = [];
  List<ServiceProviderModel> favoriteProviders = [];
  bool isLoading = false;
  bool isLoadingBanners = false;
  bool isLoadingProviders = false;
  bool isLoadingFavorites = false;
  String? errorMessage;
  String? bannerErrorMessage;
  String? providerErrorMessage;
  String? favoriteErrorMessage;

  Future<void> getFavorites(String userId) async {
    isLoadingFavorites = true;
    favoriteErrorMessage = null;
    notifyListeners();

    final result = await homeRepository.getFavorites(userId);

    result.fold(
      (error) {
        isLoadingFavorites = false;
        favoriteErrorMessage = error;
        notifyListeners();
      },
      (data) {
        isLoadingFavorites = false;
        favoriteProviders = data;
        notifyListeners();
      },
    );
  }

  Future<void> getBanners() async {
    isLoadingBanners = true;
    bannerErrorMessage = null;
    notifyListeners();

    final result = await homeRepository.getBanners();

    result.fold(
      (error) {
        isLoadingBanners = false;
        bannerErrorMessage = error;
        notifyListeners();
      },
      (data) {
        isLoadingBanners = false;
        banners = data;
        notifyListeners();
      },
    );
  }

  Future<void> getCategories() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await homeRepository.getCategories();

    result.fold(
      (error) {
        isLoading = false;
        errorMessage = error;
        notifyListeners();
      },
      (data) {
        isLoading = false;
        categories = data;
        notifyListeners();
      },
    );
  }

  Future<Either<String, ServiceProviderModel>> getProviderById(
    String providerId, {
    String? userId,
  }) async {
    return await homeRepository.getProviderById(providerId, userId: userId);
  }

  Future<void> getProviders({
    String? categoryId,
    String? serviceId,
    String? userId,
  }) async {
    isLoadingProviders = true;
    providerErrorMessage = null;
    notifyListeners();

    final result = await homeRepository.getProviders(
      categoryId: categoryId,
      serviceId: serviceId,
      userId: userId,
    );

    result.fold(
      (error) {
        isLoadingProviders = false;
        providerErrorMessage = error;
        notifyListeners();
      },
      (data) {
        isLoadingProviders = false;
        providers = data;
        notifyListeners();
      },
    );
  }

  Future<void> updateProviderStatuses({
    String? categoryId,
    String? serviceId,
  }) async {
    final result = await homeRepository.getProviderStatus(
      categoryId: categoryId,
      serviceId: serviceId,
    );

    result.fold(
      (error) {
        // Ignore errors during polling
      },
      (data) {
        bool hasChanges = false;
        for (var status in data) {
          final id = status['id'];
          final isOnline = status['isOnline'] == true;
          final lastSeen = status['lastSeen'];

          final index = providers.indexWhere((p) => p.id == id.toString());
          if (index != -1) {
            final p = providers[index];
            if (p.isOnline != isOnline || p.lastSeen != lastSeen) {
              providers[index] = ServiceProviderModel(
                id: p.id,
                name: p.name,
                categoryId: p.categoryId,
                subCategory: p.subCategory,
                rating: p.rating,
                reviewCount: p.reviewCount,
                location: p.location,
                imageUrl: p.imageUrl,
                priceStart: p.priceStart,
                isAvailable: p.isAvailable,
                about: p.about,
                isVerified: p.isVerified,
                yearsOfExperience: p.yearsOfExperience,
                isOnline: isOnline, // Update
                isFavorited: p.isFavorited,
                lastSeen: lastSeen, // Update
                age: p.age,
                reviews: p.reviews,
              );
              hasChanges = true;
            }
          }
        }
        if (hasChanges) {
          notifyListeners();
        }
      },
    );
  }

  Future<bool> toggleFavorite({
    required String userId,
    required String providerId,
  }) async {
    final result = await homeRepository.toggleFavorite(
      userId: userId,
      providerId: providerId,
    );
    return result.fold((l) => false, (newStatus) {
      // 1. Update in main providers list
      final index = providers.indexWhere((p) => p.id == providerId);
      if (index != -1) {
        final p = providers[index];
        providers[index] = ServiceProviderModel(
          id: p.id,
          name: p.name,
          categoryId: p.categoryId,
          subCategory: p.subCategory,
          rating: p.rating,
          reviewCount: p.reviewCount,
          location: p.location,
          imageUrl: p.imageUrl,
          priceStart: p.priceStart,
          isAvailable: p.isAvailable,
          about: p.about,
          isVerified: p.isVerified,
          yearsOfExperience: p.yearsOfExperience,
          isOnline: p.isOnline,
          isFavorited: newStatus,
          lastSeen: p.lastSeen,
          age: p.age,
          reviews: p.reviews,
        );
      }

      // 2. Update in favoriteProviders list
      final favIndex = favoriteProviders.indexWhere((p) => p.id == providerId);
      if (newStatus) {
        // Status is now favorited
        if (favIndex == -1) {
          // Add if not already there
          if (index != -1) {
            favoriteProviders.add(providers[index]);
          } else {
            // Fetch favorites again if not in main list (edge case)
            getFavorites(userId);
          }
        }
      } else {
        // Status is now NOT favorited
        if (favIndex != -1) {
          favoriteProviders.removeAt(favIndex);
        }
      }

      notifyListeners();
      return true;
    });
  }

  Future<void> incrementViews({
    required String providerId,
    required String viewerId,
  }) async {
    await homeRepository.incrementViews(
      providerId: providerId,
      viewerId: viewerId,
    );
  }

  Future<bool> addReview({
    required String userId,
    required String providerId,
    required double rating,
    String? comment,
  }) async {
    final result = await homeRepository.addReview(
      userId: userId,
      providerId: providerId,
      rating: rating,
      comment: comment,
    );
    return result.isRight();
  }

  Future<Either<String, List<ReviewModel>>> getReviews(
    String providerId,
  ) async {
    return await homeRepository.getReviews(providerId);
  }
}
