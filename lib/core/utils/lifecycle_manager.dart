// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:servino_client/core/api/end_point.dart';

class LifecycleManager extends StatefulWidget {
  final Widget child;
  final String? userId;
  final String? role;

  const LifecycleManager({
    super.key,
    required this.child,
    this.userId,
    this.role,
  });

  @override
  State<LifecycleManager> createState() => _LifecycleManagerState();
}

class _LifecycleManagerState extends State<LifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateStatus(true);
  }

  @override
  void didUpdateWidget(covariant LifecycleManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId == null && widget.userId != null) {
      _updateStatus(true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _updateStatus(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _updateStatus(false);
    }
  }

  void _updateStatus(bool isOnline) async {
    // debugPrint(
    //   'LifecycleManager: Updating status for ${widget.userId} to $isOnline',
    // );
    if (widget.userId == null) {
      // debugPrint('LifecycleManager: Early return, userId is null');
      return;
    }

    try {
      final dio = Dio();
      final url = '${EndPoint.baseUrl}chat/update_status.php';
      // debugPrint(
      //   'LifecycleManager: Calling POST $url with ${{'user_id': widget.userId, 'is_online': isOnline, 'role': widget.role}}',
      // );
      final response = await dio.post(
        url,
        data: {
          'user_id': widget.userId,
          'is_online': isOnline,
          'role': widget.role,
        },
      );
      // debugPrint('LifecycleManager: Response: ${response.data}');
    } catch (e) {
      // debugPrint('LifecycleManager: Error updating status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
