class LocationUtils {
  static String formatLocation(String location) {
    if (location.isEmpty) return location;

    // Split by comma
    List<String> parts = location.split(',');

    // Trim whitespace from each part
    parts = parts.map((part) => part.trim()).toList();

    // Filter out empty parts
    parts = parts.where((part) => part.isNotEmpty).toList();

    if (parts.isEmpty) return location;

    // If we have 2 or more parts, take the last 2
    if (parts.length >= 2) {
      return '${parts[parts.length - 2]}, ${parts[parts.length - 1]}';
    }

    // If only 1 part, return it
    return parts.first;
  }
}
