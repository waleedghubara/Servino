// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:servino_client/core/theme/colors.dart';
import 'package:servino_client/core/utils/toast_utils.dart';
import 'package:servino_client/core/widgets/animated_background.dart';
import 'package:servino_client/features/auth/logic/auth_provider.dart';

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;

  String? _selectedGender;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name);
    _emailController = TextEditingController(text: user?.email);
    _phoneController = TextEditingController(text: user?.phone);
    _dobController = TextEditingController(text: user?.dob);
    _selectedGender = user?.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final success = await context.read<AuthProvider>().updateProfile(
        name: _nameController.text,
        phone: _phoneController.text,
        dob: _dobController.text,
        gender: _selectedGender,
        image: _imageFile,
      );

      if (success) {
        ToastUtils.showSuccess(
          context: context,
          message: 'Profile Updated Successfully',
        );
        Navigator.pop(context);
      } else {
        final error = context.read<AuthProvider>().errorMessage;
        ToastUtils.showError(
          context: context,
          message: error ?? 'Failed to update profile',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().user;
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'profile_personal_info'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: AppColors.primary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
            size: 24.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24.w, 100.h, 24.w, 100.h),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Picture
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            padding: EdgeInsets.all(4.r),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey[300],
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50.r,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : (user?.fullImage != null &&
                                            user!.fullImage!.isNotEmpty
                                        ? CachedNetworkImageProvider(
                                                user.fullImage!,
                                              )
                                              as ImageProvider
                                        : null),
                              onBackgroundImageError:
                                  _imageFile != null ||
                                      (user?.fullImage != null &&
                                          user!.fullImage!.isNotEmpty)
                                  ? (_, _) {}
                                  : null,
                              child:
                                  (_imageFile == null &&
                                      (user?.fullImage == null ||
                                          user!.fullImage!.isEmpty))
                                  ? Icon(
                                      Icons.person,
                                      size: 50.sp,
                                      color: Colors.grey[400],
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // Info Fields
                    _buildTextField(
                      context,
                      controller: _nameController,
                      label: 'profile_name'.tr(),
                      icon: Icons.person_outline,
                    ),
                    _buildTextField(
                      context,
                      controller: _emailController,
                      label: 'profile_email'.tr(),
                      icon: Icons.email_outlined,
                      readOnly: true, // Email not editable
                    ),
                    _buildTextField(
                      context,
                      controller: _phoneController,
                      label: 'profile_phone'.tr(),
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: _buildTextField(
                          context,
                          controller: _dobController,
                          label: 'profile_dob'.tr(),
                          icon: Icons.cake_outlined,
                        ),
                      ),
                    ),
                    _buildGenderDropdown(context),
                  ],
                ),
              ),
            ),

          // Floating Save Button
          if (!isLoading)
            Positioned(
              bottom: 24.h,
              left: 24.w,
              right: 24.w,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 8,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                ),
                child: Text(
                  'save_changes'
                      .tr(), // Make sure to add this key or use 'Save'
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.grey : Colors.grey[600],
            fontSize: 14.sp,
          ),
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
        ),
        validator: (value) {
          if (!readOnly && (value == null || value.isEmpty)) {
            return '$label is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGenderDropdown(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGender,
          hint: Row(
            children: [
              Icon(Icons.wc_outlined, color: AppColors.primary),
              SizedBox(width: 12.w),
              Text(
                'profile_gender'.tr(),
                style: TextStyle(
                  color: isDark ? Colors.grey : Colors.grey[600],
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: isDark ? Colors.white : Colors.black,
          ),
          dropdownColor: isDark ? AppColors.backgroundDark : Colors.white,
          items: ['Male', 'Female'].map((String value) {
            // Localize displayed value
            String displayValue = value == 'Male'
                ? 'gender_male'.tr()
                : 'gender_female'.tr();

            // Fallback if keys missing (though user asked for translation)
            if (displayValue == 'gender_male') displayValue = 'Male';
            if (displayValue == 'gender_female') displayValue = 'Female';

            return DropdownMenuItem<String>(
              value:
                  value, // Keep value as 'Male'/'Female' for backend compatibility
              child: Text(
                displayValue,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedGender = newValue;
            });
          },
        ),
      ),
    );
  }
}
