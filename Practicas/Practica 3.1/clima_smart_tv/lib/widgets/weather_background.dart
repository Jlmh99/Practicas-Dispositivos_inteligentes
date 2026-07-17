import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class WeatherBackground extends StatefulWidget {
  final String condition;

  const WeatherBackground({
    super.key,
    required this.condition,
  });

  @override
  State<WeatherBackground> createState() => _WeatherBackgroundState();
}

class _WeatherBackgroundState extends State<WeatherBackground> {

  VideoPlayerController? _controller;

  static const Map<String, String> _videos = {
    'Clear': 'assets/videos/clear.mp4',
    'Clouds': 'assets/videos/cloudy.mp4',
    'Rain': 'assets/videos/rain.mp4',
    'Drizzle': 'assets/videos/rain.mp4',
    'Thunderstorm': 'assets/videos/thunder.mp4',
    'Snow': 'assets/videos/cloudy.mp4',
  };

  String get _videoPath =>
      _videos[widget.condition] ??
      'assets/videos/cloudy.mp4';

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void didUpdateWidget(covariant WeatherBackground oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.condition != widget.condition) {
      _loadVideo();
    }
  }

  Future<void> _loadVideo() async {

    await _controller?.dispose();

    final controller = VideoPlayerController.asset(_videoPath);

    await controller.initialize();

    controller
      ..setLooping(true)
      ..setVolume(0)
      ..play();

    if (mounted) {
      setState(() {
        _controller = controller;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (_controller == null ||
        !_controller!.value.isInitialized) {

      return Container(
        color: Colors.black,
      );
    }

    return Positioned.fill(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}