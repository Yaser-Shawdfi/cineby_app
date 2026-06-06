import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_colors.dart';

/// Native fullscreen video player. Pushed onto the navigator when the JS
/// bridge detects a playable stream.
///
/// Uses `video_player` + `chewie` (the spec's fallback path — `better_player`
/// is unmaintained and breaks on modern Flutter SDKs).
class NativePlayerScreen extends ConsumerStatefulWidget {
  const NativePlayerScreen({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  ConsumerState<NativePlayerScreen> createState() =>
      _NativePlayerScreenState();
}

class _NativePlayerScreenState extends ConsumerState<NativePlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _failed = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Lock to landscape when player opens
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final url = widget.videoUrl;
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        allowedScreenSleep: false,
        aspectRatio: controller.value.aspectRatio == 0
            ? 16 / 9
            : controller.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.accent,
          handleColor: AppColors.accent,
          bufferedColor: AppColors.iconInactive,
          backgroundColor: AppColors.divider,
        ),
        placeholder: Container(color: Colors.black),
      );
      setState(() {});
      controller.addListener(_onTick);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _onTick() {
    final c = _videoController;
    if (c == null) return;
    final v = c.value;
    if (!v.isInitialized) return;
    if (v.position >= v.duration && v.duration > Duration.zero) {
      _exitPlayer();
    }
  }

  void _exitPlayer() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onTick);
    _chewieController?.dispose();
    _videoController?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _exitPlayer();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: _failed
              ? _ErrorView(message: _errorMessage, onClose: _exitPlayer)
              : _chewieController == null
                  ? const CircularProgressIndicator(color: AppColors.accent)
                  : Chewie(controller: _chewieController!),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onClose});
  final String? message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: AppColors.accent, size: 48),
        const SizedBox(height: 12),
        Text(
          message ?? 'Could not play this stream',
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
          onPressed: onClose,
          child: const Text('Close'),
        ),
      ],
    );
  }
}
