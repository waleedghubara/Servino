// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../theme/colors.dart';

class VoiceMessageWidget extends StatefulWidget {
  final String url;
  final bool isMe;

  const VoiceMessageWidget({super.key, required this.url, required this.isMe});

  @override
  State<VoiceMessageWidget> createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget>
    with AutomaticKeepAliveClientMixin {
  late AudioPlayer _player;

  // Static variable to track the currently playing player globally
  static AudioPlayer? _activePlayer;

  @override
  bool get wantKeepAlive => true; // Keep state when scrolling

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudioSession();
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
  }

  @override
  void dispose() {
    if (_activePlayer == _player) {
      _activePlayer = null;
    }
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _handlePlayPause() async {
    try {
      if (_player.playing) {
        await _player.pause();
      } else {
        // Stop any currently playing audio in other widgets
        if (_activePlayer != null && _activePlayer != _player) {
          await _activePlayer!.stop();
        }
        _activePlayer = _player;

        if (_player.processingState == ProcessingState.idle) {
          if (widget.url.startsWith('http')) {
            await _player.setAudioSource(
              AudioSource.uri(Uri.parse(widget.url)),
            );
          } else {
            await _player.setAudioSource(AudioSource.file(widget.url));
          }
        }

        // If finished, seek back to start
        if (_player.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }

        await _player.play();
      }
    } catch (e) {
      // debugPrint("Error playing audio: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 220.w,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        children: [
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final processingState = playerState?.processingState;
              final playing = playerState?.playing ?? false;

              if (processingState == ProcessingState.loading ||
                  processingState == ProcessingState.buffering) {
                return Container(
                  padding: EdgeInsets.all(8.r),
                  child: SizedBox(
                    width: 24.sp,
                    height: 24.sp,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.isMe ? Colors.white : AppColors.primary,
                    ),
                  ),
                );
              }

              return InkWell(
                onTap: _handlePlayPause,
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: widget.isMe
                        ? Colors.white.withOpacity(0.2)
                        : isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.black12,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    (playing && processingState != ProcessingState.completed)
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: widget.isMe ? Colors.white : AppColors.primary,
                    size: 24.sp,
                  ),
                ),
              );
            },
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, playerStateSnapshot) {
                final processingState =
                    playerStateSnapshot.data?.processingState;
                final isCompleted =
                    processingState == ProcessingState.completed;

                return StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (context, snapshot) {
                    final position = isCompleted
                        ? Duration.zero
                        : (snapshot.data ?? Duration.zero);
                    return StreamBuilder<Duration?>(
                      stream: _player.durationStream,
                      builder: (context, durationSnapshot) {
                        final duration = durationSnapshot.data ?? Duration.zero;
                        final maxDuration = duration.inSeconds.toDouble() > 0
                            ? duration.inSeconds.toDouble()
                            : 1.0;
                        final value = position.inSeconds.toDouble().clamp(
                          0.0,
                          maxDuration,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 10,
                                ),
                                trackHeight: 3.h,
                                thumbColor: widget.isMe
                                    ? Colors.white
                                    : AppColors.primary,
                                activeTrackColor: widget.isMe
                                    ? Colors.white
                                    : AppColors.primary,
                                inactiveTrackColor: widget.isMe
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.3),
                              ),
                              child: Slider(
                                min: 0,
                                max: maxDuration,
                                value: value,
                                onChanged: (val) {
                                  _player.seek(Duration(seconds: val.toInt()));
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: widget.isMe
                                        ? Colors.white70
                                        : Colors.grey,
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: widget.isMe
                                        ? Colors.white70
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
