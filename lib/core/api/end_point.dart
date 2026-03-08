class EndPoint {
  static const String markRead = 'notifications/mark_read.php';
  static const String baseUrl =
      'https://walidghubara.online/backend-servino/api/';
  static const String imageBaseUrl =
      'https://walidghubara.online/backend-servino/';
  static const String register = 'client_auth/register.php';
  static const String login = 'client_auth/login.php';
  static const String googleLogin = 'client_auth/google_login.php';
  static const String verifyOtp = "client_auth/verify_otp.php";
  static const String resendOtp = "client_auth/resend_otp.php";
  static const String forgotPassword = "client_auth/forgot_password.php";
  static const String resetPassword = "client_auth/reset_password.php";

  static const String getUserProfile = 'client_auth/get_profile.php';
  static const String updateUserProfile = 'client_auth/update_profile.php';
  static const String getCategories = 'categories/read.php';
  static const String getBanners = 'banners/read.php';
  static const String getProviders = 'providers/read.php';
  static const String getProviderStatus = 'providers/read_status.php';
  static const String addReview = 'reviews/add.php';
  static const String getReviews = 'reviews/read.php';
  static const String toggleFavorite = 'favorites/toggle.php';
  static const String getFavorites = 'favorites/read.php';
  static const String incrementViews = 'providers/increment_views.php';
  static const String updateStatus = 'providers/update_status.php';
  static const String createBooking = 'bookings/create.php';
  static const String getUserBookings = 'bookings/read_by_user.php';
  static const String cancelBooking = 'bookings/cancel.php';
  static const String updateBookingStatus = 'bookings/update_status.php';
  static const String completeBooking = 'bookings/complete_booking.php';
  static const String rejectCompletion = 'bookings/reject_completion.php';

  // Notifications
  static const String getNotifications = 'notifications/read.php';
  static const String markNotificationRead = 'notifications/mark_read.php';
  static const String deleteNotification =
      'notifications/delete_notification.php';

  // Payment
  static const String getGateways = 'payment/get_gateways.php';
  static const String createTransaction = 'payment/create_transaction.php';
  static const String checkStatus = 'payment/check_status.php';

  static const String updateChatStatus = 'chat/update_status.php';
  static const String getUserChatStatus = 'chat/get_status.php';

  // Support
  static const String createTicket = 'support/create_ticket.php';
  static const String getTickets = 'support/get_tickets.php';
  static const String getMessages = 'support/get_messages.php';
  static const String sendSupportMessage = 'support/send_message.php';
  static const String setSupportTyping = 'support/set_typing.php';
  static const String uploadFile = 'upload/file.php';

  // Security
  static const String validateIntegrity = 'security/validate_integrity.php';
  static const String validatePayment = 'security/validate_payment.php';
  static const String securityLog = 'security/log.php';
}

class ApiKey {
  static String id = 'id';
  static String token = 'token';
  static String message = 'message';
  static String status = 'status';
  static String errormessage = 'ErrorMessage';
  static String name = 'name';
  static String storeName = 'storeName';
  static String tradeType = 'tradeType';
  static String city = 'city';
  static String address = 'address';
  static String email = 'email';
  static String password = 'password';
  static String confirmPassword = 'confirmPassword';
  static String phone = 'phone';
  static String profileImage = 'profileImage';
  static String imageDocument = 'imageDocument';
  static String verifyotpphone = 'verifyotpphone';
  static String verifyotpemail = 'otp_code';
  static String oldPassword = 'Old_password';
  static String newPassword = 'New_password';
  static String count = 'count';
  static String nameAddFayah = 'nameaddFayah';
  static String vehicle = 'vehicle';
  static String plate = 'plate';
}
