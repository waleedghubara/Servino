// ignore_for_file: unused_catch_stack, dead_code, deprecated_member_use

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import '../../services/firestore_config_service.dart';

class ZegoService {
  static bool _isInitialized = false;
  static String? _currentUserId;
  static String? _currentAvatarUrl;

  Future<void> onUserLogin(
    String userId,
    String userName, [
    String? avatarUrl,
  ]) async {
    if (_isInitialized) {
      if (_currentUserId != userId) {
        try {
          await ZegoUIKitPrebuiltCallInvitationService().uninit();
        } catch (e) {
          // debugPrint('ZegoService: Error during uninit: $e');
        }
        _isInitialized = false;
        _currentUserId = null;
        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        return;
      }
    }

    _currentAvatarUrl = avatarUrl;
    try {
      final int appId = FirestoreConfigService().zegoAppId;
      final String appSign = FirestoreConfigService().zegoAppSign;

      if (appId == 0 || appSign.isEmpty) {
        debugPrint('ZegoService: AppID or AppSign is invalid. Skipping init.');
        return;
      }

      // Small delay for Android 15 stability
      await Future.delayed(const Duration(milliseconds: 500));

      final bool isArabic =
          PlatformDispatcher.instance.locale.languageCode == 'ar';

      ZegoUIKitPrebuiltCallInvitationService().init(
        appID: appId,
        appSign: appSign,
        userID: userId,
        userName: userName,
        plugins: [ZegoUIKitSignalingPlugin()],
        innerText: isArabic
            ? ZegoCallInvitationInnerText(
                incomingVideoCallDialogMessage: 'مكالمة فيديو واردة...',
                incomingVoiceCallDialogMessage: 'مكالمة صوتية واردة...',
                incomingVideoCallPageMessage: 'مكالمة فيديو واردة...',
                incomingVoiceCallPageMessage: 'مكالمة صوتية واردة...',
                outgoingVideoCallPageMessage: 'جاري الاتصال...',
                outgoingVoiceCallPageMessage: 'جاري الاتصال...',
                incomingCallPageDeclineButton: 'رفض',
                incomingCallPageAcceptButton: 'رد',
                outgoingCallPageACancelButton: 'إلغاء',
                permissionConfirmDialogTitle:
                    'السماح لـ Servino بالظهور فوق التطبيقات الأخرى',
                permissionConfirmDialogAllowButton: 'سماح',
                permissionConfirmDialogDenyButton: 'رفض',
                systemAlertWindowConfirmDialogSubTitle:
                    'الظهور فوق التطبيقات الأخرى',
                permissionManuallyConfirmDialogTitle:
                    'يرجى تفعيل الصلاحيات التالية يدوياً:',
                permissionManuallyConfirmDialogSubTitle:
                    '• السماح بالتشغيل التلقائي\n• عرض التنبيهات على شاشة القفل\n• الظهور فوق التطبيقات الأخرى\n• العرض على شاشة القفل\n• النوافذ المنبثقة في الخلفية',
              )
            : ZegoCallInvitationInnerText(),
        ringtoneConfig: ZegoRingtoneConfig(
          incomingCallPath: 'assets/sounds/incoming_call.mp3',
          outgoingCallPath: 'assets/sounds/outgoing_call.mp3',
        ),
        config: ZegoCallInvitationConfig(
          permissions: [
            ZegoCallInvitationPermission.camera,
            ZegoCallInvitationPermission.microphone,
            // ZegoCallInvitationPermission.systemAlertWindow, // Disabled to prevent SIGSEGV on some devices
          ],
        ),
        notificationConfig: ZegoCallInvitationNotificationConfig(
          androidNotificationConfig: ZegoCallAndroidNotificationConfig(
            callChannel: ZegoCallAndroidNotificationChannelConfig(
              channelID: "zego_video_call",
              channelName: "Zego Video Call",
              sound: "incoming_call",
            ),
          ),
          iOSNotificationConfig: ZegoCallIOSNotificationConfig(
            appName: "Servino",
          ),
        ),
        uiConfig: ZegoCallInvitationUIConfig(
          inviter: ZegoCallInvitationInviterUIConfig(
            showAvatar: true,
            showCentralName: true,
            showCallingText: true,
            spacingBetweenAvatarAndName: 20,
            spacingBetweenNameAndCallingText: 10,
            // Hide default buttons to show custom ones
            cancelButton: ZegoCallButtonUIConfig(visible: false),
            microphoneButton: ZegoCallButtonUIConfig(visible: false),
            speakerButton: ZegoCallButtonUIConfig(visible: false),
            cameraButton: ZegoCallButtonUIConfig(visible: false),
            // Premium Background
            backgroundBuilder: (context, size, info) {
              String? avatarUrl;
              try {
                final data =
                    jsonDecode(info.customData) as Map<String, dynamic>;
                if (data.containsKey('avatars')) {
                  final avatars = data['avatars'] as Map<String, dynamic>;
                  if (info.invitees.isNotEmpty) {
                    avatarUrl = avatars[info.invitees.first.id];
                  }
                }
              } catch (e) {
                // ignore
              }
              avatarUrl ??= info.invitees.isNotEmpty
                  ? 'https://ui-avatars.com/api/?name=${info.invitees.first.name}&background=random&size=512'
                  : null;

              return Stack(
                children: [
                  Container(color: Colors.black),
                  if (avatarUrl != null)
                    Positioned.fill(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          opacity: const AlwaysStoppedAnimation(0.5),
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.black),
                        ),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            // Custom Foreground with Buttons at the bottom
            foregroundBuilder: (context, size, info) {
              return Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Speaker Button
                      _buildButtonWithLabel(
                        label: isArabic ? 'مكبر الصوت' : 'Speaker',
                        child: ZegoSwitchAudioOutputButton(
                          buttonSize: const Size(60, 60),
                          iconSize: const Size(30, 30),
                        ),
                      ),
                      // Cancel Button
                      _buildButtonWithLabel(
                        label: isArabic ? 'إلغاء' : 'Cancel',
                        child: ZegoTextIconButton(
                          icon: ButtonIcon(
                            icon: const Icon(
                              Icons.call_end,
                              color: Colors.white,
                            ),
                            backgroundColor: Colors.red,
                          ),
                          buttonSize: const Size(70, 70),
                          iconSize: const Size(35, 35),
                          onPressed: () {
                            ZegoUIKitPrebuiltCallInvitationService().cancel(
                              callees: info.invitees
                                  .map((e) => ZegoCallUser(e.id, e.name))
                                  .toList(),
                            );
                          },
                        ),
                      ),
                      // Microphone Button
                      _buildButtonWithLabel(
                        label: isArabic ? 'الميكروفون' : 'Microphone',
                        child: ZegoToggleMicrophoneButton(
                          buttonSize: const Size(60, 60),
                          iconSize: const Size(30, 30),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            minimized: ZegoCallInvitationInviterMinimizedUIConfig(
              showTips: true,
            ),
          ),
          invitee: ZegoCallInvitationInviteeUIConfig(
            microphoneButton: ZegoCallButtonUIConfig(visible: false),
            speakerButton: ZegoCallButtonUIConfig(visible: false),
            backgroundBuilder: (context, size, info) {
              String? avatarUrl;
              try {
                final data =
                    jsonDecode(info.customData) as Map<String, dynamic>;
                if (data.containsKey('avatars')) {
                  final avatars = data['avatars'] as Map<String, dynamic>;
                  avatarUrl = avatars[info.inviter.id];
                }
              } catch (e) {
                // ignore
              }
              avatarUrl ??=
                  'https://ui-avatars.com/api/?name=${info.inviter.name}&background=random&size=512';

              return Stack(
                children: [
                  Container(color: Colors.black),
                  Positioned.fill(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        opacity: const AlwaysStoppedAnimation(0.5),
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: Colors.black),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            minimized: ZegoCallInvitationInviteeMinimizedUIConfig(
              showTips: true,
            ),
          ),
        ),
        requireConfig: (ZegoCallInvitationData data) {
          var config = (data.invitees.length > 1)
              ? ZegoCallInvitationType.videoCall == data.type
                    ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
                    : ZegoUIKitPrebuiltCallConfig.groupVoiceCall()
              : ZegoCallInvitationType.videoCall == data.type
              ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
              : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

          config.topMenuBar.isVisible = true;
          config.topMenuBar.buttons = [
            ZegoCallMenuBarButtonName.minimizingButton,
            ZegoCallMenuBarButtonName.showMemberListButton,
          ];

          config.avatarBuilder =
              (
                BuildContext context,
                Size size,
                ZegoUIKitUser? user,
                Map<String, dynamic> extraInfo,
              ) {
                String? avatarUrl;

                // 1. Try to get avatar from extraInfo
                if (extraInfo.containsKey('customData')) {
                  try {
                    final customData =
                        jsonDecode(extraInfo['customData'] as String)
                            as Map<String, dynamic>;
                    if (customData.containsKey('avatars')) {
                      final avatars =
                          customData['avatars'] as Map<String, dynamic>;
                      avatarUrl = avatars[user?.id];
                    }
                  } catch (e) {
                    // ignore
                  }
                }

                // 2. Fallback to passed data customData (Crucial for Invitation Screen)
                if (avatarUrl == null && data.customData.isNotEmpty) {
                  try {
                    final customData =
                        jsonDecode(data.customData) as Map<String, dynamic>;
                    if (customData.containsKey('avatars')) {
                      final avatars =
                          customData['avatars'] as Map<String, dynamic>;
                      avatarUrl = avatars[user?.id];
                    }
                  } catch (e) {
                    // ignore
                  }
                }

                // 3. Fallback: if it's the local user, use stored _currentAvatarUrl
                if (avatarUrl == null && user?.id == _currentUserId) {
                  avatarUrl = _currentAvatarUrl;
                }

                // 4. Fallback: UI Avatars
                avatarUrl ??=
                    'https://ui-avatars.com/api/?name=${user?.name}&background=random&size=512';

                return ClipRRect(
                  borderRadius: BorderRadius.circular(size.width),
                  child: Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: size.width * 0.6,
                        ),
                      );
                    },
                  ),
                );
              };

          config.audioVideoViewConfig.useVideoViewAspectFill = true;
          config.audioVideoViewConfig.showUserNameOnView = false;

          return config;
        },
      );
      _isInitialized = true;
      _currentUserId = userId;
      // debugPrint('ZegoService: Initialization successful');
    } catch (e, stack) {
      // debugPrint('ZegoService: Fatal error during init: $e\n$stack');
    }
  }

  static Widget _buildButtonWithLabel({
    required Widget child,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Tajawal',
            fontSize: 12,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Future<void> onUserLogout() async {
    if (!_isInitialized) return;
    try {
      await ZegoUIKitPrebuiltCallInvitationService().uninit();
    } catch (e) {
      // debugPrint('ZegoService: Error during uninit: $e');
    } finally {
      _isInitialized = false;
      _currentUserId = null;
    }
  }
}
