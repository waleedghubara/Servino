// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/core/widgets/animated_background.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isLiveSupport = false;

  @override
  void initState() {
    super.initState();
    // Initial welcome message
    _addMessage(
      ChatMessage(
        text: 'help_welcome_message'.tr(),
        isUser: false,
        timestamp: DateTime.now(),
        shouldAnimate: true,
      ),
    );
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _messageController.clear();
    _addMessage(
      ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
    );

    if (_isLiveSupport) {
      // Send to backend (Simulated)
      setState(() => _isTyping = true);
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _isTyping = false);
      // Simulate admin silence or generic "received" in a real app this connects to socket
    } else {
      _processBotResponse(text);
    }
  }

  void _processBotResponse(String userText) async {
    setState(() => _isTyping = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate thinking

    String response = '';
    String lowerText = userText.toLowerCase();

    // Mock Knowledge Base
    if (lowerText.contains('human') ||
        lowerText.contains('support') ||
        lowerText.contains('agent') ||
        lowerText.contains('person') ||
        userText == 'help_escalate_human'.tr()) {
      response = 'help_support_connected'.tr();
      setState(() {
        _isLiveSupport = true;
      });
    } else if (lowerText.contains('book') ||
        lowerText.contains('appointment') ||
        lowerText.contains('schedule')) {
      response =
          'To book an appointment, browse our Services, select a provider, and choose a convenient time slot.';
    } else if (lowerText.contains('service') || lowerText.contains('offer')) {
      response =
          'We offer a wide range of services including Cleaning, Maintenance, Beauty, and Health consultations.';
    } else if (lowerText.contains('pay') || lowerText.contains('cost')) {
      response =
          'You can pay via Credit Card, Apple Pay, or Cash on Delivery. Payment details are secure.';
    } else {
      response =
          "I'm not sure about that. You can ask me about bookings, services, or payment, or ask to speak to a human.";
    }

    // Localize simple responses if simple keys existed, but for a mock model English/Arabic mix is tricky without full keys.
    // For now, if current locale is Arabic and response is English default, we might want to return Arabic text.
    // But since this is a "Mock Model", I'll assume the model is smart enough or returns based on context.
    // To match user expectation "Model with app data":
    if (context.locale.languageCode == 'ar' &&
        !response.contains('help_support_connected'.tr())) {
      // Simple Arabic Mock Fallbacks
      if (lowerText.contains('حجز') || lowerText.contains('موعد')) {
        response =
            'لحجز موعد، تصفح الخدمات لدينا، اختر مزود الخدمة، وحدد الوقت المناسب لك.';
      } else if (lowerText.contains('خدمة') || lowerText.contains('خدمات')) {
        response =
            'نقدم مجموعة واسعة من الخدمات بما في ذلك التنظيف، الصيانة، التجميل، والاستشارات الطبية.';
      } else if (lowerText.contains('دفع') || lowerText.contains('تكلفة')) {
        response =
            'يمكنك الدفع عبر البطاقة الائتمانية، أبل باي، أو الدفع عند الاستلام.';
      } else {
        response =
            "لست متأكداً من ذلك. يمكنك سؤالي عن الحجوزات، الخدمات، أو الدفع، أو طلب التحدث مع بشري.";
      }
    }

    setState(() => _isTyping = false);
    _addMessage(
      ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        shouldAnimate: true, // Typewriter effect
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'profile_help'.tr(), // "Help Center" or "Support"
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.9),
                AppColors.primary2,
                AppColors.secondaryDark,
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          SafeArea(
            child: Column(
              children: [
                // Chat List
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.w),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildMessageBubble(msg);
                    },
                  ),
                ),

                // Typing Indicator
                if (_isTyping)
                  Padding(
                    padding: EdgeInsets.only(left: 20.w, bottom: 10.h),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'typing'.tr(), // Localize if needed
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                // Suggestion Chips (Quick Actions)
                if (!_isLiveSupport)
                  Container(
                    height: 50.h,
                    margin: EdgeInsets.only(bottom: 8.h),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      children: [
                        _buildSuggestionChip('help_faq_booking'.tr()),
                        _buildSuggestionChip('help_faq_services'.tr()),
                        _buildSuggestionChip('help_faq_payment'.tr()),
                        _buildSuggestionChip(
                          'help_escalate_human'.tr(),
                          isAction: true,
                        ),
                      ],
                    ),
                  ),

                // Input Area
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),

                  decoration: BoxDecoration(
                    color: isDark ? AppColors.backgroundDark : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'help_chat_placeholder'.tr(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24.r),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[100],
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 10.h,
                              ),
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: _handleSubmitted,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () =>
                                _handleSubmitted(_messageController.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        constraints: BoxConstraints(maxWidth: 0.75.sw),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: msg.isUser
              ? AppColors.primary
              : isDark
              ? AppColors.backgroundDark
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
            bottomLeft: msg.isUser
                ? Radius.circular(20.r)
                : Radius.circular(4.r),
            bottomRight: msg.isUser
                ? Radius.circular(4.r)
                : Radius.circular(20.r),
          ),
          border: Border.all(
            color: msg.isUser
                ? AppColors.primary
                : isDark
                ? Colors.grey[800]!
                : Colors.grey[300]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isUser)
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Text(
                  _isLiveSupport
                      ? 'help_agent_name'.tr()
                      : 'help_bot_name'.tr(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (msg.isUser || !msg.shouldAnimate)
              Text(
                msg.text,
                style: TextStyle(
                  color: msg.isUser
                      ? Colors.white
                      : isDark
                      ? Colors.white
                      : Colors.black87,
                  fontSize: 14.sp,
                  height: 1.4,
                ),
              )
            else
              _TypewriterText(
                text: msg.text,
                style: TextStyle(
                  color: isDark
                      ? Colors.white
                      : Colors.black87, // Bot text color
                  fontSize: 14.sp,
                  height: 1.4,
                ),
                duration: const Duration(milliseconds: 20),
              ),
            SizedBox(height: 4.h),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat('hh:mm a').format(msg.timestamp),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.grey[400],
                  fontSize: 10.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label, {bool isAction = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(right: 8.w, bottom: 8.h),
      child: ActionChip(
        label: Text(
          label,
          style: TextStyle(
            color: isAction
                ? Colors.white
                : isDark
                ? Colors.white
                : AppColors.primary,
            fontSize: 12.sp,
          ),
        ),
        backgroundColor: isAction
            ? AppColors.primary
            : isDark
            ? AppColors.backgroundDark
            : Colors.white,
        side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        onPressed: () => _handleSubmitted(label),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool shouldAnimate;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.shouldAnimate = false,
  });
}

class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;

  const _TypewriterText({
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 30),
  });

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  String _displayedText = '';

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() async {
    for (int i = 0; i < widget.text.length; i++) {
      if (!mounted) return;
      setState(() {
        _displayedText += widget.text[i];
      });
      await Future.delayed(widget.duration);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayedText, style: widget.style);
  }
}
