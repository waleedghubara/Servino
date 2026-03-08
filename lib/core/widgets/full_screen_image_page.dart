import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FullScreenImagePage extends StatefulWidget {
  final String imageUrl; // Can be network URL or local file path
  const FullScreenImagePage({super.key, required this.imageUrl});

  @override
  State<FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  bool _isDownloading = false;

  Future<void> _downloadImage() async {
    if (_isDownloading) return;
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        // Try photos/media if SDK 33+

        if (await Permission.photos.request().isGranted) {
        } else {
          _showSnackBar("Storage permission denied");
          return;
        }
      }
    } else if (Platform.isIOS) {}

    setState(() {
      _isDownloading = true;
    });

    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception("Could not find save directory");
      }

      final fileName = 'servino_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savePath = '${directory.path}/$fileName';

      if (widget.imageUrl.startsWith('http')) {
        await Dio().download(widget.imageUrl, savePath);
      } else {
        final file = File(widget.imageUrl);
        if (await file.exists()) {
          await file.copy(savePath);
        } else {
          throw Exception("Source file not found");
        }
      }

      _showSnackBar("Image saved to $savePath");
    } catch (e) {
      // debugPrint("Download error: $e");
      _showSnackBar("Failed to save image");
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isNetwork = widget.imageUrl.startsWith('http');
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: _isDownloading
                ? SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download),
            onPressed: _downloadImage,
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: isNetwork
              ? CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              : Image.file(File(widget.imageUrl), fit: BoxFit.contain),
        ),
      ),
    );
  }
}
