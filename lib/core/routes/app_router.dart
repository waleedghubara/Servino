import 'package:flutter/material.dart';
import '../../features/services/provider_details_page.dart';
import '../../features/payment/pages/payment_required_page.dart';
import '../../features/payment/pages/payment_details_page.dart';
import '../../features/payment/pages/payment_success_page.dart';
import '../../features/payment/pages/payment_method_selection_page.dart';
import '../../features/payment/pages/payment_instruction_page.dart';
import '../../features/payment/pages/payment_waiting_page.dart';
import '../../features/payment/pages/paypal_checkout_page.dart';
import '../../features/payment/models/payment_gateway_model.dart';
import '../../features/payment/models/payment_params.dart';
import '../../core/services/data/models/service_provider_model.dart';
import '../../features/home/home_page.dart';
import '../../features/splash/splash_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/services/providers_list_page.dart';
import '../../features/booking/booking_page.dart';

import '../../features/booking/booking_success_page.dart';
import '../../features/main_layout/main_page.dart';
import '../../features/booking/my_bookings_page.dart';
import '../../features/favorites/favorites_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/booking/report_page.dart';
import '../../features/booking/booking_details_page.dart';
import '../../features/search/search_page.dart';

import 'package:servino_client/core/errors/pages/server_error_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/auth/forgot_password_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/auth/otp_page.dart';
import '../../features/auth/register_success_page.dart';
import '../../features/auth/reset_password_page.dart';
import '../../features/auth/password_reset_success_page.dart';
import '../../features/chat/chat_page.dart';
import '../../features/chat/pages/chat_request_waiting_page.dart';
import '../../features/profile/personal_information_page.dart';
import '../../features/support/support_page.dart';
import '../../features/support/support_chat_page.dart';
import '../../features/profile/terms_of_use_page.dart';
import '../../features/profile/privacy_policy_page.dart';
import '../../features/auth/complete_profile_page.dart';
import '../../features/auth/banned_page.dart';
import '../../features/profile/contact_us_page.dart';
import 'routes.dart';

/// Application Router
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return _buildRoute(const SplashPage(), settings);
      case Routes.onboarding:
        return _buildRoute(const OnboardingPage(), settings);
      case Routes.home:
        return _buildRoute(const HomePage(), settings);
      case Routes.providersList:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(ProvidersListPage(arguments: args), settings);
      case Routes.chat:
        final args =
            settings.arguments as Map<String, dynamic>?; // Accept arguments
        return MaterialPageRoute(
          builder: (_) => ChatPage(initialArguments: args),
        );

      case Routes.paymentRequired:
        final provider = settings.arguments as ServiceProviderModel;
        return _buildRoute(PaymentRequiredPage(provider: provider), settings);

      case Routes.paymentDetails:
        final args = settings.arguments as PaymentParams;
        return _buildRoute(PaymentDetailsPage(params: args), settings);

      case Routes.paymentSuccess:
        final args = settings.arguments as PaymentSuccessPageParams;
        return _buildRoute(PaymentSuccessPage(params: args), settings);

      case Routes.paymentMethodSelection:
        final params = settings.arguments as PaymentParams;
        return _buildRoute(
          PaymentMethodSelectionPage(params: params),
          settings,
        );

      case Routes.paymentInstruction:
        final args = settings.arguments as Map<String, dynamic>;
        // Check if passed 'gateway' object or 'methodId' string
        PaymentGatewayModel method;
        if (args.containsKey('gateway')) {
          method = args['gateway'] as PaymentGatewayModel;
        } else {
          throw Exception('PaymentGatewayModel is required');
        }
        return _buildRoute(
          PaymentInstructionPage(params: args['params'], method: method),
          settings,
        );

      case Routes.paypalCheckout:
        final params = settings.arguments as PaypalCheckoutPageParams;
        return _buildRoute(PaypalCheckoutPage(args: params), settings);

      case Routes.paymentWaiting:
        final args = settings.arguments as Map<String, dynamic>;
        final params = args['params'] as PaymentParams;
        final transactionId = args['transactionId'] as String?;

        return _buildRoute(
          PaymentWaitingPage(params: params, transactionId: transactionId),
          settings,
        );

      case Routes.providerDetails:
        final provider = settings.arguments as ServiceProviderModel;
        return _buildRoute(ProviderDetailsPage(provider: provider), settings);
      case Routes.booking:
        // Argument can be just Provider model (old way) or Map (new way)
        ServiceProviderModel provider;
        bool isChatInitiated = false;

        if (settings.arguments is ServiceProviderModel) {
          provider = settings.arguments as ServiceProviderModel;
        } else if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          provider = args['provider'] as ServiceProviderModel;
          isChatInitiated = args['isChatInitiated'] as bool? ?? false;
        } else {
          return _buildRoute(
            Scaffold(
              body: Center(child: Text('Invalid arguments for Booking')),
            ),
            settings,
          );
        }
        return _buildRoute(
          BookingPage(provider: provider, isChatInitiated: isChatInitiated),
          settings,
        );
      case Routes.bookingDetails:
        final booking = settings.arguments as Map<String, dynamic>;
        return _buildRoute(BookingDetailsPage(booking: booking), settings);
      case Routes.bookingSuccess:
        bool isChatInitiated = false;
        Map<String, dynamic>? chatArguments;

        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          isChatInitiated = args['isChatInitiated'] as bool? ?? false;
          chatArguments = args['chatArguments'] as Map<String, dynamic>?;
        } else if (settings.arguments is bool) {
          isChatInitiated = settings.arguments as bool;
        }

        return _buildRoute(
          BookingSuccessPage(
            isChatInitiated: isChatInitiated,
            chatArguments: chatArguments,
          ),
          settings,
        );
      case Routes.myBookings:
        return _buildRoute(const MyBookingsPage(), settings);
      case Routes.favorites:
        return _buildRoute(const FavoritesPage(), settings);
      case Routes.notifications:
        return _buildRoute(const NotificationsPage(), settings);
      case Routes.main:
        return _buildRoute(const MainPage(), settings);
      case Routes.report:
        return _buildRoute(const ReportPage(), settings);
      case Routes.search:
        return _buildRoute(const SearchPage(), settings);
      case Routes.login:
        return _buildRoute(const LoginPage(), settings);
      case Routes.register:
        return _buildRoute(const RegisterPage(), settings);
      case Routes.otp:
        return _buildRoute(const OtpPage(), settings);
      case Routes.forgotPassword:
        return _buildRoute(const ForgotPasswordPage(), settings);
      case Routes.profile:
        return _buildRoute(const ProfilePage(), settings);
      case Routes.registerSuccess:
        return _buildRoute(const RegisterSuccessPage(), settings);
      case Routes.resetPassword:
        return _buildRoute(const ResetPasswordPage(), settings);
      case Routes.passwordResetSuccess:
        return _buildRoute(const PasswordResetSuccessPage(), settings);

      case Routes.chatRequestWaiting:
        return _buildRoute(const ChatRequestWaitingPage(), settings);
      case Routes.personalInformation:
        return MaterialPageRoute(
          builder: (_) => const PersonalInformationPage(),
        );
      case Routes.helpCenter:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => SupportPage(
            initialImages: args?['initialImages'],
            initialDescription: args?['initialDescription'],
            additionalHiddenInfo: args?['additionalHiddenInfo'],
          ),
        );
      case Routes.supportChat:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => SupportChatPage(
            category: args['category'],
            description: args['description'],
            imagePaths: args['imagePaths'],
            ticketId: args['ticketId'],
            userInfo: args['userInfo'],
          ),
        );
      case Routes.termsOfUse:
        return MaterialPageRoute(builder: (_) => const TermsOfUsePage());
      case Routes.privacyPolicy:
        return MaterialPageRoute(builder: (_) => const PrivacyPolicyPage());
      case Routes.completeProfile:
        return _buildRoute(const CompleteProfilePage(), settings);
      case Routes.banned:
        return MaterialPageRoute(
          builder: (_) => const BannedPage(),
          settings: settings,
        );
      case Routes.contactUs:
        return _buildRoute(const ContactUsPage(), settings);
      case Routes.serverError:
        return MaterialPageRoute(
          builder: (context) => ServerErrorPage(
            onRetry: () {
              Navigator.of(context).pop();
            },
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
          settings: settings,
        );
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static void navigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static void navigateAndReplace(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  static void navigateAndRemoveUntil(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  static void goBack(BuildContext context) {
    Navigator.pop(context);
  }
}
