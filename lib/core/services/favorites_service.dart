import 'package:flutter/foundation.dart';

class FavoritesService {
  // Singleton instance
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  // Reactive list of favorite IDs
  final ValueNotifier<List<String>> _favoriteIds = ValueNotifier([]);

  ValueNotifier<List<String>> get favoriteIds => _favoriteIds;

  // Check if a provider is favorite
  bool isFavorite(String providerId) {
    return _favoriteIds.value.contains(providerId);
  }

  // Toggle favorite status
  void toggleFavorite(String providerId) {
    final currentFavorites = List<String>.from(_favoriteIds.value);
    if (currentFavorites.contains(providerId)) {
      currentFavorites.remove(providerId);
    } else {
      currentFavorites.add(providerId);
    }
    _favoriteIds.value = currentFavorites;
  }
}
