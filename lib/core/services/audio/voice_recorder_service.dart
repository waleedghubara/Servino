import 'dart:io';
// import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentPath;
  bool _isRecording = false;

  // Stream for UI visualization (amplitude/waveform)
  Stream<Amplitude> get onAmplitudeChanged =>
      _audioRecorder.onAmplitudeChanged(const Duration(milliseconds: 100));

  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  Future<void> start() async {
    if (!await hasPermission()) return;
    if (_isRecording) return;

    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Use AAC (m4a) as Primary - Most compatible format for Android/iOS
    final path = '${directory.path}/voice_$timestamp.m4a';
    _currentPath = path;

    const aacConfig = RecordConfig(
      encoder: AudioEncoder.aacLc,
      numChannels: 1,
      sampleRate: 16000,
      bitRate: 32000,
    );

    try {
      await _audioRecorder.start(aacConfig, path: path);
      _isRecording = true;
      // debugPrint('Recording started (AAC) at: $path');
    } catch (e) {
      // debugPrint('AAC failed, trying OPUS fallback: $e');

      final opusPath = '${directory.path}/voice_$timestamp.ogg';
      _currentPath = opusPath;
      const opusConfig = RecordConfig(
        encoder: AudioEncoder.opus,
        numChannels: 1,
      );

      try {
        await _audioRecorder.start(opusConfig, path: opusPath);
        _isRecording = true;
        // debugPrint('Recording started (OPUS) at: $opusPath');
      } catch (e2) {
        // debugPrint('Recording failed completely: $e2');
        _isRecording = false;
        rethrow;
      }
    }
  }

  Future<String?> stop() async {
    if (!_isRecording) return null;
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      // debugPrint('Recording stopped. File at: $path');
      return path ?? _currentPath;
    } catch (e) {
      // debugPrint('Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  Future<void> cancel() async {
    try {
      await _audioRecorder.stop();
      _isRecording = false;
      if (_currentPath != null) {
        final file = File(_currentPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      // debugPrint('Error canceling record: $e');
    }
  }

  Future<void> dispose() async {
    _audioRecorder.dispose();
  }
}
