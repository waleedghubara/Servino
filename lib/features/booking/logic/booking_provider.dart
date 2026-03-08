import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/repositories/booking_repository.dart';

class BookingProvider extends ChangeNotifier {
  final BookingRepository repository;

  List<dynamic> _bookings = [];
  bool _isLoading = false;
  String? _error;

  BookingProvider({required this.repository});

  List<dynamic> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> createBooking({
    required String providerId,
    required String userId,
    required String date,
    required String time,
    required String type,
    double price = 0.0,
    String location = '',
    String notes = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await repository.createBooking(
      providerId: providerId,
      userId: userId,
      date: date,
      time: time,
      type: type,
      price: price,
      location: location,
      notes: notes,
    );

    bool success = false;
    result.fold(
      (l) {
        _error = l;
        _isLoading = false;
      },
      (r) {
        success = true;
        _isLoading = false;
        // Refresh list if desired, but we usually navigate
      },
    );

    notifyListeners();
    return success;
  }

  Future<void> fetchUserBookings(String userId) async {
    _isLoading = true;
    _error = null;
    // Don't notify here to avoid flickering if already on page
    // notifyListeners();

    final result = await repository.getUserBookings(userId);

    result.fold(
      (l) {
        _error = l;
        _isLoading = false;
      },
      (data) {
        _bookings = data;
        _isLoading = false;
      },
    );
    notifyListeners();
  }

  Future<void> silentlyRefreshBookings(String userId) async {
    final result = await repository.getUserBookings(userId);
    result.fold(
      (l) => null, // Ignore error on background refresh
      (data) {
        _bookings = data;
        notifyListeners();
      },
    );
  }

  Future<bool> cancelBooking(String bookingId, String userId) async {
    final result = await repository.cancelBooking(
      bookingId: bookingId,
      userId: userId,
    );

    return result.fold(
      (l) {
        _error = l;
        notifyListeners();
        return false;
      },
      (success) {
        if (success) {
          // Optimistically remove or update status
          final index = _bookings.indexWhere((b) => b['id'] == bookingId);
          if (index != -1) {
            _bookings[index]['status'] = 'Cancelled';
            notifyListeners();
          }
        }
        return success;
      },
    );
  }

  Future<bool> updateBookingStatus(
    String bookingId,
    String status, {
    String? userId,
  }) async {
    final result = await repository.updateBookingStatus(
      bookingId: bookingId,
      status: status,
      userId: userId,
    );

    return result.fold(
      (l) {
        _error = l;
        notifyListeners();
        return false;
      },
      (success) {
        debugPrint('Update status success: $success, status: $status');
        if (success) {
          // Update status in the list with a new list reference to ensure reactivity
          final newList = List<dynamic>.from(_bookings);
          final index = newList.indexWhere(
            (b) => b['id'].toString() == bookingId,
          );
          debugPrint(
            'Updating local booking at index: $index in new list reference',
          );
          if (index != -1) {
            newList[index] = Map<String, dynamic>.from(newList[index]);
            newList[index]['status'] = status;
            _bookings = newList;
            notifyListeners();
          }
        }
        return success;
      },
    );
  }

  Future<bool> completeBooking(String bookingId) async {
    final result = await repository.completeBooking(bookingId);
    return result.fold(
      (l) {
        _error = l;
        notifyListeners();
        return false;
      },
      (success) {
        if (success) {
          final newList = List<dynamic>.from(_bookings);
          final index = newList.indexWhere(
            (b) => b['id'].toString() == bookingId,
          );
          if (index != -1) {
            newList[index] = Map<String, dynamic>.from(newList[index]);
            newList[index]['status'] = 'Completed';
            _bookings = newList;
            notifyListeners();
          }
        }
        return success;
      },
    );
  }

  Future<bool> rejectCompletion(String bookingId) async {
    final result = await repository.rejectCompletion(bookingId);
    return result.fold(
      (l) {
        _error = l;
        notifyListeners();
        return false;
      },
      (success) {
        if (success) {
          final newList = List<dynamic>.from(_bookings);
          final index = newList.indexWhere(
            (b) => b['id'].toString() == bookingId,
          );
          if (index != -1) {
            newList[index] = Map<String, dynamic>.from(newList[index]);
            newList[index]['status'] = 'Arrived';
            _bookings = newList;
            notifyListeners();
          }
        }
        return success;
      },
    );
  }

  Future<bool> submitReview({
    required String providerId,
    required String userId,
    required double rating,
    String comment = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await repository.submitReview(
      providerId: providerId,
      userId: userId,
      rating: rating,
      comment: comment,
    );

    return result.fold(
      (l) {
        _error = l;
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (success) {
        _isLoading = false;
        notifyListeners();
        return success;
      },
    );
  }
}
