// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:servino_client/core/theme/assets.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/core/widgets/animated_background.dart';
import 'package:servino_client/features/support/data/repo/support_repo.dart';
import 'package:servino_client/core/api/dio_consumer.dart';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:servino_client/core/cache/cache_helper.dart';
import 'package:servino_client/core/api/end_point.dart';

import 'package:servino_client/features/support/support_chat_page.dart';

class SupportPage extends StatefulWidget {
  final List<String>? initialImages;
  final String? initialDescription;
  final String? additionalHiddenInfo;

  const SupportPage({
    super.key,
    this.initialImages,
    this.initialDescription,
    this.additionalHiddenInfo,
  });

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _issueController = TextEditingController();
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  // Real Data
  List<Map<String, dynamic>> _history = [];
  bool _isLoadingHistory = true;
  late SupportRepository _repository;

  String? _selectedCategory;
  final List<String> _categories = [
    'support_cat_payment',
    'support_cat_client',
    'support_cat_app',
    'support_cat_other',
  ];

  @override
  void initState() {
    super.initState();
    _repository = SupportRepository(api: DioConsumer(dio: Dio()));
    _tabController = TabController(length: 2, vsync: this);
    _fetchHistory();

    // Pre-fill fields if passed
    if (widget.initialDescription != null) {
      _issueController.text = widget.initialDescription!;
    }
    if (widget.initialImages != null) {
      _selectedImages.addAll(widget.initialImages!.map((e) => File(e)));
    }
  }

  Future<void> _fetchHistory() async {
    try {
      final tickets = await _repository.getTickets();
      if (mounted) {
        setState(() {
          _history = tickets;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((x) => File(x.path)));
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitSupportRequest() async {
    if (_selectedCategory == null) {
      debugPrint('support_select_category_error'.tr());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('support_select_category_error'.tr())),
      );
      return;
    }

    if (_issueController.text.trim().isEmpty && _selectedImages.isEmpty) {
      debugPrint('support_form_empty_error'.tr());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('support_form_empty_error'.tr())));
      return;
    }

    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Extract User Info from Token
      String? userInfoStr;
      try {
        final token = await SecureCacheHelper().getData(key: ApiKey.token);
        if (token != null) {
          final decodedToken = JwtDecoder.decode(token);
          if (decodedToken['data'] != null) {
            final data = decodedToken['data'];
            final name = data['name'] ?? 'N/A';
            final email = data['email'] ?? 'N/A';
            final id = data['id']?.toString() ?? 'N/A';
            final phone = data['phone'] ?? 'N/A';

            userInfoStr = "Name: $name\nEmail: $email\nPhone: $phone\nID: $id";
          }
        }

        // Append Additional Hidden Info (e.g. Booking ID)
        if (widget.additionalHiddenInfo != null) {
          userInfoStr =
              "${userInfoStr ?? ''}\n\n--- Context ---\n${widget.additionalHiddenInfo}";
        }
      } catch (e) {
        debugPrint('Error extracting user info: $e');
      }

      final ticketId = await _repository.createTicket(
        category: _selectedCategory!,
        description: _issueController.text.trim(),
        images: _selectedImages,
        userInfo: userInfoStr,
      );

      if (mounted) {
        Navigator.pop(context); // Hide Loading
        if (ticketId != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SupportChatPage(
                category: _selectedCategory!.tr(),
                description: _issueController.text.trim(),
                imagePaths: _selectedImages
                    .map((e) => e.path)
                    .toList(), // Passed for local preview maybe, but chat will reload
                ticketId: ticketId.toString(),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create ticket')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _issueController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'support_page_title'.tr(),
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),

          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 10.h),
                // Custom Tab Bar
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20.w),
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    dividerColor: Colors.transparent,
                    indicatorPadding: EdgeInsets.zero,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark
                        ? Colors.white70
                        : AppColors.textSecondary,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      fontFamily: 'Tajawal',
                    ),
                    tabs: [
                      Tab(text: 'support_tab_new'.tr()),
                      Tab(text: 'support_tab_history'.tr()),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNewTicketForm(isDark),
                      _buildHistoryList(isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewTicketForm(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        children: [
          // Header Illustration
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.secondary.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Center(
              child: SvgPicture.asset(
                Assets.supportSvg2,
                width: 40.w,
                height: 40.w,
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Glassmorphic Form
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'support_category_label'.tr(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Category Wrap
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat.tr()),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected ? cat : null;
                            });
                          },
                          selectedColor: AppColors.primary,
                          avatarBorder: Border.all(
                            color: AppColors.surfaceDark,
                          ),
                          backgroundColor: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.white,
                          labelStyle: TextStyle(
                            fontFamily: 'Tajawal',
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                      ? Colors.white
                                      : AppColors.surfaceDark),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 24.h),

                    Text(
                      'support_issue_description'.tr(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    // Text Field
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(0.2)
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.1),
                        ),
                      ),
                      child: TextField(
                        controller: _issueController,
                        maxLines: 4,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'support_issue_hint'.tr(),
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white.withOpacity(0.5)
                                : Colors.grey,
                            fontSize: 14.sp,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16.w),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Image Picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'support_attach_images'.tr(),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: _pickImages,
                          icon: Icon(
                            Icons.add_photo_alternate_rounded,
                            color: AppColors.primary,
                            size: 28.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    if (_selectedImages.isNotEmpty)
                      SizedBox(
                        height: 80.h,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(width: 10.w),
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: Image.file(
                                    _selectedImages[index],
                                    width: 80.w,
                                    height: 80.h,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: InkWell(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: EdgeInsets.all(4.r),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: 14.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          height: 80.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : AppColors.primary.withOpacity(0.05),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 24.sp,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.primary.withOpacity(0.6),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'support_tap_to_upload'.tr(),
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: isDark ? Colors.white70 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 30.h),

          // Submit
          Container(
            width: double.infinity,
            height: 56.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _submitSupportRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(Assets.chat2, width: 24.w, height: 24.w),
                  SizedBox(width: 10.w),
                  Text(
                    'support_start_chat'.tr(),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(bool isDark) {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(Assets.supportSvg2, width: 100.w, height: 100.w),
            Text(
              'support_history_empty'.tr(),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      itemCount: _history.length,
      separatorBuilder: (c, i) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final ticket = _history[index];
        final isOpen = ticket['status'] == 'Open';

        return ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 8.h,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SupportChatPage(
                        category: ticket['category'].toString().tr(),
                        description: ticket['description'],
                        imagePaths: const [],
                        ticketId: ticket['id'].toString(),
                      ),
                    ),
                  );
                },
                leading: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    Assets.supportSvg2,
                    width: 20.w,
                    height: 20.w,
                  ),
                ),
                title: Text(
                  '${'support_ticket_id'.tr()} ${ticket['id']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: 14.sp,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4.h),
                    Text(
                      ticket['category'].toString().tr(),
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                        fontSize: 12.sp,
                      ),
                    ),
                    Text(
                      ticket['date'],
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
                trailing: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isOpen ? Colors.green : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    isOpen
                        ? 'ticket_status_open'.tr()
                        : 'ticket_status_closed'.tr(),
                    style: TextStyle(
                      color: isOpen ? Colors.green : Colors.grey,
                      fontSize: 10.sp,

                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
